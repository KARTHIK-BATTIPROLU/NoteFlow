"""
Migration script to copy legacy GridFS files to Cloudflare R2 object storage.
Reads all resource documents containing legacy `file_id`, streams content from GridFS,
uploads to R2, and updates the document with `storage_key` and status `published`.
"""
import asyncio
import os
import uuid
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorGridFSBucket
from dotenv import load_dotenv

load_dotenv()

from storage import get_s3_client, R2_BUCKET

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError("MONGODB_URL is not set.")
DATABASE_NAME = "noteflow"


async def migrate_gridfs_to_r2():
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    fs = AsyncIOMotorGridFSBucket(db)
    s3 = get_s3_client()

    resources_coll = db["resources"]
    cursor = resources_coll.find({"file_id": {"$exists": True}})
    docs = await cursor.to_list(length=None)

    print(f"Found {len(docs)} legacy GridFS resources to migrate...")

    migrated_count = 0
    for doc in docs:
        file_id_str = doc.get("file_id")
        doc_id = doc["_id"]
        title = doc.get("title", "Untitled")
        firebase_uid = doc.get("firebase_uid", "legacy")
        content_type = doc.get("content_type", "application/pdf")

        print(f"\nMigrating resource '{title}' (id={doc_id}, file_id={file_id_str})...")

        try:
            object_id = ObjectId(file_id_str)
            download_stream = await fs.open_download_stream(object_id)
            file_bytes = await download_stream.read()

            storage_key = f"resources/{firebase_uid}/{uuid.uuid4()}"

            s3.put_object(
                Bucket=R2_BUCKET,
                Key=storage_key,
                Body=file_bytes,
                ContentType=content_type,
            )

            await resources_coll.update_one(
                {"_id": doc_id},
                {
                    "$set": {
                        "storage_key": storage_key,
                        "status": "published",
                    },
                    "$unset": {"file_id": ""},
                },
            )
            print(f"✓ Migrated '{title}' -> R2 key: {storage_key}")
            migrated_count += 1

        except Exception as e:
            print(f"✗ Failed to migrate '{title}': {e}")

    print(f"\nMigration completed. {migrated_count}/{len(docs)} files migrated to R2.")
    client.close()


if __name__ == "__main__":
    asyncio.run(migrate_gridfs_to_r2())
