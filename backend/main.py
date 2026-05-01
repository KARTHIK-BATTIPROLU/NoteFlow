from fastapi import FastAPI, HTTPException, Depends, Query, UploadFile, File, Form, Header
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from bson import ObjectId
from datetime import datetime
import re
import math
import firebase_admin
from firebase_admin import credentials, auth

from database import connect_to_mongo, close_mongo_connection, subjects as subjects_collection, topics as topics_collection, resources as resources_collection, get_database, get_gridfs
from models import SubjectResponse, SubjectCreate, TopicResponse, TopicCreate, ResourceResponse, ResourceCreate

# Initialize Firebase Admin (modify with your service account path if needed)
try:
    firebase_admin.initialize_app()
except ValueError:
    pass # Already initialized

app = FastAPI(title="NoteFlow API", version="1.0.0")

# CORS middleware for allowing frontend to talk to the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()
    # Initialize collections with indexes
    await initialize_collections()

@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

@app.get("/")
async def root():
    return {"message": "Welcome to NoteFlow API"}

async def initialize_collections():
    """Initialize MongoDB collections with indexes"""
    db = get_database()
    
    # Create collections if they don't exist
    existing_collections = await db.list_collection_names()
    
    if "subjects" not in existing_collections:
        await db.create_collection("subjects")
        print("Created 'subjects' collection")
    
    if "topics" not in existing_collections:
        await db.create_collection("topics")
        print("Created 'topics' collection")
    
    if "resources" not in existing_collections:
        await db.create_collection("resources")
        print("Created 'resources' collection")
    
    # Create indexes for better search performance
    subjects_coll = subjects_collection()
    await subjects_coll.create_index("name")
    
    topics_coll = topics_collection()
    await topics_coll.create_index([("name", 1), ("subject", 1)])
    
    resources_coll = resources_collection()
    await resources_coll.create_index([("title", 1), ("subject", 1), ("topic", 1)])
    await resources_coll.create_index("uploaded_at")
    
    print("Collections and indexes initialized successfully")

@app.get("/subjects/", response_model=List[SubjectResponse])
async def get_subjects():
    collection = subjects_collection()
    subjects_cursor = collection.find({})
    subjects = await subjects_cursor.to_list(length=None)
    
    # Map _id to id for response
    result = []
    for s in subjects:
        s['id'] = str(s['_id'])
        result.append(SubjectResponse(**s))
    return result

@app.post("/subjects/", response_model=SubjectResponse)
async def create_subject(subject: SubjectCreate):
    collection = subjects_collection()
    subject_dict = subject.model_dump()
    new_subject = await collection.insert_one(subject_dict)
    
    created_subject = await collection.find_one({"_id": new_subject.inserted_id})
    created_subject['id'] = str(created_subject['_id'])
    return SubjectResponse(**created_subject)

@app.get("/subjects/{subject_id}/topics/", response_model=List[TopicResponse])
async def get_topics(subject_id: str):
    collection = topics_collection()
    topics_cursor = collection.find({"subject": subject_id})
    topics = await topics_cursor.to_list(length=None)
    
    result = []
    for t in topics:
        t['id'] = str(t['_id'])
        result.append(TopicResponse(**t))
    return result

@app.post("/topics/", response_model=TopicResponse)
async def create_topic(topic: TopicCreate):
    collection = topics_collection()
    topic_dict = topic.model_dump()
    new_topic = await collection.insert_one(topic_dict)
    
    created_topic = await collection.find_one({"_id": new_topic.inserted_id})
    created_topic['id'] = str(created_topic['_id'])
    return TopicResponse(**created_topic)

@app.get("/topics/{topic_id}/resources/", response_model=List[ResourceResponse])
async def get_resources_by_topic(topic_id: str):
    collection = resources_collection()
    resources_cursor = collection.find({"topic": topic_id})
    resources = await resources_cursor.to_list(length=None)
    
    result = []
    for r in resources:
        r['id'] = str(r['_id'])
        result.append(ResourceResponse(**r))
    return result

@app.get("/resources/", response_model=List[ResourceResponse])
async def get_all_resources():
    collection = resources_collection()
    resources_cursor = collection.find({})
    resources = await resources_cursor.to_list(length=None)

    result = []
    for r in resources:
        r['id'] = str(r['_id'])
        result.append(ResourceResponse(**r))
    return result

# Deprecated: use POST /upload instead
# @app.post("/resources/", response_model=ResourceResponse)
# async def create_resource(resource: ResourceCreate):
#     collection = resources_collection()
#     resource_dict = resource.model_dump()
#     resource_dict["uploaded_at"] = datetime.utcnow()
#     
#     new_resource = await collection.insert_one(resource_dict)
#     created_resource = await collection.find_one({"_id": new_resource.inserted_id})
#     created_resource['id'] = str(created_resource['_id'])
#     return ResourceResponse(**created_resource)

