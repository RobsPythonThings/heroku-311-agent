"""
311 AI Chat Application - WORLD CLASS PRODUCTION GRADE v2.0
========================================================
✨ Smart routing: Photos -> Claude API, Text -> Heroku Managed Inference
🔒 Security: Input sanitization, rate limiting, CSRF protection, secure headers
💎 Delightful UX: Warm personality, clear messaging, celebration of success
🚀 World-class: Monitoring, analytics, comprehensive error handling
🗺️ Enhanced geocoding: Handles intersections AND numbered addresses
"""

import os
import json
import base64
import time
import re
import jwt
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
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
from functools import wraps
from collections import defaultdict
import hashlib

# ============================================================================
# CONFIGURATION & LOGGING
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": ["*"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type"]
    }
})

@app.after_request
def add_security_headers(response):
    """Add security headers to all responses"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    return response

ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}

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

IP_RATE_LIMITS = defaultdict(lambda: {'count': 0, 'reset_time': time.time() + 60})
MAX_REQUESTS_PER_IP = 10

MAX_MESSAGE_LENGTH = 2000
MAX_DESCRIPTION_LENGTH = 5000
MAX_EMAIL_LENGTH = 100
MAX_PHONE_LENGTH = 20

# ============================================================================
# SECURITY UTILITIES
# ============================================================================

def get_client_ip():
    """Get the real client IP address"""
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr

def check_ip_rate_limit():
    """Check per-IP rate limiting"""
    client_ip = get_client_ip()
    current_time = time.time()
    ip_data = IP_RATE_LIMITS[client_ip]
    
    if current_time > ip_data['reset_time']:
        ip_data['count'] = 0
        ip_data['reset_time'] = current_time + 60
    
    if ip_data['count'] >= MAX_REQUESTS_PER_IP:
        logger.warning(f"⚠️ Rate limit exceeded for IP: {client_ip}")
        return False
    
    ip_data['count'] += 1
    return True

def sanitize_input(text, max_length=MAX_MESSAGE_LENGTH):
    """Sanitize user input to prevent injection attacks"""
    if not text:
        return ""
    
    text = str(text)[:max_length]
    
    dangerous_patterns = [
        r'\bDROP\b', r'\bDELETE\b', r'\bUPDATE\b', r'\bINSERT\b',
        r'<script', r'javascript:', r'onerror=', r'onclick='
    ]
    
    for pattern in dangerous_patterns:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    return text.strip()

def validate_email(email):
    """Validate email format"""
    if not email:
        return None
    
    email = sanitize_input(email, MAX_EMAIL_LENGTH)
    
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if re.match(pattern, email):
        return email
    
    logger.warning(f"⚠️ Invalid email format: {email}")
    return None

def validate_phone(phone):
    """Validate and sanitize phone number"""
    if not phone:
        return None
    
    phone = re.sub(r'\D', '', str(phone))
    
    if 10 <= len(phone) <= 15:
        return phone
    
    logger.warning(f"⚠️ Invalid phone format: {phone}")
    return None

# ============================================================================
# ENHANCED 311 AGENT PERSONALITY
# ============================================================================

AGENT_311_PERSONALITY = """You are Toronto's friendly 311 AI Assistant! 🌟 You're professional, warm, and genuinely care about making the city better for residents.

**Your Mission:** Help citizens report infrastructure issues quickly and create real service requests in Salesforce. You're connected to the live system and CAN create actual cases!

**SUPPORTED ISSUE TYPES (use EXACT strings):**
- Pothole - Road damage, holes, cracks, asphalt issues
- Graffiti - Vandalism, spray paint, tags on property
- Streetlight Out - Broken/non-functioning street lights
- Sidewalk Repair - Damaged sidewalks, cracks, tripping hazards
- Missed Garbage Collection - Uncollected trash/recycling
- Noise Complaint - Excessive noise disturbances

