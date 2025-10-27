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

# Supported image formats for vision API
ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}

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
        
        # Convert messages to Claude format (no need to extract system messages anymore)
        claude_messages = []
        
        for msg in messages:
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
                            logger.info(f"📷 Converted image to Claude format ({media_type})")
                claude_messages.append({
                    "role": msg['role'],
                    "content": converted_content
                })
        
        # Build API call parameters
        api_params = {
            "model": "claude-sonnet-4-20250514",
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": claude_messages
        }
        
        response = self.claude_client.messages.create(**api_params)
        logger.info("✅ Claude API response received")
        
        return response.content[0].text
    
    def create_message(self, messages, max_tokens=1024, temperature=1.0):
        """
        Smart routing: Try Heroku Managed Inference first, fallback to Claude API on failure
        """
        errors = []
        
        # Try Heroku Managed Inference first (if configured)
        if self.use_heroku_inference:
            try:
                return self._call_heroku_inference(messages, max_tokens, temperature)
            except Exception as e:
                error_msg = f"Heroku Inference failed: {str(e)}"
                logger.warning(f"⚠️ {error_msg}")
                errors.append(error_msg)
        
        # Fallback to Claude API
        if self.use_claude_fallback:
            try:
                return self._call_claude_api(messages, max_tokens, temperature)
            except Exception as e:
                error_msg = f"Claude API failed: {str(e)}"
                logger.error(f"❌ {error_msg}")
                errors.append(error_msg)
        
        # If both failed, raise exception
        raise Exception(f"All AI services failed: {'; '.join(errors)}")
    
    def health_check(self):
        """Test both AI services and return status"""
        status = {}
        
        # Test Heroku Managed Inference
        if self.use_heroku_inference:
            try:
                test_msg = [{"role": "user", "content": "Say 'ok'"}]
                response = self._call_heroku_inference(test_msg, max_tokens=10)
                status['heroku_inference'] = 'ok' if response else 'error'
            except Exception as e:
                logger.error(f"Heroku Inference health check failed: {e}")
                status['heroku_inference'] = 'error'
        else:
            status['heroku_inference'] = 'not_configured'
        
        # Test Claude API
        if self.use_claude_fallback:
            try:
                test_msg = [{"role": "user", "content": "Say 'ok'"}]
                response = self._call_claude_api(test_msg, max_tokens=10)
                status['claude_api'] = 'ok' if response else 'error'
            except Exception as e:
                logger.error(f"Claude API health check failed: {e}")
                status['claude_api'] = 'error'
        else:
            status['claude_api'] = 'not_configured'
        
        return status

# Initialize AI client
ai_client = HerokuInferenceClient()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def check_rate_limit(service_name):
    """Check if API rate limit is exceeded"""
    current_time = time.time()
    service = API_CALL_COUNTS[service_name]
    
    # Reset counter if minute has passed
    if current_time > service['reset_time']:
        service['count'] = 0
        service['reset_time'] = current_time + 60
    
    # Check limit
    if service['count'] >= RATE_LIMITS[service_name]:
        logger.warning(f"⚠️ Rate limit exceeded for {service_name}")
        return False
    
    # Increment and allow
    service['count'] += 1
    return True

def get_salesforce_client():
    """Create Salesforce client with JWT authentication"""
    try:
        # JWT authentication for Salesforce
        private_key = os.environ.get('SF_PRIVATE_KEY', '').replace('\\n', '\n')
        consumer_key = os.environ.get('SF_CONSUMER_KEY')
        username = os.environ.get('SF_USERNAME')
        
        if not all([private_key, consumer_key, username]):
            raise ValueError("Missing Salesforce credentials")
        
        # Create JWT
        claim = {
            'iss': consumer_key,
            'sub': username,
            'aud': 'https://login.salesforce.com',
            'exp': datetime.utcnow() + timedelta(minutes=3)
        }
        
        assertion = jwt.encode(claim, private_key, algorithm='RS256')
        
        # Request access token
        r = requests.post(
            'https://login.salesforce.com/services/oauth2/token',
            data={
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': assertion
            }
        )
        
        if r.status_code != 200:
            raise Exception(f"Salesforce auth failed: {r.text}")
        
        access_token = r.json()['access_token']
        instance_url = r.json()['instance_url']
        
        return Salesforce(instance_url=instance_url, session_id=access_token)
    except Exception as e:
        logger.error(f"❌ Salesforce authentication failed: {str(e)}")
        raise

