"""
311 AI Chat Application
Flask backend for handling chat conversations and creating Salesforce cases
"""

import os
import json
import base64
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import anthropic
from simple_salesforce import Salesforce
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Initialize Anthropic client
claude_client = anthropic.Anthropic(api_key=os.environ.get('CLAUDE_API_KEY'))

# Initialize Salesforce client
def get_salesforce_client():
    """Initialize and return Salesforce client with username/password auth"""
    return Salesforce(
        username=os.environ.get('SALESFORCE_USERNAME'),
        password=os.environ.get('SALESFORCE_PASSWORD'),
        security_token='',  # Security token already included in password
        domain='test' if 'test' in os.environ.get('SALESFORCE_INSTANCE_URL', '') else 'login'
    )

# Agent system prompt for 311 conversations
AGENT_SYSTEM_PROMPT = """You are a helpful 311 AI Assistant for Toronto's municipal services. Your role is to:

1. Help citizens report issues like potholes, graffiti, streetlight outages, noise complaints, etc.
2. Gather required information: issue type, description, location, and contact info
3. Be empathetic and professional
4. Ask clarifying questions when needed
5. Confirm case creation with case numbers

Available complaint types:
- Pothole
- Graffiti
- Streetlight Out
- Sidewalk Repair
- Road Repair
- Noise Complaint
- Missed Garbage Collection
- Recycling Issue
- Water Leak
- Sewage Issue
- Tree Issue
- Park Maintenance

When you have enough information (complaint type, description, and optionally location/contact), respond with:
READY_TO_CREATE_CASE

Then I will create the case in Salesforce and give you the case number to share with the citizen."""

@app.route('/')
def index():
    """Serve the chat widget"""
    return render_template('index.html')

def find_photo_in_conversation(conversation_history):
    """Search conversation history for a photo"""
    for msg in reversed(conversation_history):
        photo = msg.get('photo')
        if photo:
            logger.info(f"Found photo in conversation history")
            return photo
    logger.info("No photo found in conversation history")
    return None

@app.route('/chat', methods=['POST'])
def chat():
    """Handle chat messages"""
    try:
        data = request.json
        user_message = data.get('message', '')
        conversation_history = data.get('conversation_history', [])
        photo_base64 = data.get('photo')
        
        # Quick fix: if message is empty but there's a photo, add placeholder
        if not user_message and photo_base64:
            user_message = "Photo attached"
        
        logger.info(f"Received message: {user_message[:100]}")
        
        messages = []
        for msg in conversation_history:
            messages.append({"role": msg["role"], "content": msg["content"]})
        
        current_message_content = [{"type": "text", "text": user_message}]
        
        # Handle photo - can be either string (old format) or object (new format)
        photo_data = None
        photo_media_type = "image/jpeg"
        
        if photo_base64:
            logger.info("Photo included in message")
            if isinstance(photo_base64, dict):
                # New format: {data: base64, media_type: 'image/png'}
                photo_data = photo_base64.get('data')
                photo_media_type = photo_base64.get('media_type', 'image/jpeg')
            else:
                # Old format: just base64 string
                photo_data = photo_base64
            
            if photo_data:
                current_message_content.append({
                    "type": "image",
                    "source": {"type": "base64", "media_type": photo_media_type, "data": photo_data}
                })
        
        messages.append({"role": "user", "content": current_message_content})
        
        response = claude_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2048,
            system=AGENT_SYSTEM_PROMPT,
            messages=messages
        )
        
        assistant_response = response.content[0].text
        logger.info(f"Claude response: {assistant_response[:100]}")
        
        if "READY_TO_CREATE_CASE" in assistant_response:
            logger.info("Agent ready to create case, extracting info...")
            case_info = extract_case_info_from_conversation(messages)
            
            if case_info:
                # Check current message first, then search history for photo
                photo_to_attach = photo_base64 or find_photo_in_conversation(conversation_history)
                case_result = create_salesforce_case(case_info, photo_to_attach)
                
                if case_result['success']:
                    assistant_response = assistant_response.replace(
                        "READY_TO_CREATE_CASE",
                        f"Great! I've created your service request. Your case number is **{case_result['caseNumber']}**. "
                        f"You can use this number to track your request. {case_result['message']}"
                    )
                else:
                    assistant_response = f"I apologize, but there was an error creating your case: {case_result['message']}"
        
        return jsonify({'success': True, 'response': assistant_response})
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

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
        
        response = claude_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1024,
            messages=[{"role": "user", "content": extraction_prompt}]
        )
        
        extracted_text = response.content[0].text
        json_start = extracted_text.find('{')
        json_end = extracted_text.rfind('}') + 1
        if json_start >= 0 and json_end > json_start:
            case_info = json.loads(extracted_text[json_start:json_end])
            logger.info(f"Extracted case info: {case_info}")
            return case_info
        return None
    except Exception as e:
        logger.error(f"Error extracting case info: {str(e)}")
        return None

