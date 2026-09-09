import os
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError(
        "MONGODB_URL environment variable is not set. "
        "Please set MONGODB_URL in backend/.env or in your environment."
    )
MONGODB_URL = MONGODB_URL.strip()

DATABASE_NAME = os.getenv("DATABASE_NAME", "noteflow").strip()

client: Optional[AsyncIOMotorClient] = None

async def connect_to_mongo():
    global client
    client = AsyncIOMotorClient(MONGODB_URL)
    print(f"[database] Connected to MongoDB database: {DATABASE_NAME}")


async def close_mongo_connection():
    global client
    if client:
        client.close()
        print("[database] MongoDB connection closed.")


def get_database():
    if client is None:
        raise RuntimeError("MongoDB client is not initialized. Call connect_to_mongo() first.")
    return client[DATABASE_NAME]


def get_collection(name: str):
    return get_database()[name]


resources = lambda: get_collection("resources")
subjects = lambda: get_collection("subjects")
topics = lambda: get_collection("topics")
users = lambda: get_collection("users")
