import requests
import json

# Test if backend is accessible
print("Testing backend connection...")
try:
    response = requests.get('http://localhost:8000/')
    print(f"✓ Backend is accessible: {response.json()}")
except Exception as e:
    print(f"✗ Backend connection failed: {e}")
    exit(1)

# Check MongoDB connection
from pymongo import MongoClient
try:
    client = MongoClient('mongodb://localhost:27017/')
    db = client['noteflow']
    db.command('ping')
    print(f"✓ MongoDB is accessible")
    print(f"  Resources count: {db.resources.count_documents({})}")
    print(f"  Subjects count: {db.subjects.count_documents({})}")
    print(f"  Topics count: {db.topics.count_documents({})}")
except Exception as e:
    print(f"✗ MongoDB connection failed: {e}")
