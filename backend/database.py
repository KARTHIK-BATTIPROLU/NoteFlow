import os
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorGridFSBucket
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError(
        "MONGODB_URL environment variable is not set. "
        "Set it in backend/.env or your shell environment before starting the server."
    )
DATABASE_NAME = "noteflow"

client: Optional[AsyncIOMotorClient] = None
fs: Optional[AsyncIOMotorGridFSBucket] = None

async def connect_to_mongo():
    global client, fs
    client = AsyncIOMotorClient(MONGODB_URL)
    fs = AsyncIOMotorGridFSBucket(client[DATABASE_NAME])


async def close_mongo_connection():
    global client
    if client:
        client.close()


def get_database():
    return client[DATABASE_NAME]

def get_gridfs():
    return fs

def get_collection(name: str):
    return get_database()[name]


resources = lambda: get_collection("resources")
subjects = lambda: get_collection("subjects")
topics = lambda: get_collection("topics")
