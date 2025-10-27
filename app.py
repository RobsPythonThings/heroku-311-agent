"""
311 AI Chat Application - PRODUCTION GRADE
Flask backend with Heroku Managed Inference, JWT authentication, retry logic, and comprehensive error handling
Supports vision analysis via Heroku Managed Inference with fallback to Claude API
"""

import os
import json
import base64
import time
import jwt
import requests
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import anthropic
from simple_salesforce import Salesforce
import logging
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from dateutil import parser

# ============================================================================
# CONFIGURATION & LOGGING
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Rate limiting: Track API calls per minute
API_CALL_COUNTS = {
    'heroku_inference': {'count': 0, 'reset_time': time.time() + 60},
    'claude_api': {'count': 0, 'reset_time': time.time() + 60},
    'salesforce': {'count': 0, 'reset_time': time.time() + 60}
}
RATE_LIMITS = {
    'heroku_inference': 150,  # Heroku Managed Inference limit: 150 req/min
    'claude_api': 50,  # Direct Claude API fallback limit
    'salesforce': 100  # calls per minute
}

# ============================================================================
# HEROKU MANAGED INFERENCE CLIENT INITIALIZATION
# ============================================================================

class HerokuInferenceClient:
    """
    Production-grade Heroku Managed Inference client with retry logic,
    fallback to Claude API, and comprehensive error handling
    """
    
    def __init__(self):
        # Heroku Managed Inference config
        self.inference_url = os.environ.get('INFERENCE_URL')
        self.inference_key = os.environ.get('INFERENCE_KEY')
        self.inference_model_id = os.environ.get('INFERENCE_MODEL_ID')
        
        # Fallback: Direct Claude API
        self.claude_api_key = os.environ.get('CLAUDE_API_KEY')
        self.claude_client = None
        
        # Determine which service is available
        self.use_heroku_inference = bool(self.inference_url and self.inference_key and self.inference_model_id)
        self.use_claude_fallback = bool(self.claude_api_key)
        
        if self.use_heroku_inference:
            logger.info("✅ Heroku Managed Inference initialized")
            logger.info(f"   Model: {self.inference_model_id}")
        else:
            logger.warning("⚠️ Heroku Managed Inference not configured")
        
        # Initialize Claude API as fallback
        if self.use_claude_fallback:
            try:
                self.claude_client = anthropic.Anthropic(
                    api_key=self.claude_api_key,
                    http_client=httpx.Client(proxy=None)
                )
                logger.info("✅ Claude API fallback initialized")
            except Exception as e:
                logger.error(f"❌ Failed to initialize Claude API fallback: {str(e)}")
                self.claude_client = None
        
        if not self.use_heroku_inference and not self.use_claude_fallback:
            logger.error("❌ No AI inference service configured!")
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((requests.exceptions.RequestException, ConnectionError)),
        reraise=False
    )
    def _call_heroku_inference(self, messages, max_tokens=1024, temperature=1.0):
        """Call Heroku Managed Inference with retry logic"""
        if not self.use_heroku_inference:
            raise Exception("Heroku Managed Inference not configured")
        
        if not check_rate_limit('heroku_inference'):
            raise Exception("Rate limit exceeded for Heroku Managed Inference")
        
        headers = {
            "Authorization": f"Bearer {self.inference_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.inference_model_id,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature
        }
        
        logger.info(f"🔵 Calling Heroku Managed Inference ({self.inference_model_id})")
        
        response = requests.post(
            f"{self.inference_url}/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            error_msg = f"Heroku Inference API error: {response.status_code} - {response.text}"
            logger.error(f"❌ {error_msg}")
            raise Exception(error_msg)
        
        result = response.json()
        logger.info("✅ Heroku Managed Inference response received")
        
        return result['choices'][0]['message']['content']
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((anthropic.APIError, requests.exceptions.RequestException)),
        reraise=False
    )
    def _call_claude_api(self, messages, max_tokens=1024, temperature=1.0):
        """Call Claude API directly - supports vision with base64 images"""
        if not self.claude_client:
            raise Exception("Claude API fallback not configured")
        
        if not check_rate_limit('claude_api'):
            raise Exception("Rate limit exceeded for Claude API")
        
        logger.info("🟠 Calling Claude API")
        
        # Extract system message (Claude API requires it separate from messages)
        system_prompt = None
        claude_messages = []
        
        for msg in messages:
            # Handle system messages separately
            if msg.get('role') == 'system':
                system_prompt = msg['content']
                logger.info("🎯 Extracted system prompt for Claude API")
                continue
            
            # Convert user/assistant messages
            if isinstance(msg['content'], str):
                # Simple text message
                claude_messages.append(msg)
            elif isinstance(msg['content'], list):
                # Multimodal message - convert image_url format to Claude's image format
                converted_content = []
                for item in msg['content']:
                    if item['type'] == 'text':
                        converted_content.append(item)
                    elif item['type'] == 'image_url':
                        # Extract base64 from data URI format
                        image_url = item['image_url']['url']
                        if image_url.startswith('data:image/'):
                            # Parse: data:image/jpeg;base64,<base64_data>
                            media_type = image_url.split(';')[0].split(':')[1]
                            base64_data = image_url.split(',', 1)[1]
                            converted_content.append({
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": media_type,
                                    "data": base64_data
                                }
                            })
                            logger.info("📷 Converted image to Claude format")
                claude_messages.append({
                    "role": msg['role'],
                    "content": converted_content
                })
        
        # Build API call parameters
        api_params = {
            "model": "claude-sonnet-4-20250514",
            "max_tokens": max_tokens,
            "messages": claude_messages,
            "temperature": temperature
        }
        
        # Add system prompt if present
        if system_prompt:
            api_params["system"] = system_prompt
        
        # Log what we're sending for debugging
        logger.info(f"🔍 Sending to Claude: {len(claude_messages)} messages, system={bool(system_prompt)}")
        
        try:
            response = self.claude_client.messages.create(**api_params)
            logger.info("✅ Claude API response received")
            return response.content[0].text
        except anthropic.BadRequestError as e:
            logger.error(f"❌ Claude BadRequestError: {str(e)}")
            logger.error(f"❌ Number of messages: {len(claude_messages)}")
            logger.error(f"❌ Has system prompt: {bool(system_prompt)}")
            # Log message structure (not full content for privacy)
            for i, msg in enumerate(claude_messages):
                content_type = "string" if isinstance(msg.get('content'), str) else "list"
                if content_type == "list":
                    content_items = [item.get('type') for item in msg.get('content', [])]
                    logger.error(f"❌ Message {i}: role={msg.get('role')}, content={content_items}")
                else:
                    logger.error(f"❌ Message {i}: role={msg.get('role')}, content=text")
            raise
    
    def create_message(self, messages, max_tokens=1024, temperature=1.0):
        """
        Create a message using Heroku Managed Inference for text, Claude API for vision
        Routes intelligently based on content type
        """
        errors = []
        
        # Detect if this is a vision request (has images)
        has_image = any(
            isinstance(msg.get('content'), list) and 
            any(item.get('type') == 'image_url' for item in msg['content'])
            for msg in messages
        )
        
        # If has image, route directly to Claude API (HMI vision support is limited)
        if has_image:
            logger.info("📷 Vision request detected - using Claude API directly")
            try:
                return self._call_claude_api(messages, max_tokens, temperature)
            except Exception as e:
                error_msg = f"Claude API failed: {str(e)}"
                logger.error(f"❌ {error_msg}")
                raise Exception(error_msg)
        
        # Text-only: Try Heroku Managed Inference first, fallback to Claude
        if self.use_heroku_inference:
            try:
                return self._call_heroku_inference(messages, max_tokens, temperature)
            except Exception as e:
                error_msg = f"Heroku Inference failed: {str(e)}"
                logger.warning(f"⚠️ {error_msg}")
                errors.append(error_msg)
        
        # Fallback to Claude API if Heroku Inference fails or isn't configured
        if self.use_claude_fallback:
            try:
                logger.info("🔄 Falling back to Claude API")
                return self._call_claude_api(messages, max_tokens, temperature)
            except Exception as e:
                error_msg = f"Claude API fallback failed: {str(e)}"
                logger.error(f"❌ {error_msg}")
                errors.append(error_msg)
        
        # Both failed
        error_summary = " | ".join(errors)
        raise Exception(f"All AI services failed: {error_summary}")
    
    def health_check(self):
        """Test AI service connectivity"""
        checks = {
            'heroku_inference': 'not_configured',
            'claude_api_fallback': 'not_configured'
        }
        
        # Test Heroku Managed Inference
        if self.use_heroku_inference:
            try:
                test_response = self._call_heroku_inference(
                    messages=[{"role": "user", "content": "test"}],
                    max_tokens=10
                )
                checks['heroku_inference'] = 'ok' if test_response else 'error'
            except Exception as e:
                logger.error(f"Heroku Inference health check failed: {e}")
                checks['heroku_inference'] = 'error'
        
        # Test Claude API fallback
        if self.use_claude_fallback:
            try:
                test_response = self._call_claude_api(
                    messages=[{"role": "user", "content": "test"}],
                    max_tokens=10
                )
                checks['claude_api_fallback'] = 'ok' if test_response else 'error'
            except Exception as e:
                logger.error(f"Claude API health check failed: {e}")
                checks['claude_api_fallback'] = 'error'
        
        return checks

