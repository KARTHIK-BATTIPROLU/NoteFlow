import os
from pymongo import MongoClient

from dotenv import load_dotenv
load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError(
        "MONGODB_URL environment variable is not set. "
        "Set it in backend/.env or your shell environment before running this script."
    )

client = MongoClient(MONGODB_URL)
db = client['noteflow']

print("=" * 50)
print("MongoDB Resources Check")
print("=" * 50)

count = db.resources.count_documents({})
print(f"\nTotal resources in database: {count}")

if count > 0:
    print("\nRecent uploads:")
    resources = list(db.resources.find().sort("created_at", -1).limit(10))
    for i, r in enumerate(resources, 1):
        print(f"\n{i}. Title: {r.get('title', 'N/A')}")
        print(f"   Subject: {r.get('subject', 'N/A')}")
        print(f"   Topic: {r.get('topic', 'N/A')}")
        print(f"   User UID: {r.get('firebase_uid', 'N/A')}")
        print(f"   File ID: {r.get('file_id', 'N/A')}")
        print(f"   Created: {r.get('created_at', 'N/A')}")
else:
    print("\n❌ No resources found in database!")

print("\n" + "=" * 50)
