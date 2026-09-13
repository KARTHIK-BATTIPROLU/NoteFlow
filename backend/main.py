import os
import json
import logging
import uuid
import re
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Depends, Query, Header
from fastapi.middleware.cors import CORSMiddleware
from bson import ObjectId
import firebase_admin
from firebase_admin import credentials, auth

from dotenv import load_dotenv
load_dotenv()

from pymongo import ReturnDocument

from database import (
    connect_to_mongo,
    close_mongo_connection,
    subjects as subjects_collection,
    topics as topics_collection,
    resources as resources_collection,
    users as users_collection,
    get_database,
)
from models import (
    SubjectResponse,
    SubjectCreate,
    TopicResponse,
    TopicCreate,
    ResourceResponse,
    UploadInitRequest,
    UploadInitResponse,
    UploadCompleteRequest,
    DownloadResponse,
    LikeResponse,
)
import storage

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("noteflow")

# Validate required env vars at startup
REQUIRED_ENV_VARS = ["MONGODB_URL"]
for var in REQUIRED_ENV_VARS:
    if not os.environ.get(var):
        raise RuntimeError(f"Required environment variable '{var}' is missing. Check backend/.env")

# Initialize Firebase Admin SDK
_sa_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")
_sa_path = os.environ.get("FIREBASE_SERVICE_ACCOUNT")
if _sa_json:
    _sa_json = _sa_json.strip()
if _sa_path:
    _sa_path = _sa_path.strip()

if not _sa_json and not _sa_path:
    local_sa = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "serviceAccount.json"))
    if os.path.exists(local_sa):
        _sa_path = local_sa

try:
    if _sa_json:
        _creds = credentials.Certificate(json.loads(_sa_json))
        firebase_admin.initialize_app(_creds)
        logger.info("[auth] Firebase initialized with service account from FIREBASE_SERVICE_ACCOUNT_JSON")
    elif _sa_path:
        _creds = credentials.Certificate(_sa_path)
        firebase_admin.initialize_app(_creds)
        logger.info(f"[auth] Firebase initialized with service account file: {_sa_path}")
    else:
        firebase_admin.initialize_app()
        logger.info("[auth] Firebase initialized with ambient credentials")
except ValueError:
    if not firebase_admin._apps:
        raise

if not firebase_admin.get_app().project_id:
    raise RuntimeError(
        "Firebase Admin has no project ID. Set FIREBASE_SERVICE_ACCOUNT_JSON in environment."
    )

app = FastAPI(title="NoteFlow API", version="1.0.0")