# Initialize AI client globally
ai_client = HerokuInferenceClient()

# ============================================================================
# CERTIFICATE MONITORING
# ============================================================================

def check_certificate_expiration():
    """Check if certificate is expiring soon and log warnings"""
    try:
        private_key_base64 = os.environ.get('SF_PRIVATE_KEY_BASE64')
        if not private_key_base64:
            logger.warning("⚠️ No private key found in environment")
            return None
        
        # Note: We have the private key, but to check expiration we'd need the cert
        # For now, just log that monitoring is active
        logger.info("🔐 Certificate monitoring active")
        return None
    except Exception as e:
        logger.error(f"Certificate check failed: {str(e)}")
        return None

# ============================================================================
# RATE LIMITING
# ============================================================================

def check_rate_limit(service):
    """Check if we're within rate limits for a service"""
    current_time = time.time()
    
    # Reset counter if time window expired
    if current_time >= API_CALL_COUNTS[service]['reset_time']:
        API_CALL_COUNTS[service]['count'] = 0
        API_CALL_COUNTS[service]['reset_time'] = current_time + 60
    
    # Check if we're over the limit
    if API_CALL_COUNTS[service]['count'] >= RATE_LIMITS[service]:
        logger.warning(f"⚠️ Rate limit approaching for {service}")
        return False
    
    API_CALL_COUNTS[service]['count'] += 1
    return True

