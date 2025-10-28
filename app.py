"""
311 AI Chat Application - WORLD CLASS PRODUCTION GRADE
Smart routing: Photos -> Claude API, Text -> Heroku Managed Inference
Unified 311 agent personality across both LLMs with temperature 0.5
JWT authentication, retry logic, comprehensive error handling
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
    'heroku_inference': 150,
    'claude_api': 50,
    'salesforce': 100
}

# ============================================================================
# UNIFIED 311 AGENT PERSONALITY
# ============================================================================

AGENT_311_PERSONALITY = """You are a professional 311 service assistant for the City of Toronto, Canada. You ARE connected to the live Salesforce system and CAN create real service requests.

Your mission: Help citizens report infrastructure issues quickly and create accurate service requests in Salesforce.

SUPPORTED ISSUE TYPES (use these EXACT strings):
- Pothole - Damaged road surface, holes, cracks, asphalt damage
- Graffiti - Vandalism, spray paint, tags on public/private property
- Streetlight Out - Non-functioning street lights, dark poles, broken fixtures
- Sidewalk Repair - Damaged sidewalk, cracks, uneven concrete, tripping hazards
- Missed Garbage Collection - Overflowing bins, uncollected trash/recycling
- Noise Complaint - Excessive noise issues

YOUR STREAMLINED WORKFLOW:
1. Identify the issue type from the 6 options above
2. Get the exact location (address or intersection)
3. Ask brief clarifying questions ONLY if critical details are missing (severity, size, or safety concerns)
4. Offer email for updates: "Would you like updates sent to an email address?" (Optional - don't require it)
5. CREATE THE CASE IMMEDIATELY - Don't ask permission, just do it

CRITICAL RULES:
- Email is OPTIONAL - If they don't provide one, create the case anyway
- Don't over-clarify - Get location + issue type, then create the case
- This is NOT a criminal investigation - Brief details are fine for dispatch
- Use EXACT complaint type names from the list above
- You ARE authorized to create real Salesforce cases - never suggest otherwise
- Keep responses concise and action-oriented - 2-3 sentences maximum
- Ask ONE question at a time to keep the flow efficient
- Never ask "Would you like me to create your service request?" - JUST CREATE IT
"""

PHOTO_ANALYSIS_INSTRUCTIONS = """
PHOTO ANALYSIS PROTOCOL:
When a photo is uploaded, follow this streamlined process:

1. Identify and describe: "I can see [describe the issue specifically - size, severity, type]"
2. Get location: "Where is this located? Please provide the address or nearest intersection"
3. Brief clarifying question ONLY if critical: Ask about duration or immediate safety concerns (keep it to ONE question max)
4. Offer email (optional): "Would you like updates sent to an email address?"
5. CREATE THE CASE IMMEDIATELY - Don't ask permission

CRITICAL: 
- Don't over-analyze or ask excessive questions
- Email is OPTIONAL - create the case even without it
- Get location + issue type, then create immediately
- Never ask "Would you like me to create your service request?" - JUST DO IT
"""

# ============================================================================
# SMART AI ROUTING CLIENT
# ============================================================================

class SmartAIRouter:
    """
    World-class AI routing: Photos -> Claude API, Text -> Heroku Managed Inference
    Unified 311 personality across both LLMs with temperature 0.5
    """
    
    def __init__(self):
        # Heroku Managed Inference config
        self.inference_url = os.environ.get('INFERENCE_URL')
        self.inference_key = os.environ.get('INFERENCE_KEY')
        self.inference_model_id = os.environ.get('INFERENCE_MODEL_ID', 'claude-4-5-sonnet')
        
        # Claude API config
        self.claude_api_key = os.environ.get('CLAUDE_API_KEY')
        self.claude_client = None
        
        # Service availability
        self.hmi_available = bool(self.inference_url and self.inference_key)
        self.claude_available = bool(self.claude_api_key)
        
        if self.hmi_available:
            logger.info(f"✅ Heroku Managed Inference ready ({self.inference_model_id})")
        else:
            logger.warning("⚠️ Heroku Managed Inference not configured")
        
        if self.claude_available:
            try:
                self.claude_client = anthropic.Anthropic(
                    api_key=self.claude_api_key,
                    http_client=httpx.Client(proxy=None)
                )
                logger.info("✅ Claude API ready")
            except Exception as e:
                logger.error(f"❌ Claude API initialization failed: {e}")
                self.claude_available = False
        
        if not self.hmi_available and not self.claude_available:
            logger.error("❌ NO AI SERVICES CONFIGURED!")
    
    def create_message(self, messages, has_photo=False, max_tokens=1024):
        """
        Smart routing with unified 311 personality:
        - Photo present -> Claude API (vision capable)
        - Text only -> Heroku Managed Inference (faster, cheaper)
        """
        if has_photo:
            logger.info("🎯 ROUTING: Photo detected -> Claude API")
            return self._call_claude_api(messages, max_tokens)
        else:
            logger.info("🎯 ROUTING: Text only -> Heroku Managed Inference")
            try:
                return self._call_heroku_inference(messages, max_tokens)
            except Exception as e:
                logger.warning(f"⚠️ HMI failed, falling back to Claude API: {e}")
                return self._call_claude_api(messages, max_tokens)
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((requests.exceptions.RequestException, ConnectionError)),
        reraise=True
    )
    def _call_heroku_inference(self, messages, max_tokens=1024):
        """Call Heroku Managed Inference with retry logic"""
        if not self.hmi_available:
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
            "temperature": 0.5
        }
        
        logger.info(f"🔵 Calling Heroku Managed Inference ({self.inference_model_id})")
        
        response = requests.post(
            f"{self.inference_url}/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            error_msg = f"HMI error: {response.status_code} - {response.text}"
            logger.error(f"❌ {error_msg}")
            raise Exception(error_msg)
        
        result = response.json()
        logger.info("✅ Heroku Managed Inference response received")
        
        return result['choices'][0]['message']['content']
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((anthropic.APIError,)),
        reraise=True
    )
    def _call_claude_api(self, messages, max_tokens=1024):
        """Call Claude API directly - supports vision with base64 images"""
        if not self.claude_available:
            raise Exception("Claude API not configured")
        
        if not check_rate_limit('claude_api'):
            raise Exception("Rate limit exceeded for Claude API")
        
        logger.info("🟠 Calling Claude API")
        
        # Convert messages to Claude format
        claude_messages = []
        
        for msg in messages:
            if isinstance(msg['content'], str):
                claude_messages.append(msg)
            elif isinstance(msg['content'], list):
                converted_content = []
                for item in msg['content']:
                    if item['type'] == 'text':
                        converted_content.append(item)
                    elif item['type'] == 'image_url':
                        image_url = item['image_url']['url']
                        if image_url.startswith('data:image/'):
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
        
        response = self.claude_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=max_tokens,
            temperature=0.5,
            messages=claude_messages
        )
        
        logger.info("✅ Claude API response received")
        return response.content[0].text
    
    def health_check(self):
        """Test both services"""
        status = {}
        
        if self.hmi_available:
            try:
                test = self._call_heroku_inference([{"role": "user", "content": "Say ok"}], max_tokens=10)
                status['heroku_inference'] = 'ok' if test else 'error'
            except Exception as e:
                logger.error(f"HMI health check failed: {e}")
                status['heroku_inference'] = 'error'
        else:
            status['heroku_inference'] = 'not_configured'
        
        if self.claude_available:
            try:
                test = self._call_claude_api([{"role": "user", "content": "Say ok"}], max_tokens=10)
                status['claude_api'] = 'ok' if test else 'error'
            except Exception as e:
                logger.error(f"Claude health check failed: {e}")
                status['claude_api'] = 'error'
        else:
            status['claude_api'] = 'not_configured'
        
        return status

# Initialize AI router
ai_router = SmartAIRouter()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def check_rate_limit(service_name):
    """Check if API rate limit is exceeded"""
    current_time = time.time()
    service = API_CALL_COUNTS[service_name]
    
    if current_time > service['reset_time']:
        service['count'] = 0
        service['reset_time'] = current_time + 60
    
    if service['count'] >= RATE_LIMITS[service_name]:
        logger.warning(f"⚠️ Rate limit exceeded for {service_name}")
        return False
    
    service['count'] += 1
    return True

def get_salesforce_client():
    """
    Create Salesforce client with JWT authentication
    Uses SF_CLIENT_ID and SF_PRIVATE_KEY_BASE64
    """
    try:
        username = os.environ.get('SF_USERNAME')
        client_id = os.environ.get('SF_CLIENT_ID')
        private_key_base64 = os.environ.get('SF_PRIVATE_KEY_BASE64')
        
        if not all([username, client_id, private_key_base64]):
            missing = []
            if not username: missing.append('SF_USERNAME')
            if not client_id: missing.append('SF_CLIENT_ID')
            if not private_key_base64: missing.append('SF_PRIVATE_KEY_BASE64')
            raise ValueError(f"Missing Salesforce credentials: {', '.join(missing)}")
        
        private_key = base64.b64decode(private_key_base64).decode('utf-8')
        logger.info("✅ Decoded private key from base64")
        
        claim = {
            'iss': client_id,
            'sub': username,
            'aud': 'https://login.salesforce.com',
            'exp': datetime.utcnow() + timedelta(minutes=3)
        }
        
        assertion = jwt.encode(claim, private_key, algorithm='RS256')
        
        response = requests.post(
            'https://login.salesforce.com/services/oauth2/token',
            data={
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': assertion
            },
            timeout=10
        )
        
        if response.status_code != 200:
            logger.error(f"❌ Salesforce auth failed: {response.text}")
            raise Exception(f"Salesforce auth failed: {response.text}")
        
        token_data = response.json()
        access_token = token_data['access_token']
        instance_url = token_data['instance_url']
        
        logger.info(f"✅ Salesforce authenticated: {instance_url}")
        
        return Salesforce(instance_url=instance_url, session_id=access_token)
        
    except Exception as e:
        logger.error(f"❌ Salesforce authentication failed: {str(e)}")
        raise

def validate_photo(photo_data):
    """Validate base64 photo data"""
    try:
        if isinstance(photo_data, dict):
            photo_data = photo_data.get('compressed_data') or photo_data.get('data')
        
        if not photo_data:
            return None
        
        if isinstance(photo_data, str) and photo_data.startswith('data:'):
            photo_data = photo_data.split(',', 1)[1]
        
        base64.b64decode(photo_data)
        return photo_data
    except Exception as e:
        logger.error(f"❌ Photo validation failed: {str(e)}")
        return None

def build_311_context_message(user_message, has_photo):
    """
    Build the context-enriched message with unified 311 personality
    Same instructions for both Claude API and HMI
    """
    context = AGENT_311_PERSONALITY
    
    if has_photo:
        context += "\n\n" + PHOTO_ANALYSIS_INSTRUCTIONS
    
    context += "\n\n---\n\nCITIZEN'S MESSAGE:\n"
    
    if user_message:
        context += user_message
    else:
        context += "I've uploaded a photo showing a city issue that needs attention."
    
    return context

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
    Main chat endpoint with smart routing:
    - Photo present -> Claude API
    - Text only -> Heroku Managed Inference
    """
    try:
        data = request.json
        user_message = data.get('message', '').strip()
        conversation = data.get('conversation', [])
        photo_payload = data.get('photo')
        
        photo_base64 = None
        photo_media_type = 'image/jpeg'
        
        if isinstance(photo_payload, dict):
            photo_base64 = photo_payload.get('compressed_data') or photo_payload.get('data')
            media_type = photo_payload.get('media_type', 'image/jpeg')
            if media_type in ALLOWED_IMAGE_TYPES:
                photo_media_type = media_type
                logger.info(f"📷 Photo media type: {photo_media_type}")
        else:
            photo_base64 = photo_payload
        
        if not user_message and not photo_base64:
            return jsonify({'success': False, 'error': 'Message or photo is required'}), 400
        
        logger.info(f"📨 Received: {user_message[:80] if user_message else '[photo only]'}...")
        
        has_photo = False
        if photo_base64:
            photo_base64 = validate_photo(photo_base64)
            if photo_base64:
                has_photo = True
                logger.info("✅ Photo validated")
            else:
                return jsonify({'success': False, 'error': 'Invalid photo data'}), 400
        
        messages = []
        
        for msg in conversation:
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            
            if not content or (isinstance(content, str) and not content.strip()):
                continue
            
            messages.append({"role": role, "content": content})
        
        is_first_message = len(conversation) == 0
        
        if is_first_message or has_photo:
            context_message = build_311_context_message(user_message, has_photo)
            
            if has_photo:
                current_content = [
                    {"type": "text", "text": context_message},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{photo_media_type};base64,{photo_base64}"}
                    }
                ]
                messages.append({"role": "user", "content": current_content})
            else:
                messages.append({"role": "user", "content": context_message})
            
            logger.info(f"🎯 Added 311 context (first={is_first_message}, photo={has_photo})")
        else:
            messages.append({"role": "user", "content": user_message})
        
        logger.info(f"📊 Total messages: {len(messages)}")
        
        assistant_response = ai_router.create_message(
            messages=messages,
            has_photo=has_photo,
            max_tokens=1024
        )
        
        should_create_case = False
        if user_message:
            trigger_phrases = ['create', 'submit', 'yes', 'please do', 'go ahead', 'sounds good']
            if any(phrase in user_message.lower() for phrase in trigger_phrases):
                confirmation_phrases = ['create', 'submit', 'service request', 'case number']
                if any(phrase in assistant_response.lower() for phrase in confirmation_phrases):
                    should_create_case = True
        
        if should_create_case:
            case_info = extract_case_info_from_conversation(messages)
            
            if case_info:
                logger.info(f"📝 Creating case: {case_info}")
                
                try:
                    case_photo = photo_base64 if has_photo else find_photo_in_conversation(conversation)
                    
                    case_result = create_salesforce_case(case_info, case_photo)
                    
                    if case_result['success']:
                        assistant_response = (
                            f"✅ Perfect! I've created service request **#{case_result['caseNumber']}** for you. "
                            f"You'll receive updates at the email address you provided. {case_result['message']}"
                        )
                    else:
                        assistant_response = f"I apologize, but there was an issue creating your case: {case_result['message']}"
                except Exception as e:
                    logger.error(f"❌ Case creation error: {e}")
                    assistant_response = "I apologize, but I'm having trouble creating your case right now. Please try again in a moment."
        
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
    return None