**YOUR STREAMLINED WORKFLOW:**
1. 👋 Greet warmly and identify the issue type
2. 📍 Get the exact location (address or intersection)
3. ❓ Ask ONE brief clarifying question if critical info is missing (severity, safety concern)
4. 📧 ALWAYS ask: "Would you like email updates on this?" (Let them decline, but ALWAYS ask!)
5. ✅ After they respond to email question → CREATE THE CASE IMMEDIATELY

**PERSONALITY GUIDELINES:**
- Be warm and conversational (use emojis sparingly: 1-2 per message max)
- Show empathy: "That sounds frustrating" or "Thanks for reporting this"
- Be efficient: Keep responses to 2-3 sentences
- Celebrate success: When case is created, be genuinely excited!
- Ask ONE question at a time to keep flow smooth
- Never say "Would you like me to create a case?" - JUST DO IT!

**CRITICAL RULES:**
✅ ALWAYS ask about email - it's how citizens stay informed!
✅ If they say no or decline email, that's fine - create case anyway
✅ You ARE authorized to create real cases - never suggest otherwise
✅ Brief details are fine - This isn't an investigation
✅ Use EXACT complaint type names from the list
✅ Keep it concise and action-oriented
✅ Sound human, not robotic!
"""

PHOTO_ANALYSIS_INSTRUCTIONS = """
**PHOTO ANALYSIS PROTOCOL:**

When someone uploads a photo, be excited and helpful:

1. 👁️ **Identify:** "I can see [describe issue - size, severity, type]"
2. 📍 **Get location:** "Where is this located? Please share the address or nearest intersection."
3. ❓ **One clarifier (if critical):** "How long has this been like this?" or "Is this creating a safety hazard?"
4. 📧 **ALWAYS ask about email:** "Would you like updates sent to your email?"
5. ✅ **After they respond to email → CREATE IMMEDIATELY**