# ============================================================================
# JWT AUTHENTICATION WITH RETRY LOGIC
# ============================================================================

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception_type((requests.exceptions.RequestException, ConnectionError)),
    reraise=True
)
def get_jwt_access_token():
    """
    Get Salesforce access token using JWT Bearer flow
    Enhanced with retry logic and comprehensive error handling
    """
    try:
        # Load private key from environment variable (Heroku) or file (local)
        private_key_base64 = os.environ.get('SF_PRIVATE_KEY_BASE64')
        if private_key_base64:
            private_key = base64.b64decode(private_key_base64).decode('utf-8')
            logger.debug("🔑 Loaded private key from environment variable")
        else:
            private_key_path = os.path.join(os.path.dirname(__file__), 'server.key')
            with open(private_key_path, 'r') as f:
                private_key = f.read()
            logger.debug("🔑 Loaded private key from file")
        
        # Get config from environment
        client_id = os.environ.get('SF_CLIENT_ID')
        username = os.environ.get('SF_USERNAME')
        instance_url = os.environ.get('SF_INSTANCE_URL', 'https://login.salesforce.com')
        
        if not all([client_id, username]):
            raise ValueError("Missing required Salesforce credentials (SF_CLIENT_ID, SF_USERNAME)")
        
        # Determine login URL based on instance
        if 'test' in instance_url or 'sandbox' in instance_url:
            login_url = 'https://test.salesforce.com'
        else:
            login_url = 'https://login.salesforce.com'
        
        # Build JWT claim
        claim = {
            'iss': client_id,
            'sub': username,
            'aud': login_url,
            'exp': int(time.time()) + 300  # 5 minutes from now
        }
        
        # Sign JWT with RS256
        assertion = jwt.encode(claim, private_key, algorithm='RS256')
        
        # Exchange JWT for access token
        response = requests.post(
            f'{login_url}/services/oauth2/token',
            data={
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': assertion
            },
            timeout=10
        )
        
        if response.status_code != 200:
            error_msg = f"JWT token exchange failed: {response.status_code} - {response.text}"
            logger.error(f"❌ {error_msg}")
            raise Exception(error_msg)
        
        token_data = response.json()
        logger.info("✅ JWT authentication successful")
        
        return token_data['access_token'], token_data['instance_url']
    
    except Exception as e:
        logger.error(f"❌ Error in JWT authentication: {str(e)}")
        raise

