from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ResourceCreate(BaseModel):
    title: str
    subject: str
    topic: str
    firebase_uid: str
    storage_key: str
    file_name: str
    content_type: str
    size: int
    sha256: str
    likes: int = 0
    downloads: int = 0
    status: str = "published"
    created_at: Optional[datetime] = None


class ResourceResponse(BaseModel):
    id: str
    title: str
    subject: str
    topic: str
    firebase_uid: str
    file_name: str
    content_type: str
    size: int
    sha256: Optional[str] = None
    likes: int = 0
    downloads: int = 0
    status: str = "published"
    created_at: Optional[datetime] = None
    storage_key: Optional[str] = None
    file_id: Optional[str] = None  # Legacy compatibility if any
    subject_name: Optional[str] = None
    topic_name: Optional[str] = None
    uploader_handle: Optional[str] = None


class UploadInitRequest(BaseModel):
    title: str
    subject: str
    topic: str
    file_name: str
    content_type: str
    size: int
    sha256: str


class UploadInitResponse(BaseModel):
    upload_url: Optional[str] = None
    key: Optional[str] = None
    duplicate: bool = False
    resource_id: Optional[str] = None


class UploadCompleteRequest(BaseModel):
    key: str
    title: str
    subject: str
    topic: str
    file_name: str
    content_type: str
    size: int
    sha256: str


class DownloadResponse(BaseModel):
    download_url: str


class LikeResponse(BaseModel):
    resource_id: str
    likes: int


class UserDoc(BaseModel):
    firebase_uid: str
    handle: str
    created_at: datetime


class SubjectCreate(BaseModel):
    name: str


class SubjectResponse(SubjectCreate):
    id: str


class TopicCreate(BaseModel):
    name: str
    subject: str


class TopicResponse(TopicCreate):
    id: str
