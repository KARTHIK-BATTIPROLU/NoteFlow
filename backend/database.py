import os
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorGridFSBucket
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

MONGODB_URL = os.getenv(
    "MONGODB_URL",
    "mongodb+srv://vivekgaddam02_db_user:58R4u9ZC97Xsd8vp@cluster0.cqxqflr.mongodb.net/?appName=Cluster0",
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