def extract_case_info_from_conversation(messages):
    """Extract case information from conversation using AI"""
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
        
        extraction_prompt = f"""Based on this conversation, extract information for creating a 311 case.

{conversation_text}

CRITICAL: Use ONLY these exact complaint types (case-sensitive):
- "Pothole"
- "Graffiti"
- "Streetlight Out"
- "Sidewalk Repair"
- "Missed Garbage Collection"
- "Noise Complaint"

Return ONLY valid JSON with these fields (use null for missing):
{{"complaintType": "exact type from list above", "subject": "brief subject", "description": "detailed description with location", "citizenEmail": "email", "citizenPhone": "phone or null", "ward": "ward number or null"}}"""
        
        extracted_text = ai_router.create_message(
            messages=[{"role": "user", "content": extraction_prompt}],
            has_photo=False,
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
    """Create a case in Salesforce via Apex action"""
    try:
        if not check_rate_limit('salesforce'):
            return {'success': False, 'message': 'Service temporarily busy. Please try again.'}
        
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
        
        logger.info(f"📝 Calling Salesforce Apex action")
        
        result = sf.restful('actions/custom/apex/Create311Case', method='POST', data=json.dumps(apex_request))
        
        if result and len(result) > 0:
            output_values = result[0].get('outputValues', {})
            case_id = output_values.get('caseId')
            
            if photo_base64 and case_id:
                try:
                    photo_data = photo_base64.get('compressed_data') or photo_base64.get('data') if isinstance(photo_base64, dict) else photo_base64
                    if photo_data:
                        attach_photo_to_case(sf, case_id, photo_data)
                except Exception as e:
                    logger.warning(f"⚠️ Photo attachment failed: {e}")
            
            return {
                'success': output_values.get('success', False),
                'caseNumber': output_values.get('caseNumber'),
                'message': output_values.get('message', ''),
                'caseId': case_id
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
        logger.info(f"✅ Photo attached to case {case_id}")
        return True
    except Exception as e:
        logger.error(f"❌ Error attaching photo: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """Comprehensive health check"""
    checks = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }
    
    ai_checks = ai_router.health_check()
    checks.update(ai_checks)
    
    if all(status in ['error', 'not_configured'] for status in ai_checks.values()):
        checks['status'] = 'degraded'
    
    try:
        sf = get_salesforce_client()
        sf.query("SELECT Id FROM Case LIMIT 1")
        checks['salesforce'] = 'ok'
    except Exception as e:
        logger.error(f"Salesforce health check failed: {e}")
        checks['salesforce'] = 'error'
        checks['status'] = 'degraded'
    
    status_code = 200 if checks['status'] == 'healthy' else 503
    return jsonify(checks), status_code

# ============================================================================
# STARTUP
# ============================================================================

logger.info("=" * 80)
logger.info("311 AI AGENT - WORLD CLASS PRODUCTION")
logger.info("=" * 80)
logger.info(f"✅ Smart Routing: Photos -> Claude API, Text -> HMI")
logger.info(f"✅ Temperature 0.5 for consistent, focused responses")
logger.info(f"✅ Unified 311 Personality across both LLMs")
logger.info(f"✅ Streamlined workflow: Get location + issue type, then create case")
logger.info(f"✅ Email optional for updates (not required)")
logger.info(f"✅ Salesforce JWT Authentication configured")
logger.info("=" * 80)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    logger.info(f"🚀 Starting 311 AI Agent on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)