# CORS middleware
origins = os.environ.get("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB limit
ALLOWED_CONTENT_TYPES = {
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.ms-powerpoint",
}


@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()
    await initialize_collections()


@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()


@app.get("/")
async def root():
    return {"message": "Welcome to NoteFlow API"}


@app.get("/health")
async def health():
    try:
        import database
        client = database.client
        if client is None:
            raise RuntimeError("Database client not initialized")
        await client.admin.command("ping")
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        return {"status": "error", "db": str(e)}


async def initialize_collections():
    """Initialize MongoDB collections and indexes."""
    db = get_database()
    existing_collections = await db.list_collection_names()

    for coll_name in ["subjects", "topics", "resources", "users"]:
        if coll_name not in existing_collections:
            await db.create_collection(coll_name)
            logger.info(f"Created '{coll_name}' collection")

    # Create indexes
    await subjects_collection().create_index("name")
    await topics_collection().create_index([("name", 1), ("subject", 1)])
    
    res_coll = resources_collection()
    await res_coll.create_index([("title", 1), ("subject", 1), ("topic", 1)])
    await res_coll.create_index("created_at")
    await res_coll.create_index("sha256")
    await res_coll.create_index("firebase_uid")
    await res_coll.create_index("subject")

    await users_collection().create_index("firebase_uid", unique=True)
    logger.info("Collections and indexes initialized successfully")


async def verify_firebase_token(authorization: str = Header(...)) -> str:
    """Verify Firebase ID token and return uid."""
    try:
        parts = authorization.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        token = parts[1]

        try:
            decoded_token = auth.verify_id_token(token)
            return decoded_token["uid"]
        except auth.ExpiredIdTokenError:
            raise HTTPException(status_code=401, detail="Token has expired")
        except auth.InvalidIdTokenError as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Token verification failed: {e}")

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unexpected error verifying token")
        raise HTTPException(status_code=401, detail="Unauthorized")


async def get_or_create_user_handle(firebase_uid: str) -> str:
    """Get existing user pseudonymous handle or generate a new one."""
    users_coll = users_collection()
    user_doc = await users_coll.find_one({"firebase_uid": firebase_uid})
    if user_doc and "handle" in user_doc:
        return user_doc["handle"]

    # Generate new pseudonymous handle: student-<6 random hex chars>
    random_hex = uuid.uuid4().hex[:6]
    handle = f"student-{random_hex}"
    
    await users_coll.update_one(
        {"firebase_uid": firebase_uid},
        {
            "$setOnInsert": {
                "firebase_uid": firebase_uid,
                "handle": handle,
                "created_at": datetime.utcnow(),
            }
        },
        upsert=True,
    )
    return handle


async def enrich_resources(resources_list: list) -> List[ResourceResponse]:
    """Batched lookup to enrich resources with subject, topic, and uploader handle names."""
    if not resources_list:
        return []

    # Collect unique ObjectIds and UIDs
    subject_ids = set()
    topic_ids = set()
    uids = set()

    for r in resources_list:
        if r.get("subject"):
            subject_ids.add(r["subject"])
        if r.get("topic"):
            topic_ids.add(r["topic"])
        if r.get("firebase_uid"):
            uids.add(r["firebase_uid"])

    # Batch query subjects
    valid_subject_obj_ids = [ObjectId(s) for s in subject_ids if ObjectId.is_valid(s)]
    subjects_map = {}
    if valid_subject_obj_ids:
        subj_cursor = subjects_collection().find({"_id": {"$in": valid_subject_obj_ids}})
        async for s_doc in subj_cursor:
            subjects_map[str(s_doc["_id"])] = s_doc["name"]

    # Batch query topics
    valid_topic_obj_ids = [ObjectId(t) for t in topic_ids if ObjectId.is_valid(t)]
    topics_map = {}
    if valid_topic_obj_ids:
        top_cursor = topics_collection().find({"_id": {"$in": valid_topic_obj_ids}})
        async for t_doc in top_cursor:
            topics_map[str(t_doc["_id"])] = t_doc["name"]

    # Batch query users
    users_map = {}
    if uids:
        u_cursor = users_collection().find({"firebase_uid": {"$in": list(uids)}})
        async for u_doc in u_cursor:
            users_map[u_doc["firebase_uid"]] = u_doc.get("handle")

    result = []
    for r in resources_list:
        r_copy = dict(r)
        r_copy["id"] = str(r_copy["_id"])
        
        subj_id = r_copy.get("subject")
        r_copy["subject_name"] = subjects_map.get(subj_id, "Unknown")

        top_id = r_copy.get("topic")
        r_copy["topic_name"] = topics_map.get(top_id, "Unknown")

        uid = r_copy.get("firebase_uid")
        r_copy["uploader_handle"] = users_map.get(uid, f"student-{uid[:6]}" if uid else "student")

        result.append(ResourceResponse(**r_copy))

    return result


# --- Subject & Topic Endpoints ---

@app.get("/subjects/", response_model=List[SubjectResponse])
async def get_subjects():
    cursor = subjects_collection().find({})
    subjects = await cursor.to_list(length=None)
    return [SubjectResponse(id=str(s["_id"]), name=s["name"]) for s in subjects]


@app.post("/subjects/", response_model=SubjectResponse)
async def create_subject(subject: SubjectCreate):
    new_sub = await subjects_collection().insert_one(subject.model_dump())
    created = await subjects_collection().find_one({"_id": new_sub.inserted_id})
    return SubjectResponse(id=str(created["_id"]), name=created["name"])


@app.get("/subjects/{subject_id}/topics/", response_model=List[TopicResponse])
async def get_topics(subject_id: str):
    cursor = topics_collection().find({"subject": subject_id})
    topics = await cursor.to_list(length=None)
    return [TopicResponse(id=str(t["_id"]), name=t["name"], subject=t["subject"]) for t in topics]


@app.post("/topics/", response_model=TopicResponse)
async def create_topic(topic: TopicCreate):
    new_top = await topics_collection().insert_one(topic.model_dump())
    created = await topics_collection().find_one({"_id": new_top.inserted_id})
    return TopicResponse(id=str(created["_id"]), name=created["name"], subject=created["subject"])


# --- Presigned Upload & Resource Endpoints ---

@app.post("/uploads/init", response_model=UploadInitResponse)
async def upload_init(
    req: UploadInitRequest,
    firebase_uid: str = Depends(verify_firebase_token)
):
    """Initialize file upload by validating metadata and generating R2 presigned PUT URL."""
    try:
        if not storage.is_configured():
            raise HTTPException(
                status_code=503,
                detail="File storage (Cloudflare R2) is not configured yet. Uploads will be enabled soon."
            )

        # Validate size limit
        if req.size > MAX_FILE_SIZE:
            raise HTTPException(status_code=400, detail=f"File size exceeds maximum limit of 50MB")

        # Validate content type
        if req.content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=400,
                detail=f"Content-Type '{req.content_type}' not allowed. Must be PDF or PPT/PPTX."
            )

        # Per-user upload rate limit check (max 20 upload init calls in last 1 hour)
        one_hour_ago = datetime.utcnow() - timedelta(hours=1)
        recent_count = await resources_collection().count_documents({
            "firebase_uid": firebase_uid,
            "created_at": {"$gte": one_hour_ago}
        })
        if recent_count >= 20:
            raise HTTPException(status_code=429, detail="Upload rate limit exceeded. Please try again later.")

        # Deduplication check by SHA-256
        existing = await resources_collection().find_one({"sha256": req.sha256, "status": "published"})
        if existing:
            return UploadInitResponse(duplicate=True, resource_id=str(existing["_id"]))

        # Generate object key and presigned PUT URL
        key = f"resources/{firebase_uid}/{uuid.uuid4()}"
        upload_url = storage.presign_put(key, req.content_type)

        return UploadInitResponse(upload_url=upload_url, key=key)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Error in /uploads/init")
        raise HTTPException(status_code=500, detail="Failed to initialize upload")


