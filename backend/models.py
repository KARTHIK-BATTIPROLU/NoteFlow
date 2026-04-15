from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ResourceCreate(BaseModel):
    title: str
    subject: str
    topic: str
    file_url: str
    file_type: str
    uploaded_by: str


class ResourceResponse(ResourceCreate):
    id: str
    uploaded_at: datetime


class SubjectCreate(BaseModel):
    name: str


class SubjectResponse(SubjectCreate):
    id: str


class TopicCreate(BaseModel):
    name: str
    subject: str


class TopicResponse(TopicCreate):
    id: str
