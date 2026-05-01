from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ResourceCreate(BaseModel):
    title: str
    subject: str
    topic: str
    firebase_uid: str
    file_id: str
    file_name: str
    content_type: str
    size: int
    likes: int = 0
    downloads: int = 0
    created_at: datetime = None

class ResourceResponse(ResourceCreate):
    id: str
    subject_name: Optional[str] = None
    topic_name: Optional[str] = None


class SubjectCreate(BaseModel):
    name: str


class SubjectResponse(SubjectCreate):
    id: str


class TopicCreate(BaseModel):
    name: str
    subject: str


class TopicResponse(TopicCreate):
    id: str
