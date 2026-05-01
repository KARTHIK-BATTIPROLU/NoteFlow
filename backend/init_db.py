"""
Script to initialize MongoDB collections with sample data
Run this script to set up your NoteFlow database with collections and sample data
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
from datetime import datetime

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017/")
DATABASE_NAME = "noteflow"


async def init_database():
    """Initialize MongoDB database with collections and sample data"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    
    print(f"Connected to MongoDB at {MONGODB_URL}")
    print(f"Database: {DATABASE_NAME}")
    
    # Create collections
    existing_collections = await db.list_collection_names()
    
    collections_to_create = ["subjects", "topics", "resources"]
    
    for collection_name in collections_to_create:
        if collection_name not in existing_collections:
            await db.create_collection(collection_name)
            print(f"✓ Created collection: {collection_name}")
        else:
            print(f"✓ Collection already exists: {collection_name}")
    
    # Create indexes
    print("\nCreating indexes...")
    
    # Subjects indexes
    await db.subjects.create_index("name")
    print("✓ Created index on subjects.name")
    
    # Topics indexes
    await db.topics.create_index([("name", 1), ("subject", 1)])
    print("✓ Created index on topics.name and topics.subject")
    
    # Resources indexes
    await db.resources.create_index([("title", 1), ("subject", 1), ("topic", 1)])
    await db.resources.create_index("uploaded_at")
    print("✓ Created indexes on resources")
    
    # Check if we should add sample data
    subject_count = await db.subjects.count_documents({})
    
    if subject_count == 0:
        print("\nAdding sample data...")
        
        # Add sample subjects
        subjects = [
            {"name": "Mathematics"},
            {"name": "Physics"},
            {"name": "Computer Science"},
        ]
        
        subject_result = await db.subjects.insert_many(subjects)
        print(f"✓ Added {len(subject_result.inserted_ids)} subjects")
        
        # Add sample topics
        math_id = subject_result.inserted_ids[0]
        physics_id = subject_result.inserted_ids[1]
        cs_id = subject_result.inserted_ids[2]
        
        topics = [
            {"name": "Calculus", "subject": str(math_id)},
            {"name": "Linear Algebra", "subject": str(math_id)},
            {"name": "Mechanics", "subject": str(physics_id)},
            {"name": "Thermodynamics", "subject": str(physics_id)},
            {"name": "Data Structures", "subject": str(cs_id)},
            {"name": "Algorithms", "subject": str(cs_id)},
        ]
        
        topic_result = await db.topics.insert_many(topics)
        print(f"✓ Added {len(topic_result.inserted_ids)} topics")
        
        print("\n✓ Sample data added successfully!")
    else:
        print(f"\n✓ Database already contains {subject_count} subjects. Skipping sample data.")
    
    # Display collection stats
    print("\n" + "="*50)
    print("DATABASE STATISTICS")
    print("="*50)
    
    for collection_name in collections_to_create:
        count = await db[collection_name].count_documents({})
        print(f"{collection_name.capitalize()}: {count} documents")
    
    print("="*50)
    print("\n✓ Database initialization complete!")
    
    client.close()


if __name__ == "__main__":
    asyncio.run(init_database())
