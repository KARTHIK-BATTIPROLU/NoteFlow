import os
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional

MONGODB_URL = os.getenv(
    "MONGODB_URL",
    "mongodb+srv://<db_username>:<db_password>@cluster0.mcueh4p.mongodb.net/?appName=Cluster0",
)
DATABASE_NAME = "noteflow"

client: Optional[AsyncIOMotorClient] = None


async def connect_to_mongo():
    global client
    client = AsyncIOMotorClient(MONGODB_URL)


async def close_mongo_connection():
    global client
    if client:
        client.close()


def get_database():
    return client[DATABASE_NAME]


def get_collection(name: str):
    return get_database()[name]


resources = lambda: get_collection("resources")
subjects = lambda: get_collection("subjects")
topics = lambda: get_collection("topics")