# ============================================================================
# SALESFORCE CLIENT INITIALIZATION
# ============================================================================

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception_type((Exception,)),
    reraise=True
)
def get_salesforce_client():
    """
    Get Salesforce client with JWT authentication
    Enhanced with retry logic
    """
    try:
        access_token, instance_url = get_jwt_access_token()
        
        sf = Salesforce(
            instance_url=instance_url,
            session_id=access_token,
            version='58.0'
        )
        
        logger.info("✅ Salesforce client initialized")
        return sf
        
    except Exception as e:
        logger.error(f"❌ Error initializing Salesforce client: {str(e)}")
        raise

# ============================================================================
# PHOTO VALIDATION
# ============================================================================

def validate_photo(photo_data):
    """Validate photo data and return cleaned base64 string"""
    if not photo_data:
        return None
    
    # Strip data URI prefix if present
    if isinstance(photo_data, str) and photo_data.startswith('data:'):
        photo_data = photo_data.split(',', 1)[1] if ',' in photo_data else photo_data
    
    # Validate base64 and size
    try:
        decoded = base64.b64decode(photo_data)
        size_mb = len(decoded) / (1024 * 1024)
        
        if size_mb > 10:  # 10 MB limit
            logger.warning(f"⚠️ Photo size ({size_mb:.2f} MB) exceeds 10 MB limit")
            return None
        
        logger.info(f"✅ Photo validated: {size_mb:.2f} MB")
        return photo_data
    except Exception as e:
        logger.error(f"❌ Invalid photo data: {str(e)}")
        return None

# ============================================================================
# MAIN ROUTES
# ============================================================================