@app.post("/uploads/complete", response_model=ResourceResponse)
async def upload_complete(
    req: UploadCompleteRequest,
    firebase_uid: str = Depends(verify_firebase_token)
):
    """Validate completed upload in R2, save metadata doc in MongoDB, and return resource."""
    try:
        if not storage.is_configured():
            raise HTTPException(
                status_code=503,
                detail="File storage (Cloudflare R2) is not configured yet. Uploads will be enabled soon."
            )

        # 1. Verify object exists in R2 and check size
        head = storage.head_object(req.key)
        if not head:
            raise HTTPException(status_code=400, detail="Uploaded file object not found in storage")

        actual_size = head.get("ContentLength", 0)
        if actual_size != req.size:
            storage.delete_object(req.key)
            raise HTTPException(
                status_code=400,
                detail=f"Uploaded file size ({actual_size} bytes) does not match expected size ({req.size} bytes)"
            )

        # 2. Magic-byte validation via small range GET
        header_bytes = storage.get_object_range(req.key, "bytes=0-7")
        if header_bytes:
            if req.content_type == "application/pdf" and not header_bytes.startswith(b"%PDF"):
                storage.delete_object(req.key)
                raise HTTPException(status_code=400, detail="File content does not match valid PDF signature")
            elif "presentation" in req.content_type or "powerpoint" in req.content_type:
                # PPTX (ZIP container starting with PK) or binary PPT (\xd0\xcf\x11\xe0)
                if not (header_bytes.startswith(b"PK") or header_bytes.startswith(b"\xd0\xcf\x11\xe0")):
                    storage.delete_object(req.key)
                    raise HTTPException(status_code=400, detail="File content does not match valid PPT/PPTX signature")

        # 3. Ensure user pseudonymous handle exists
        handle = await get_or_create_user_handle(firebase_uid)

        # 4. Insert resource metadata document
        resource_doc = {
            "title": req.title,
            "subject": req.subject,
            "topic": req.topic,
            "firebase_uid": firebase_uid,
            "storage_key": req.key,
            "file_name": req.file_name,
            "content_type": req.content_type,
            "size": req.size,
            "sha256": req.sha256,
            "likes": 0,
            "downloads": 0,
            "status": "published",
            "created_at": datetime.utcnow()
        }

        new_resource = await resources_collection().insert_one(resource_doc)
        created_doc = await resources_collection().find_one({"_id": new_resource.inserted_id})

        enriched = await enrich_resources([created_doc])
        return enriched[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Error in /uploads/complete")
        storage.delete_object(req.key)
        raise HTTPException(status_code=500, detail="Failed to complete upload")


@app.get("/resources/", response_model=List[ResourceResponse])
async def get_all_resources(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=50),
    subject: Optional[str] = Query(None, description="Filter by subject ObjectId string")
):
    """Get paginated community feed of resources, newest first."""
    query = {"status": "published"}
    if subject:
        query["subject"] = subject

    cursor = resources_collection().find(query).sort("created_at", -1).skip(skip).limit(limit)
    resources = await cursor.to_list(length=None)
    return await enrich_resources(resources)


