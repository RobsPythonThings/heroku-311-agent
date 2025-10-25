"""
Salesforce Token Keep-Alive Script
Runs indefinitely, pinging Salesforce every hour to keep the session token alive.
Kill this process after your demo/workshop.
"""

import os
import time
from simple_salesforce import Salesforce
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def ping_salesforce():
    """Ping Salesforce to keep token alive"""
    try:
        sf = Salesforce(
            instance_url=os.environ.get('SALESFORCE_INSTANCE_URL'),
            session_id=os.environ.get('SALESFORCE_ACCESS_TOKEN')
        )
        result = sf.query("SELECT Id FROM Case LIMIT 1")
        logger.info(f"✅ Token still alive! Found {result['totalSize']} cases")
        return True
    except Exception as e:
        logger.error(f"❌ Token ping failed: {e}")
        return False

def main():
    """Run keep-alive loop indefinitely"""
    logger.info("🚀 Starting Salesforce token keep-alive service...")
    logger.info(f"📍 Instance: {os.environ.get('SALESFORCE_INSTANCE_URL')}")
    logger.info("⏰ Will ping every 60 minutes")
    logger.info("💡 Press Ctrl+C to stop\n")
    
    ping_count = 0
    
    try:
        while True:
            ping_count += 1
            logger.info(f"🔄 Ping #{ping_count} at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            if ping_salesforce():
                logger.info("💚 Success! Sleeping for 60 minutes...\n")
            else:
                logger.warning("⚠️ Ping failed, but continuing. Check your token!\n")
            
            # Sleep for 1 hour (3600 seconds)
            time.sleep(3600)
            
    except KeyboardInterrupt:
        logger.info("\n👋 Keep-alive service stopped by user")
        logger.info(f"📊 Total pings sent: {ping_count}")
    except Exception as e:
        logger.error(f"💥 Unexpected error: {e}")
        raise

if __name__ == "__main__":
    main()