def create_salesforce_case(case_info, photo_base64=None):
    """Create a case in Salesforce"""
    try:
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
        
        logger.info(f"Creating case with data: {apex_request}")
        
        result = sf.restful('actions/custom/apex/Create311Case', method='POST', data=json.dumps(apex_request))
        logger.info(f"Salesforce response: {result}")
        
        if result and len(result) > 0:
            case_result = result[0]
            output_values = case_result.get('outputValues', {})
            case_id = output_values.get('caseId')
            
            logger.info(f"Photo attachment check - photo_base64 type: {type(photo_base64)}, case_id: {case_id}")
            if photo_base64 and case_id:
                try:
                    # Extract base64 data if photo is an object
                    photo_data = photo_base64.get('data') if isinstance(photo_base64, dict) else photo_base64
                    logger.info(f"Extracted photo_data length: {len(photo_data) if photo_data else 0}")
                    if photo_data:
                        logger.info(f"Attempting to attach photo to case {case_id}")
                        attach_photo_to_case(sf, case_id, photo_data)
                    else:
                        logger.warning("photo_data is empty after extraction")
                except Exception as e:
                    # Log but don't fail - case was created successfully
                    logger.warning(f"Photo attachment failed for case {case_id}: {e}")
            else:
                logger.warning(f"Photo attachment skipped - photo_base64: {bool(photo_base64)}, case_id: {case_id}")
            
            return {
                'success': output_values.get('success', False),
                'caseNumber': output_values.get('caseNumber'),
                'message': output_values.get('message', ''),
                'caseId': output_values.get('caseId')
            }
        
        return {'success': False, 'message': 'Unexpected response from Salesforce'}
    except Exception as e:
        logger.error(f"Error creating Salesforce case: {str(e)}")
        return {'success': False, 'message': str(e)}

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
        logger.info(f"Photo attached to case {case_id}: {result}")
        return True
    except Exception as e:
        logger.error(f"Error attaching photo: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """Enhanced health check - tests all critical services"""
    checks = {
        'status': 'healthy',
        'claude_api': 'unknown',
        'salesforce': 'unknown'
    }
    
    try:
        # Test Claude API
        claude_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=10,
            messages=[{"role": "user", "content": "test"}]
        )
        checks['claude_api'] = 'ok'
    except Exception as e:
        logger.error(f"Claude health check failed: {e}")
        checks['claude_api'] = 'error'
        checks['status'] = 'degraded'
    
    try:
        # Test Salesforce connection
        sf = get_salesforce_client()
        sf.query("SELECT Id FROM Case LIMIT 1")
        checks['salesforce'] = 'ok'
    except Exception as e:
        logger.error(f"Salesforce health check failed: {e}")
        checks['salesforce'] = 'error'
        checks['status'] = 'degraded'
    
    return jsonify(checks)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)