def check_certificate_expiration():
    """Check if SSL certificate is expiring soon"""
    cert_path = os.environ.get('SSL_CERT_PATH')
    if not cert_path or not os.path.exists(cert_path):
        return None
    
    try:
        with open(cert_path, 'rb') as f:
            cert_data = f.read()
            cert = x509.load_pem_x509_certificate(cert_data, default_backend())
            
        expiry = cert.not_valid_after_utc
        days_until_expiry = (expiry - datetime.now(expiry.tzinfo)).days
        
        if days_until_expiry < 30:
            logger.warning(f"⚠️ SSL certificate expires in {days_until_expiry} days!")
            return f"expires_in_{days_until_expiry}_days"
        
        return None
    except Exception as e:
        logger.error(f"Certificate check failed: {e}")
        return None

def validate_photo(photo_data):
    """Validate base64 photo data"""
    try:
        if isinstance(photo_data, dict):
            photo_data = photo_data.get('compressed_data') or photo_data.get('data')
        
        if not photo_data:
            return None
        
        # Remove data URI prefix if present
        if isinstance(photo_data, str) and photo_data.startswith('data:'):
            photo_data = photo_data.split(',', 1)[1]
        
        # Validate base64
        base64.b64decode(photo_data)
        return photo_data
    except Exception as e:
        logger.error(f"❌ Photo validation failed: {str(e)}")
        return None