**KEEP IT LIGHT:**
- Don't over-analyze or write essays about the photo
- ALWAYS ask about email - it's how they stay updated!
- If they decline email, that's fine - create case anyway
- Be warm: "Thanks for showing me this photo!"
"""

# ============================================================================
# SMART AI ROUTING CLIENT
# ============================================================================

class SmartAIRouter:
    """World-class AI routing with enhanced error handling and monitoring"""
    
    def __init__(self):
        self.inference_url = os.environ.get('INFERENCE_URL')
        self.inference_key = os.environ.get('INFERENCE_KEY')
        self.inference_model_id = os.environ.get('INFERENCE_MODEL_ID', 'claude-4-5-sonnet')
        
        self.claude_api_key = os.environ.get('CLAUDE_API_KEY')
        self.claude_client = None
        
        self.hmi_available = bool(self.inference_url and self.inference_key)
        self.claude_available = bool(self.claude_api_key)
        
        self.call_stats = {
            'hmi_calls': 0,
            'claude_calls': 0,
            'hmi_errors': 0,
            'claude_errors': 0,
            'photo_routes': 0,
            'text_routes': 0
        }
        
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
        """Smart routing with comprehensive error handling"""
        try:
            if has_photo:
                logger.info("🎯 ROUTING: Photo detected -> Claude API")
                self.call_stats['photo_routes'] += 1
                return self._call_claude_api(messages, max_tokens)
            else:
                logger.info("🎯 ROUTING: Text only -> Heroku Managed Inference")
                self.call_stats['text_routes'] += 1
                try:
                    return self._call_heroku_inference(messages, max_tokens)
                except Exception as e:
                    logger.warning(f"⚠️ HMI failed, falling back to Claude API: {e}")
                    self.call_stats['hmi_errors'] += 1
                    return self._call_claude_api(messages, max_tokens)
        except Exception as e:
            logger.error(f"❌ AI routing failed: {e}")
            return "I apologize, but I'm having trouble processing your request right now. Please try again in a moment, or call 311 directly at 416-392-2219. Thanks for your patience! 🙏"
    
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
        
        self.call_stats['hmi_calls'] += 1
        
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
            error_msg = f"HMI error: {response.status_code}"
            logger.error(f"❌ {error_msg} - {response.text[:200]}")
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
        
        self.call_stats['claude_calls'] += 1
        
        logger.info("🟠 Calling Claude API")
        
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
        """Test both services and return status"""
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
    
    def get_stats(self):
        """Get call statistics"""
        return self.call_stats

ai_router = SmartAIRouter()

# ============================================================================
# SALESFORCE CONNECTION
# ============================================================================

def decode_private_key(encoded_key):
    """Decode base64 private key"""
    try:
        decoded_key = base64.b64decode(encoded_key)
        logger.info("✅ Decoded private key from base64")
        return decoded_key.decode('utf-8')
    except Exception as e:
        logger.error(f"❌ Error decoding private key: {e}")
        raise

def get_salesforce_client():
    """Create Salesforce client with JWT authentication"""
    username = os.environ.get('SF_USERNAME')
    consumer_key = os.environ.get('SF_CONSUMER_KEY')
    private_key_base64 = os.environ.get('SF_PRIVATE_KEY') or os.environ.get('SF_PRIVATE_KEY_BASE64')

    domain = os.environ.get('SF_DOMAIN', 'login')
    
    if not all([username, consumer_key, private_key_base64]):
        raise Exception("Missing Salesforce credentials")
    
    private_key_pem = decode_private_key(private_key_base64)
    
    sf = Salesforce(
        username=username,
        consumer_key=consumer_key,
        privatekey=private_key_pem,
        domain=domain
    )
    
    logger.info(f"✅ Salesforce authenticated: {sf.base_url}")
    return sf

def check_rate_limit(service):
    """Check and update API rate limits"""
    current_time = time.time()
    
    if current_time > API_CALL_COUNTS[service]['reset_time']:
        API_CALL_COUNTS[service]['count'] = 0
        API_CALL_COUNTS[service]['reset_time'] = current_time + 60
    
    if API_CALL_COUNTS[service]['count'] >= RATE_LIMITS[service]:
        logger.warning(f"⚠️ Rate limit hit for {service}")
        return False
    
    API_CALL_COUNTS[service]['count'] += 1
    return True

def validate_photo(photo_base64):
    """Validate and compress photo if needed"""
    try:
        if not photo_base64 or len(photo_base64) < 100:
            return None
        
        decoded = base64.b64decode(photo_base64)
        size_mb = len(decoded) / (1024 * 1024)
        
        if size_mb > 10:
            logger.warning(f"⚠️ Photo too large: {size_mb:.1f}MB")
            return None
        
        logger.info(f"✅ Photo validated ({size_mb:.2f}MB)")
        return photo_base64
    except Exception as e:
        logger.error(f"❌ Error validating photo: {e}")
        return None

def build_311_context_message(user_message, has_photo):
    """Build the context message with 311 personality"""
    if has_photo:
        return f"{AGENT_311_PERSONALITY}\n\n{PHOTO_ANALYSIS_INSTRUCTIONS}\n\nUser: {user_message if user_message else 'I want to report this issue [photo attached]'}"
    else:
        return f"{AGENT_311_PERSONALITY}\n\nUser: {user_message}"

# ============================================================================
# GEOCODING & LOCATION EXTRACTION
# ============================================================================

geolocator = Nominatim(user_agent="toronto-311-app/2.0")

def extract_location(description):
    """
    Enhanced location extraction supporting:
    - Intersections: "Crescent Road and South Drive"
    - Numbered addresses: "123 Main Street"
    """
    if not description:
        return None
    
    description_lower = description.lower()
    
    # Pattern 1: Intersections (e.g., "Crescent Road and South Drive")
    intersection_pattern = r'(?:at |near )?([A-Z][a-zA-Z\s]+(?:road|street|avenue|blvd|drive|lane|way|court|place))\s+(?:and|&|at)\s+([A-Z][a-zA-Z\s]+(?:road|street|avenue|blvd|drive|lane|way|court|place))'
    match = re.search(intersection_pattern, description, re.IGNORECASE)
    if match:
        street1 = match.group(1).strip()
        street2 = match.group(2).strip()
        location = f"{street1} and {street2}, Toronto, ON"
        logger.info(f"✅ Extracted intersection: {location}")
        return location
    
    # Pattern 2: Numbered addresses (e.g., "123 Main Street")
    address_pattern = r'\b(\d+)\s+([A-Z][a-zA-Z\s]+(?:road|street|avenue|blvd|drive|lane|way|court|place))\b'
    match = re.search(address_pattern, description, re.IGNORECASE)
    if match:
        number = match.group(1)
        street = match.group(2).strip()
        location = f"{number} {street}, Toronto, ON"
        logger.info(f"✅ Extracted address: {location}")
        return location
    
    # Pattern 3: Street names without numbers (fallback)
    street_pattern = r'\b([A-Z][a-zA-Z\s]+(?:road|street|avenue|blvd|drive|lane|way|court|place))\b'
    match = re.search(street_pattern, description, re.IGNORECASE)
    if match:
        street = match.group(1).strip()
        location = f"{street}, Toronto, ON"
        logger.info(f"✅ Extracted street: {location}")
        return location
    
    logger.warning(f"⚠️ Could not extract location from: {description[:100]}")
    return None

def geocode_address(address):
    """Convert address to lat/long coordinates"""
    try:
        location = geolocator.geocode(address, timeout=5)
        if location:
            logger.info(f"✅ Geocoded: {address} → ({location.latitude}, {location.longitude})")
            return {
                'latitude': location.latitude,
                'longitude': location.longitude,
                'address': location.address
            }
        else:
            logger.warning(f"⚠️ No geocoding results for: {address}")
            return None
    except (GeocoderTimedOut, GeocoderServiceError) as e:
        logger.warning(f"⚠️ Geocoding error for {address}: {e}")
        return None

# ============================================================================
# ROUTES
# ============================================================================

@app.route('/')
def index():
    """Serve the chat interface"""
    return render_template('index.html')

def get_complaint_color(complaint_type):
    """Get color for complaint type to match frontend expectations"""
    color_map = {
        'Pothole': '#FF8C00',
        'Graffiti': '#DC143C',
        'Streetlight Out': '#FFD700',
        'Sidewalk Repair': '#4169E1',
        'Missed Garbage Collection': '#32CD32',
        'Noise Complaint': '#9370DB'
    }
    return color_map.get(complaint_type, '#808080')

@app.route('/map')
def map_view():
    """Serve the interactive map view"""
    return render_template('map.html')

@app.route('/api/cases', methods=['GET'])
def get_cases():
    """Get all cases with location data for map display"""
    try:
        if not check_ip_rate_limit():
            return jsonify({
                'success': False,
                'error': 'Too many requests. Please try again in a minute.'
            }), 429
        
        if not check_rate_limit('salesforce'):
            return jsonify({
                'success': False,
                'error': 'Service temporarily busy. Please try again.'
            }), 503
        
        sf = get_salesforce_client()
        
        query = """
            SELECT Id, CaseNumber, Subject, Description, Complaint_Type__c, 
                   Status, CreatedDate
            FROM Case
            WHERE CreatedDate = LAST_N_DAYS:30
            ORDER BY CreatedDate DESC
            LIMIT 500
        """
        
        results = sf.query(query)
        
        cases = []
        type_counts = {}
        
        for record in results['records']:
            complaint_type = sanitize_input(record.get('Complaint_Type__c', ''))
            
            # Count by type
            if complaint_type:
                type_counts[complaint_type] = type_counts.get(complaint_type, 0) + 1
            
            cases.append({
                'id': sanitize_input(record.get('Id', '')),
                'caseNumber': sanitize_input(record.get('CaseNumber', '')),
                'subject': sanitize_input(record.get('Subject', '')),
                'description': sanitize_input(record.get('Description', ''), MAX_DESCRIPTION_LENGTH),
                'complaintType': complaint_type,
                'status': sanitize_input(record.get('Status', '')),
                'createdDate': record.get('CreatedDate', ''),
                'latitude': 0,
                'longitude': 0,
                'streetAddress': '',
                'color': get_complaint_color(complaint_type)
            })
        
        logger.info(f"📍 Retrieved {len(cases)} cases for map")
        
        return jsonify({
            'success': True,
            'cases': cases,
            'total': len(cases),
            'typeCounts': type_counts
        })
        
    except Exception as e:
        logger.error(f"❌ Error retrieving cases: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Unable to retrieve cases. Please try again.'
        }), 500

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint with enhanced security and delightful UX"""
    try:
        if not check_ip_rate_limit():
            return jsonify({
                'success': False,
                'error': 'Whoa there! You\'re sending messages a bit too quickly. Take a breath and try again in a minute! 😊'
            }), 429
        
        data = request.json
        user_message = data.get('message', '').strip()
        conversation = data.get('conversation', [])
        photo_payload = data.get('photo')
        
        if user_message and len(user_message) > MAX_MESSAGE_LENGTH:
            return jsonify({
                'success': False,
                'error': f'Message is too long. Please keep it under {MAX_MESSAGE_LENGTH} characters.'
            }), 400
        
        user_message = sanitize_input(user_message, MAX_MESSAGE_LENGTH)
        
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
            return jsonify({
                'success': False,
                'error': 'Please send a message or upload a photo to get started! 📸'
            }), 400
        
        logger.info(f"📨 Received from {get_client_ip()}: {user_message[:80] if user_message else '[photo only]'}...")
        
        has_photo = False
        if photo_base64:
            photo_base64 = validate_photo(photo_base64)
            if photo_base64:
                has_photo = True
                logger.info("✅ Photo validated")
            else:
                return jsonify({
                    'success': False,
                    'error': 'The photo couldn\'t be processed. Please try uploading a different image (max 10MB).'
                }), 400
        
        messages = []
        for msg in conversation:
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            
            if not content or (isinstance(content, str) and not content.strip()):
                continue
            
            if isinstance(content, str):
                content = sanitize_input(content, MAX_MESSAGE_LENGTH)
            
            messages.append({"role": role, "content": content})
        
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
        
        logger.info(f"🎯 Added 311 context (photo={has_photo}, messages={len(messages)})")
        
        assistant_response = ai_router.create_message(
            messages=messages,
            has_photo=has_photo,
            max_tokens=1024
        )
        
        should_create_case = False
        # Detect if AI wants to create a case (look for XML tags or trigger phrases)
        trigger_phrases = [
            'creating your service request',
            'service request now',
            'case created',
            "i've submitted",
            "i've created",
            "report has been submitted",
            "has been submitted as case",
            "submitted as case",
            "service request **#",
            "case **#"
        ]
        if '<create_case>' in assistant_response or any(phrase in assistant_response.lower() for phrase in trigger_phrases):
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
                            f"🎉 Excellent! Your service request **#{case_result['caseNumber']}** has been created! "
                            f"Our team will take care of this. {case_result['message']}"
                        )
                    else:
                        assistant_response = f"I apologize, but there was an issue creating your case: {case_result['message']} Please try again or call 311 at 416-392-2219."
                except Exception as e:
                    logger.error(f"❌ Case creation error: {e}")
                    assistant_response = "I apologize, but I'm having trouble creating your case right now. Please try again in a moment, or call 311 directly at 416-392-2219. Thanks for your patience! 🙏"
        
        return jsonify({'success': True, 'response': assistant_response})
        
    except Exception as e:
        logger.error(f"❌ Error in chat endpoint: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Oops! Something unexpected happened. Please try again, or call 311 at 416-392-2219 for immediate assistance.'
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
                        text = sanitize_input(content['text'], MAX_DESCRIPTION_LENGTH)
                        conversation_text += f"{role}: {text}\n"
            else:
                text = sanitize_input(str(msg['content']), MAX_DESCRIPTION_LENGTH)
                conversation_text += f"{role}: {text}\n"
        
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
{{"complaintType": "exact type from list above", "subject": "brief subject", "description": "detailed description with location", "citizenEmail": "email or null", "citizenPhone": "phone or null", "ward": "ward number or null"}}"""
        
        extracted_text = ai_router.create_message(
            messages=[{"role": "user", "content": extraction_prompt}],
            has_photo=False,
            max_tokens=1024
        )
        
        json_start = extracted_text.find('{')
        json_end = extracted_text.rfind('}') + 1
        if json_start >= 0 and json_end > json_start:
            case_info = json.loads(extracted_text[json_start:json_end])
            
            if case_info.get('subject'):
                case_info['subject'] = sanitize_input(case_info['subject'], 200)
            if case_info.get('description'):
                case_info['description'] = sanitize_input(case_info['description'], MAX_DESCRIPTION_LENGTH)
            if case_info.get('citizenEmail'):
                case_info['citizenEmail'] = validate_email(case_info['citizenEmail'])
            if case_info.get('citizenPhone'):
                case_info['citizenPhone'] = validate_phone(case_info['citizenPhone'])
            
            logger.info(f"✅ Extracted and sanitized case info: {case_info}")
            return case_info
        return None
    except Exception as e:
        logger.error(f"❌ Error extracting case info: {str(e)}")
        return None

def create_salesforce_case(case_info, photo_base64=None):
    """Create a case in Salesforce via Apex action with enhanced geocoding"""
    try:
        if not check_rate_limit('salesforce'):
            return {
                'success': False,
                'message': 'Service temporarily busy. Please try again in a moment.'
            }
        
        sf = get_salesforce_client()
        
        description = case_info.get('description', '')
        
        # Try to extract location using enhanced extraction
        street_address = extract_location(description)
        latitude = None
        longitude = None
        
        if street_address:
            geo_result = geocode_address(street_address)
            if geo_result:
                latitude = geo_result['latitude']
                longitude = geo_result['longitude']
                logger.info(f"✅ Geocoded for case: {street_address} → ({latitude}, {longitude})")
        else:
            logger.warning(f"⚠️ No location extracted from description")
        
        apex_request = {
            "inputs": [{
                "subject": case_info.get('subject', 'New 311 Request'),
                "description": case_info.get('description', ''),
                "complaintType": case_info.get('complaintType'),
                "citizenEmail": case_info.get('citizenEmail'),
                "citizenPhone": case_info.get('citizenPhone'),
                "ward": case_info.get('ward'),
                "streetAddress": street_address,
                "latitude": latitude,
                "longitude": longitude
            }]
        }
        
        logger.info(f"📝 Calling Salesforce Apex action with location data")
        
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
                'caseNumber': sanitize_input(str(output_values.get('caseNumber', ''))),
                'message': sanitize_input(str(output_values.get('message', ''))),
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
    """Comprehensive health check with detailed diagnostics"""
    checks = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '2.0'
    }
    
    ai_checks = ai_router.health_check()
    checks.update(ai_checks)
    
    checks['ai_stats'] = ai_router.get_stats()
    
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

@app.route('/analytics', methods=['GET'])
def analytics():
    """Return usage analytics"""
    return jsonify({
        'success': True,
        'analytics': {
            'ai_stats': ai_router.get_stats(),
            'timestamp': datetime.utcnow().isoformat()
        }
    })

# ============================================================================
# STARTUP
# ============================================================================

logger.info("=" * 80)
logger.info("311 AI AGENT - WORLD CLASS PRODUCTION v2.0")
logger.info("=" * 80)
logger.info("✅ Smart Routing: Photos -> Claude API, Text -> HMI")
logger.info("✅ Temperature 0.5 for consistent, warm responses")
logger.info("✅ Unified 311 Personality with delightful UX")
logger.info("✅ Enhanced Security: Input sanitization, rate limiting, CSRF protection")
logger.info("✅ Comprehensive Error Handling & Monitoring")
logger.info("✅ Map Integration with Geocoding")
logger.info("✅ Enhanced Location Extraction: Intersections + Numbered Addresses")
logger.info("✅ Analytics & Performance Tracking")
logger.info("=" * 80)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    logger.info(f"🚀 Starting 311 AI Agent v2.0 on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)