@app.get("/resources/{resource_id}", response_model=ResourceResponse)
async def get_resource_by_id(resource_id: str):
    """Get single resource by ObjectId."""
    if not ObjectId.is_valid(resource_id):
        raise HTTPException(status_code=400, detail="Invalid resource ID format")
    doc = await resources_collection().find_one({"_id": ObjectId(resource_id), "status": "published"})
    if not doc:
        raise HTTPException(status_code=404, detail="Resource not found")
    enriched = await enrich_resources([doc])
    return enriched[0]


@app.post("/resources/{resource_id}/like", response_model=LikeResponse)
async def like_resource(resource_id: str):
    """Atomically increment like count for a resource."""
    if not ObjectId.is_valid(resource_id):
        raise HTTPException(status_code=400, detail="Invalid resource ID format")
    result = await resources_collection().find_one_and_update(
        {"_id": ObjectId(resource_id), "status": "published"},
        {"$inc": {"likes": 1}},
        return_document=ReturnDocument.AFTER,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Resource not found")
    return LikeResponse(resource_id=str(result["_id"]), likes=result.get("likes", 1))


@app.get("/resources/{resource_id}/download", response_model=DownloadResponse)
async def get_download_url(resource_id: str):
    """Generate a presigned R2 GET URL for downloading a resource and increment download count."""
    try:
        if not storage.is_configured():
            raise HTTPException(
                status_code=503,
                detail="File storage (Cloudflare R2) is not configured yet. Downloads will be enabled soon."
            )

        if not ObjectId.is_valid(resource_id):
            raise HTTPException(status_code=400, detail="Invalid resource ID format")

        resource = await resources_collection().find_one({"_id": ObjectId(resource_id)})
        if not resource:
            raise HTTPException(status_code=404, detail="Resource not found")

        storage_key = resource.get("storage_key")
        if not storage_key:
            raise HTTPException(status_code=404, detail="Resource storage key not found")

        filename = resource.get("file_name", "download.pdf")
        download_url = storage.presign_get(storage_key, filename=filename)

        # Atomically increment downloads counter
        await resources_collection().update_one(
            {"_id": ObjectId(resource_id)},
            {"$inc": {"downloads": 1}}
        )

        return DownloadResponse(download_url=download_url)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Error generating download URL")
        raise HTTPException(status_code=500, detail="Failed to generate download URL")


@app.get("/topics/{topic_id}/resources/", response_model=List[ResourceResponse])
async def get_resources_by_topic(topic_id: str):
    cursor = resources_collection().find({"topic": topic_id, "status": "published"}).sort("created_at", -1)
    resources = await cursor.to_list(length=None)
    return await enrich_resources(resources)


@app.get("/search/", response_model=List[ResourceResponse])
async def search_resources(
    q: Optional[str] = Query(None, description="Search query for title"),
    subject: Optional[str] = Query(None, description="Filter by subject ID"),
    topic: Optional[str] = Query(None, description="Filter by topic ID")
):
    query = {"status": "published"}
    if subject:
        query["subject"] = subject
    if topic:
        query["topic"] = topic
    if q:
        query["title"] = {"$regex": re.escape(q), "$options": "i"}

    cursor = resources_collection().find(query).sort("created_at", -1)
    resources = await cursor.to_list(length=None)
    return await enrich_resources(resources)


@app.get("/user/resources/", response_model=List[ResourceResponse])
async def get_user_resources(
    firebase_uid: str = Depends(verify_firebase_token)
):
    cursor = resources_collection().find({"firebase_uid": firebase_uid}).sort("created_at", -1)
    resources = await cursor.to_list(length=None)
    return await enrich_resources(resources)


# -----------------------------------------------------------------------------
# Render Free Tier Cold Start Keep-Alive Note:
# Render spins down free-tier web services after 15 minutes of inactivity.
# The subsequent request takes ~30-50 seconds to complete (cold start).
# To keep the instance warm, configure a free external ping monitor (e.g.,
# cron-job.org, UptimeRobot, or BetterUptime) to send an HTTP GET request to:
#   GET https://<your-render-app-name>.onrender.com/health
# at an interval of every 10 to 14 minutes.
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)