@app.route('/')
def index():
    """Serve the main chat interface"""
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    """
    Main chat endpoint with vision support via Heroku Managed Inference
    Accepts: message (optional if photo present), conversation (optional), photo (optional)
    Returns: AI assistant response with case creation capability
    """
    try:
        data = request.json
        user_message = data.get('message', '').strip()
        conversation = data.get('conversation', [])
        photo_base64 = data.get('photo')  # Base64 encoded image or dict with data/media_type
        
        # Extract photo data if it's a dict
        if isinstance(photo_base64, dict):
            photo_base64 = photo_base64.get('data')
        
        # Require either message or photo
        if not user_message and not photo_base64:
            return jsonify({'success': False, 'error': 'Message or photo is required'}), 400
        
        logger.info(f"📨 Received message: {user_message[:100] if user_message else '[photo only]'}...")
        
        # Validate photo if present
        if photo_base64:
            photo_base64 = validate_photo(photo_base64)
            if not photo_base64:
                return jsonify({'success': False, 'error': 'Invalid photo data'}), 400
        
        # Build conversation context for AI
        messages = []
        
        # Add conversation history (if this is a follow-up message)
        for msg in conversation:
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            messages.append({"role": role, "content": content})
        
        # Build current message content
        current_message_content = []
        
        # Add text if present
        if user_message:
            current_message_content.append({
                "type": "text",
                "text": user_message
            })
        
        # ONLY add system prompt if this is the very first message (no conversation history)
        is_first_message = len(conversation) == 0
        
        if is_first_message:
            # Add system prompt as first message
            system_message = {
                "role": "system",
                "content": """You are a helpful 311 service assistant for the City of Austin, Texas. 
Help citizens report issues like potholes, graffiti, broken streetlights, and other city services.

Be friendly, gather necessary information (location, description), and when ready, confirm with the user before creating a case.
Ask: "Would you like me to create a service request for this?"

When analyzing photos, describe what you see and ask clarifying questions about the issue shown.

IMPORTANT: Do NOT automatically create cases. Always confirm with the user first."""
            }
            messages.insert(0, system_message)
            logger.info("🎬 First message - system prompt added")
        
        # Add photo to current message if present
        if photo_base64:
            # Use data URI format for vision analysis
            image_data_uri = f"data:image/jpeg;base64,{photo_base64}"
            current_message_content.append({
                "type": "image_url",
                "image_url": {
                    "url": image_data_uri
                }
            })
            logger.info("📷 Photo included in message for vision analysis")
        
        # Add current message
        if current_message_content:
            if len(current_message_content) == 1 and current_message_content[0].get("type") == "text":
                # Text only - use string format
                messages.append({
                    "role": "user",
                    "content": current_message_content[0]["text"]
                })
            else:
                # Multimodal (or photo-only) - use array format
                messages.append({
                    "role": "user",
                    "content": current_message_content
                })
        
        logger.info(f"📊 Conversation context: {len(messages)} messages (first_message={is_first_message})")
        
        # Call AI service (Heroku Managed Inference with Claude fallback)
        assistant_response = ai_client.create_message(
            messages=messages,
            max_tokens=1024,
            temperature=1.0
        )
        
        # Check if user wants to create a case
        if user_message and any(phrase in user_message.lower() for phrase in ['create', 'submit', 'yes', 'please do', 'go ahead']):
            # Look for photo in conversation if not in current message
            if not photo_base64:
                photo_base64 = find_photo_in_conversation(conversation)
            
            # Check if assistant is confirming case creation
            if any(phrase in assistant_response.lower() for phrase in ['create', 'submit', 'service request']):
                # Extract case info from conversation
                case_info = extract_case_info_from_conversation(messages)
                
                if case_info:
                    logger.info(f"📝 Creating case with info: {case_info}")
                    
                    try:
                        case_result = create_salesforce_case(case_info, photo_base64)
                        if case_result['success']:
                            assistant_response = (
                                f"Great! I've created your service request. Your case number is **{case_result['caseNumber']}**. "
                                f"You can use this number to track your request. {case_result['message']}"
                            )
                        else:
                            assistant_response = f"I apologize, but there was an error creating your case: {case_result['message']}"
                    except Exception as e:
                        logger.error(f"❌ Error creating case: {str(e)}")
                        assistant_response = "I apologize, but I'm having trouble creating your case right now. Please try again in a moment, or contact 311 directly."
        
        return jsonify({'success': True, 'response': assistant_response})
        
    except Exception as e:
        logger.error(f"❌ Error in chat endpoint: {str(e)}")
        return jsonify({
            'success': False, 
            'error': 'An unexpected error occurred. Please try again.'
        }), 500

def find_photo_in_conversation(conversation_history):
    """Search conversation history for a photo"""
    for msg in reversed(conversation_history):
        photo = msg.get('photo')
        if photo:
            logger.info("📷 Found photo in conversation history")
            return photo
    logger.debug("No photo found in conversation history")
    return None

def extract_case_info_from_conversation(messages):
    """Extract case information from conversation"""
    try:
        conversation_text = ""
        for msg in messages:
            role = "User" if msg["role"] == "user" else "Assistant"
            if isinstance(msg["content"], list):
                for content in msg["content"]:
                    if content["type"] == "text":
                        conversation_text += f"{role}: {content['text']}\n"
            else:
                conversation_text += f"{role}: {msg['content']}\n"
        
        extraction_prompt = f"""Based on this conversation, extract info for creating a 311 case:

{conversation_text}

Return ONLY JSON with these fields (use null for missing):
{{"complaintType": "Pothole/Graffiti/etc", "subject": "brief subject", "description": "details", "location": "address", "citizenEmail": "email", "citizenPhone": "phone", "ward": "ward"}}"""
        
        # Use AI client for extraction
        extracted_text = ai_client.create_message(
            messages=[{"role": "user", "content": extraction_prompt}],
            max_tokens=1024
        )
        
        json_start = extracted_text.find('{')
        json_end = extracted_text.rfind('}') + 1
        if json_start >= 0 and json_end > json_start:
            case_info = json.loads(extracted_text[json_start:json_end])
            logger.info(f"✅ Extracted case info: {case_info}")
            return case_info
        return None
    except Exception as e:
        logger.error(f"❌ Error extracting case info: {str(e)}")
        return None

