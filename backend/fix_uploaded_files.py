"""
Fix uploaded files that have JWT tokens instead of UIDs
This script extracts the actual UID from JWT tokens stored in firebase_uid field
"""
import os
import jwt
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv(
    "MONGODB_URL",
    "mongodb+srv://vivekgaddam02_db_user:58R4u9ZC97Xsd8vp@cluster0.cqxqflr.mongodb.net/?appName=Cluster0",
)
DATABASE_NAME = "noteflow"

def extract_uid_from_jwt(token):
    """Extract UID from JWT token without verification"""
    try:
        # Decode without verification (we just need to read the payload)
        decoded = jwt.decode(token, options={"verify_signature": False})
        return decoded.get('user_id') or decoded.get('sub')
    except Exception as e:
        print(f"Error decoding token: {e}")
        return None

def fix_resources():
    """Fix all resources that have JWT tokens as firebase_uid"""
    client = MongoClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    resources = db.resources
    
    print("=" * 60)
    print("Fixing uploaded files with JWT tokens")
    print("=" * 60)
    print()
    
    # Find all resources
    all_resources = list(resources.find({}))
    print(f"Found {len(all_resources)} total resources")
    print()
    
    fixed_count = 0
    
    for resource in all_resources:
        firebase_uid = resource.get('firebase_uid', '')
        
        # Check if it looks like a JWT token (contains dots)
        if firebase_uid.count('.') == 2:
            print(f"Resource ID: {resource['_id']}")
            print(f"Title: {resource.get('title', 'N/A')}")
            print(f"Current firebase_uid (JWT): {firebase_uid[:50]}...")
            
            # Extract actual UID
            actual_uid = extract_uid_from_jwt(firebase_uid)
            
            if actual_uid:
                print(f"Extracted UID: {actual_uid}")
                
                # Update the resource
                result = resources.update_one(
                    {'_id': resource['_id']},
                    {'$set': {'firebase_uid': actual_uid}}
                )
                
                if result.modified_count > 0:
                    print("✓ Updated successfully")
                    fixed_count += 1
                else:
                    print("✗ Update failed")
            else:
                print("✗ Could not extract UID from token")
            
            print()
    
    print("=" * 60)
    print(f"Fixed {fixed_count} resources")
    print("=" * 60)
    
    client.close()

if __name__ == "__main__":
    fix_resources()
