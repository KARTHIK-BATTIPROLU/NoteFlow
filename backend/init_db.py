"""
Script to initialize MongoDB collections with sample data.
Run this script to set up your NoteFlow database with collections, indexes, and initial taxonomy seed.
"""
import asyncio
import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError(
        "MONGODB_URL environment variable is not set. "
        "Set it in backend/.env or your shell environment before running this script."
    )
DATABASE_NAME = "noteflow"


def _masked(url: str) -> str:
    """Hide credentials when logging the connection string."""
    if "@" in url:
        scheme, rest = url.split("://", 1)
        return f"{scheme}://***:***@{rest.split('@', 1)[1]}"
    return url


async def init_database():
    """Initialize MongoDB database with collections, indexes, and seed sample data."""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    print(f"Connected to MongoDB at {_masked(MONGODB_URL)}")
    print(f"Database: {DATABASE_NAME}")

    collections_to_create = ["subjects", "topics", "resources", "users"]
    existing_collections = await db.list_collection_names()

    for collection_name in collections_to_create:
        if collection_name not in existing_collections:
            await db.create_collection(collection_name)
            print(f"✓ Created collection: {collection_name}")
        else:
            print(f"✓ Collection already exists: {collection_name}")

    print("\nCreating indexes...")

    # Subjects indexes
    await db.subjects.create_index("name")
    print("✓ Created index on subjects.name")

    # Topics indexes
    await db.topics.create_index([("name", 1), ("subject", 1)])
    print("✓ Created index on topics.name and topics.subject")

    # Resources indexes
    await db.resources.create_index([("title", 1), ("subject", 1), ("topic", 1)])
    await db.resources.create_index("created_at")
    await db.resources.create_index("sha256")
    await db.resources.create_index("firebase_uid")
    await db.resources.create_index("subject")
    print("✓ Created indexes on resources (created_at, sha256, firebase_uid, subject)")

    # Users indexes
    await db.users.create_index("firebase_uid", unique=True)
    print("✓ Created unique index on users.firebase_uid")

    subject_count = await db.subjects.count_documents({})
    if subject_count == 0:
        print("\nAdding taxonomy seed data...")

        subjects = [
            {"name": "Computer Science"},
            {"name": "Mathematics"},
            {"name": "Physics"},
            {"name": "Chemistry"},
        ]

        subject_result = await db.subjects.insert_many(subjects)
        print(f"✓ Added {len(subject_result.inserted_ids)} subjects")

        cs_id, math_id, phy_id, chem_id = [str(sid) for sid in subject_result.inserted_ids]

        topics = [
            {"name": "Data Structures & Algorithms", "subject": cs_id},
            {"name": "Object-Oriented Programming", "subject": cs_id},
            {"name": "Database Management Systems", "subject": cs_id},
            {"name": "Operating Systems", "subject": cs_id},
            {"name": "Computer Networks", "subject": cs_id},
            {"name": "Calculus", "subject": math_id},
            {"name": "Linear Algebra", "subject": math_id},
            {"name": "Statistics", "subject": math_id},
            {"name": "Mechanics", "subject": phy_id},
            {"name": "Thermodynamics", "subject": phy_id},
            {"name": "Organic Chemistry", "subject": chem_id},
            {"name": "Inorganic Chemistry", "subject": chem_id},
        ]

        topic_result = await db.topics.insert_many(topics)
        print(f"✓ Added {len(topic_result.inserted_ids)} topics")
        print("\n✓ Seed taxonomy added successfully!")
    else:
        print(f"\n✓ Database already contains {subject_count} subjects. Skipping seed taxonomy.")

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