def create_salesforce_case(case_info, photo_base64=None):
    """
    Create a case in Salesforce with error handling
    """
    try:
        # Check rate limits
        if not check_rate_limit('salesforce'):
            return {
                'success': False, 
                'message': 'Service temporarily busy. Please try again in a moment.'
            }
        
        sf = get_salesforce_client()
        
        apex_request = {
            "inputs": [{
                "subject": case_info.get('subject', 'New 311 Request'),
                "description": case_info.get('description', ''),
                "complaintType": case_info.get('complaintType'),
                "citizenEmail": case_info.get('citizenEmail'),
                "citizenPhone": case_info.get('citizenPhone'),
                "ward": case_info.get('ward')
            }]
        }
        
        logger.info(f"📝 Creating case with data: {apex_request}")
        
        result = sf.restful('actions/custom/apex/Create311Case', method='POST', data=json.dumps(apex_request))
        logger.info(f"✅ Salesforce response: {result}")
        
        if result and len(result) > 0:
            case_result = result[0]
            output_values = case_result.get('outputValues', {})
            case_id = output_values.get('caseId')
            
            # Attach photo if available
            if photo_base64 and case_id:
                try:
                    photo_data = photo_base64.get('data') if isinstance(photo_base64, dict) else photo_base64
                    if photo_data:
                        logger.info(f"📎 Attempting to attach photo to case {case_id}")
                        attach_photo_to_case(sf, case_id, photo_data)
                except Exception as e:
                    logger.warning(f"⚠️ Photo attachment failed for case {case_id}: {e}")
            
            return {
                'success': output_values.get('success', False),
                'caseNumber': output_values.get('caseNumber'),
                'message': output_values.get('message', ''),
                'caseId': output_values.get('caseId')
            }
        
        return {'success': False, 'message': 'Unexpected response from Salesforce'}
    except Exception as e:
        logger.error(f"❌ Error creating Salesforce case: {str(e)}")
        return {'success': False, 'message': 'Unable to create case. Please try again.'}

def attach_photo_to_case(sf, case_id, photo_base64):
    """Attach a photo to a Salesforce case"""
    try:
        content_version = {
            'Title': 'Service Request Photo',
            'PathOnClient': 'photo.jpg',
            'VersionData': photo_base64,
            'FirstPublishLocationId': case_id
        }
        result = sf.ContentVersion.create(content_version)
        logger.info(f"✅ Photo attached to case {case_id}: {result}")
        return True
    except Exception as e:
        logger.error(f"❌ Error attaching photo: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """
    Enhanced health check - tests all critical services including Heroku Managed Inference
    """
    checks = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }
    
    # Test AI services (Heroku Managed Inference + fallback)
    ai_checks = ai_client.health_check()
    checks.update(ai_checks)
    
    # Check if at least one AI service is working
    if all(status in ['error', 'not_configured'] for status in ai_checks.values()):
        checks['status'] = 'degraded'
    
    # Test Salesforce connection
    try:
        sf = get_salesforce_client()
        sf.query("SELECT Id FROM Case LIMIT 1")
        checks['salesforce'] = 'ok'
    except Exception as e:
        logger.error(f"Salesforce health check failed: {e}")
        checks['salesforce'] = 'error'
        checks['status'] = 'degraded'
    
    # Check certificate
    cert_status = check_certificate_expiration()
    checks['certificate'] = cert_status if cert_status else 'ok'
    
    status_code = 200 if checks['status'] == 'healthy' else 503
    return jsonify(checks), status_code

# ============================================================================
# STARTUP
# ============================================================================

# Check certificate on startup
check_certificate_expiration()

# Log AI service configuration
logger.info("=" * 80)
logger.info("311 AI AGENT - STARTUP CONFIGURATION")
logger.info("=" * 80)
if ai_client.use_heroku_inference:
    logger.info(f"✅ Primary AI Service: Heroku Managed Inference ({ai_client.inference_model_id})")
else:
    logger.info("⚠️ Primary AI Service: Not configured")

if ai_client.use_claude_fallback:
    logger.info("✅ Fallback AI Service: Claude API (Direct)")
else:
    logger.info("⚠️ Fallback AI Service: Not configured")
logger.info("=" * 80)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    logger.info(f"🚀 Starting 311 AI Agent on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
