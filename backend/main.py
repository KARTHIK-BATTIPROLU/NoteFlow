from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from bson import ObjectId
from datetime import datetime

from database import connect_to_mongo, close_mongo_connection, subjects as subjects_collection, topics as topics_collection, resources as resources_collection
from models import SubjectResponse, SubjectCreate, TopicResponse, TopicCreate, ResourceResponse, ResourceCreate

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
    connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_db_client():
    close_mongo_connection()

@app.get("/")
async def root():
    return {"message": "Welcome to NoteFlow API"}

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

@app.post("/resources/", response_model=ResourceResponse)
async def create_resource(resource: ResourceCreate):
    collection = resources_collection()
    resource_dict = resource.model_dump()
    resource_dict["uploaded_at"] = datetime.utcnow()
    
    new_resource = await collection.insert_one(resource_dict)
    created_resource = await collection.find_one({"_id": new_resource.inserted_id})
    created_resource['id'] = str(created_resource['_id'])
    return ResourceResponse(**created_resource)