# ============================================================================
# FLASK ROUTES
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
        photo_payload = data.get('photo')  # Base64 encoded image or dict with data/media_type
        
        # DEBUG: Log what we received
        logger.info(f"🔍 DEBUG - Received data keys: {list(data.keys())}")
        logger.info(f"🔍 DEBUG - Photo payload type: {type(photo_payload)}")
        if isinstance(photo_payload, dict):
            logger.info(f"🔍 DEBUG - Photo payload keys: {list(photo_payload.keys())}")
        
        # Extract photo data and media type
        photo_base64 = None
        photo_media_type = 'image/jpeg'  # Default fallback
        
        if isinstance(photo_payload, dict):
            # Extract base64 data
            photo_base64 = photo_payload.get('compressed_data') or photo_payload.get('data')
            
            if not photo_base64:
                logger.error(f"❌ Photo object received but no 'data' or 'compressed_data' key found. Keys: {list(photo_payload.keys())}")
            
            # Extract and validate media type
            media_type = photo_payload.get('media_type', 'image/jpeg')
            if media_type in ALLOWED_IMAGE_TYPES:
                photo_media_type = media_type
                logger.info(f"📷 Photo media type: {photo_media_type}")
            else:
                logger.warning(f"⚠️ Unsupported media type '{media_type}', defaulting to image/jpeg")
        else:
            # Direct base64 string
            photo_base64 = photo_payload
        
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
        logger.info(f"🔍 DEBUG - Processing {len(conversation)} messages from conversation history")
        for i, msg in enumerate(conversation):
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            
            # Debug log each message
            content_preview = str(content)[:100] if content else "[EMPTY]"
            logger.info(f"🔍 DEBUG - History msg {i}: role={role}, content_type={type(content)}, preview={content_preview}")
            
            # Skip messages with empty content (they'll cause API errors)
            if not content or (isinstance(content, str) and not content.strip()):
                logger.warning(f"⚠️ Skipping message {i} with empty content from conversation history")
                continue
                
            messages.append({"role": role, "content": content})
        
        # Build current message content
        current_message_content = []
        
        # Check if this is the first message OR if there's a photo
        is_first_message = len(conversation) == 0
        has_photo = bool(photo_base64)
        
        # Include 311 instructions if: (1) first message OR (2) photo upload
        if is_first_message or has_photo:
            # Add comprehensive 311 context as part of the user message
            if has_photo:
                system_instructions = """You are a 311 service assistant for the City of Toronto, Canada. Your role is to help citizens report city infrastructure issues and create service requests.

🎯 YOUR CORE MISSION:
Analyze the uploaded photo, identify the exact issue type, gather required information, and guide the citizen through creating a service request.

📋 SUPPORTED ISSUE TYPES - Use these EXACT strings when identifying issues:
1. **Pothole** - Damaged road surface, holes, cracks, asphalt damage
2. **Graffiti** - Vandalism, spray paint, tags on public/private property  
3. **Streetlight Out** - Non-functioning street lights, dark poles, broken fixtures
4. **Sidewalk Repair** - Damaged sidewalk, cracks, uneven concrete, tripping hazards
5. **Missed Garbage Collection** - Overflowing bins, uncollected trash/recycling
6. **Noise Complaint** - Excessive noise issues (usually reported without photo)

🔍 PHOTO ANALYSIS WORKFLOW:
1. **Identify the issue type**: Examine the photo carefully and determine which of the 6 types it shows. Use the EXACT complaint type name from the list above.
2. **Describe what you see**: Be specific and detailed about the infrastructure problem (e.g., "I can see a large pothole in the road surface, approximately 2-3 feet wide with cracked edges and exposed gravel")
3. **Gather location**: Ask for the specific address or intersection where this issue is located
4. **Ask clarifying questions**: Get details about severity, size, safety concerns, how long it's been an issue
5. **Collect contact info**: Ask for their email address and optionally phone number for updates
6. **Confirm before creating**: Once you have: issue type, location, description, and email, ask: "Would you like me to create a service request for this [issue type]? You'll receive a case number to track the status."

⚠️ CRITICAL INSTRUCTIONS:
- ALWAYS identify the specific complaint type from the 6 options above
- Be descriptive and specific about what you see in the photo
- ALWAYS ask for location/address - field crews need to know where to go
- ALWAYS collect citizen email for case tracking and updates
- NEVER create a case without explicit confirmation from the citizen
- Keep responses professional, concise, and action-oriented
- If the photo doesn't clearly show one of the 6 issue types, ask clarifying questions

---

CITIZEN'S MESSAGE WITH PHOTO:
"""
            else:
                system_instructions = """You are a 311 service assistant for the City of Toronto, Canada. Help citizens report city infrastructure issues.

📋 SUPPORTED ISSUE TYPES - Use these EXACT strings:
• **Pothole** - Road damage, holes, cracks
• **Graffiti** - Vandalism on property
• **Streetlight Out** - Non-functioning lights  
• **Sidewalk Repair** - Damaged concrete, tripping hazards
• **Missed Garbage Collection** - Uncollected trash/recycling
• **Noise Complaint** - Excessive noise issues

📝 YOUR WORKFLOW:
1. Understand what issue the citizen is reporting and identify the correct complaint type from the list above
2. Gather specific location (address or intersection)
3. Get detailed description of the issue
4. Collect citizen email address for case updates
5. Confirm before creating: "Would you like me to create a service request for this [complaint type]?"

Be friendly, efficient, and use the EXACT complaint type names when creating cases.

---

CITIZEN'S MESSAGE:
"""
            
            message_text = system_instructions + (user_message if user_message else "I've uploaded a photo showing a city issue that needs attention.")
            current_message_content.append({
                "type": "text",
                "text": message_text
            })
            logger.info(f"🎯 Added 311 context (first_message={is_first_message}, has_photo={has_photo})")
        elif user_message:
            # Follow-up text message without photo - just add user text
            current_message_content.append({
                "type": "text",
                "text": user_message
            })
        
        # Add photo to current message if present
        if photo_base64:
            # Use data URI format with correct media type for vision analysis
            image_data_uri = f"data:{photo_media_type};base64,{photo_base64}"
            current_message_content.append({
                "type": "image_url",
                "image_url": {
                    "url": image_data_uri
                }
            })
            logger.info(f"📷 Photo included in message for vision analysis ({photo_media_type})")
        
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
        
        logger.info(f"📊 Conversation context: {len(messages)} messages total, current message has {len(current_message_content)} content items")
        
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
                                f"✅ Great! I've created service request #{case_result['caseNumber']} for you. "
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

CRITICAL: Use ONLY these exact complaint types (case-sensitive):
- "Pothole"
- "Graffiti"  
- "Streetlight Out"
- "Sidewalk Repair"
- "Missed Garbage Collection"
- "Noise Complaint"

Return ONLY JSON with these fields (use null for missing):
{{"complaintType": "one of the exact types above", "subject": "brief subject", "description": "details including location", "citizenEmail": "email", "citizenPhone": "phone", "ward": "ward number if mentioned"}}"""
        
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
                    photo_data = photo_base64.get('compressed_data') or photo_base64.get('data') if isinstance(photo_base64, dict) else photo_base64
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