async def verify_firebase_token(authorization: str = Header(...)):
    """Verifies Firebase token - optionally bypass in dev if needed"""
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid auth scheme")
        
        # In a real production setup, this will check token against Firebase Servers
        # For local dev without creds configured, we'll try to decode, 
        # but you should configure firebase_admin securely.
        try:
            decoded_token = auth.verify_id_token(token)
            return decoded_token['uid']
        except Exception as e:
            # Fallback for dev mode - remove in pure production!
            print(f"Token verification fail: {str(e)} - using raw token as UID for dev.")
            return token
            
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Unauthorized: {str(e)}")

@app.post("/upload", response_model=ResourceResponse)
async def upload_resource(
    title: str = Form(...),
    subject: str = Form(...),
    topic: str = Form(...),
    file: UploadFile = File(...),
    firebase_uid: str = Depends(verify_firebase_token)
):
    """
    Handle direct chunked file upload to GridFS 
    & store metadata to MongoDB.
    """
    try:
        # Sanitize filename and validate size if necessary
        MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB
        file_name = file.filename
        content_type = file.content_type
        
        # Connect to GridFS
        fs = get_gridfs()
        
        # Upload chunk by chunk string to GridFS
        grid_in = fs.open_upload_stream(
            file_name,
            metadata={"contentType": content_type, "firebase_uid": firebase_uid}
        )
        
        # Chunk read manually or read entire file (careful with memory)
        content = await file.read()
        
        if len(content) > MAX_FILE_SIZE:
             raise HTTPException(status_code=413, detail="File too large")
             
        await grid_in.write(content)
        await grid_in.close()
        
        file_id = str(grid_in._id)
        
        # Save Metadata to resources collection
        collection = resources_collection()
        
        resource_data = {
            "title": title,
            "subject": subject,
            "topic": topic,
            "firebase_uid": firebase_uid,
            "file_id": file_id,
            "file_name": file_name,
            "content_type": content_type,
            "size": len(content),
            "likes": 0,
            "downloads": 0,
            "created_at": datetime.utcnow()
        }
        
        new_resource = await collection.insert_one(resource_data)
        
        # Prepare response
        created_resource = await collection.find_one({"_id": new_resource.inserted_id})
        created_resource['id'] = str(created_resource['_id'])
        
        # Extract names if they are object ids
        try:
            subject_doc = await subjects_collection().find_one({"_id": ObjectId(subject)})
            created_resource['subject_name'] = subject_doc["name"] if subject_doc else None
                
            topic_doc = await topics_collection().find_one({"_id": ObjectId(topic)})
            created_resource['topic_name'] = topic_doc["name"] if topic_doc else None
        except:
             pass

        return ResourceResponse(**created_resource)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/file/{file_id}")
async def download_file(file_id: str):
    """
    Stream file back to client directly from GridFS chunks.
    """
    try:
        from motor.motor_asyncio import AsyncIOMotorGridFSBucket
        fs: AsyncIOMotorGridFSBucket = get_gridfs()
        
        try:
            object_id = ObjectId(file_id)
        except:
            raise HTTPException(status_code=400, detail="Invalid GridFS Object ID")
            
        file_doc = await fs.open_download_stream(object_id)
        
        if not file_doc:
            raise HTTPException(status_code=404, detail="File not found")
            
        metadata = file_doc.metadata or {}
        content_type = metadata.get("contentType", "application/octet-stream")
        
        async def file_stream():
            while True:
                chunk = await file_doc.readchunk()
                if not chunk:
                    break
                yield chunk
                
        return StreamingResponse(
            file_stream(),
            media_type=content_type,
            headers={
                "Content-Disposition": f'inline; filename="{file_doc.filename}"'
            }
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/search/", response_model=List[ResourceResponse])
async def search_resources(
    q: Optional[str] = Query(None, description="Search query for title, subject, or topic"),
    subject: Optional[str] = Query(None, description="Filter by subject ID"),
    topic: Optional[str] = Query(None, description="Filter by topic ID")
):
    """
    Search resources with optional filters
    - q: Search in title (case-insensitive)
    - subject: Filter by subject ID
    - topic: Filter by topic ID
    """
    collection = resources_collection()
    subjects_coll = subjects_collection()
    topics_coll = topics_collection()
    
    # Build query
    query = {}
    
    if subject:
        query["subject"] = subject
    
    if topic:
        query["topic"] = topic
    
    if q:
        # Case-insensitive search in title
        query["title"] = {"$regex": re.escape(q), "$options": "i"}
    
    resources_cursor = collection.find(query).sort("uploaded_at", -1)
    resources = await resources_cursor.to_list(length=None)
    
    # Enrich resources with subject and topic names
    result = []
    for r in resources:
        # Get subject name
        subject_name = "Unknown"
        topic_name = "Unknown"
        
        try:
            if r.get("subject"):
                subject_doc = await subjects_coll.find_one({"_id": ObjectId(r["subject"])})
                if subject_doc: subject_name = subject_doc["name"]
        except: pass
        
        try:
            if r.get("topic"):
                topic_doc = await topics_coll.find_one({"_id": ObjectId(r["topic"])})
                if topic_doc: topic_name = topic_doc["name"]
        except: pass
        
        r['id'] = str(r['_id'])
        r['subject_name'] = subject_name
        r['topic_name'] = topic_name
        result.append(ResourceResponse(**r))
    
    return result
