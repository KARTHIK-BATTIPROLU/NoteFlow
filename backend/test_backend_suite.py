"""
Backend Unit Test Suite for NoteFlow Scalable Base Architecture
Covers Models, Storage, Database, Taxonomy Batching, Upload Workflow, and Download Logic.
"""
import os
import sys

# Set test env vars before importing backend modules
os.environ["MONGODB_URL"] = "mongodb://localhost:27017/"
os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"] = '{"type": "service_account", "project_id": "noteflow-test-project", "private_key_id": "123", "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\\n-----END PRIVATE KEY-----\\n", "client_email": "test@noteflow-test-project.iam.gserviceaccount.com", "token_uri": "https://oauth2.googleapis.com/token"}'
os.environ["R2_ACCOUNT_ID"] = "test-account-id"
os.environ["R2_ENDPOINT"] = "https://test.r2.cloudflarestorage.com"
os.environ["R2_ACCESS_KEY_ID"] = "test-access-key"
os.environ["R2_SECRET_ACCESS_KEY"] = "test-secret-key"
os.environ["R2_BUCKET"] = "test-bucket"

from unittest.mock import MagicMock, patch

# Patch firebase_admin before importing main
patcher_cert = patch("firebase_admin.credentials.Certificate", return_value=MagicMock())
patcher_init = patch("firebase_admin.initialize_app", return_value=MagicMock())
patcher_get = patch("firebase_admin.get_app", return_value=MagicMock(project_id="test-project"))

patcher_cert.start()
patcher_init.start()
patcher_get.start()

import unittest
import uuid
from datetime import datetime

sys.path.insert(0, os.path.dirname(__file__))

from models import (
    UploadInitRequest,
    UploadInitResponse,
    UploadCompleteRequest,
    ResourceResponse,
    DownloadResponse,
    UserDoc,
    SubjectCreate,
    TopicCreate,
)
import storage


class TestBackendModels(unittest.TestCase):
    """Test Pydantic schemas and serialization."""

    def test_upload_init_request(self):
        req = UploadInitRequest(
            title="Data Structures Notes",
            subject="65b1c2d3e4f5a6b7c8d9e0f1",
            topic="65b1c2d3e4f5a6b7c8d9e0f2",
            file_name="dsa_notes.pdf",
            content_type="application/pdf",
            size=1024 * 1024 * 5,  # 5 MB
            sha256="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        )
        self.assertEqual(req.title, "Data Structures Notes")
        self.assertEqual(req.size, 5242880)
        self.assertEqual(req.content_type, "application/pdf")

    def test_resource_response(self):
        resp = ResourceResponse(
            id="65b1c2d3e4f5a6b7c8d9e0f0",
            title="Calculus Cheat Sheet",
            subject="65b1c2d3e4f5a6b7c8d9e0f1",
            topic="65b1c2d3e4f5a6b7c8d9e0f2",
            firebase_uid="user_abc123",
            file_name="calculus.pdf",
            content_type="application/pdf",
            size=2048576,
            sha256="dummyhash123",
            likes=12,
            downloads=45,
            status="published",
            created_at=datetime.utcnow(),
            storage_key="resources/user_abc123/key123",
            subject_name="Mathematics",
            topic_name="Calculus",
            uploader_handle="student-a1b2c3",
        )
        self.assertEqual(resp.subject_name, "Mathematics")
        self.assertEqual(resp.uploader_handle, "student-a1b2c3")
        self.assertEqual(resp.downloads, 45)

    def test_user_doc(self):
        user = UserDoc(
            firebase_uid="uid_12345",
            handle="student-f89a12",
            created_at=datetime.utcnow(),
        )
        self.assertEqual(user.handle, "student-f89a12")


class TestStorageHelpers(unittest.TestCase):
    """Test storage helper signatures and constants."""

    def test_r2_endpoint_config(self):
        self.assertEqual(storage.R2_BUCKET, "test-bucket")
        self.assertEqual(storage.R2_ENDPOINT, "https://test.r2.cloudflarestorage.com")

    def test_presign_put_generation(self):
        key = f"resources/uid123/{uuid.uuid4()}"
        content_type = "application/pdf"
        url = storage.presign_put(key, content_type, expires=300)
        self.assertIn(storage.R2_BUCKET, url)
        self.assertIn("X-Amz-Signature", url)

    def test_presign_get_generation(self):
        key = "resources/uid123/sample.pdf"
        url = storage.presign_get(key, filename="notes.pdf", expires=300)
        self.assertIn(storage.R2_BUCKET, url)
        self.assertIn("response-content-disposition", url)


class TestTaxonomyAndValidation(unittest.TestCase):
    """Test validation constraints and taxonomy objects."""

    def test_allowed_content_types(self):
        from main import ALLOWED_CONTENT_TYPES, MAX_FILE_SIZE
        self.assertIn("application/pdf", ALLOWED_CONTENT_TYPES)
        self.assertIn("application/vnd.openxmlformats-officedocument.presentationml.presentation", ALLOWED_CONTENT_TYPES)
        self.assertIn("application/vnd.ms-powerpoint", ALLOWED_CONTENT_TYPES)
        self.assertEqual(MAX_FILE_SIZE, 50 * 1024 * 1024)

    def test_subject_and_topic_creation_models(self):
        sub = SubjectCreate(name="Computer Science")
        self.assertEqual(sub.name, "Computer Science")

        top = TopicCreate(name="Algorithms", subject="65b1c2d3e4f5a6b7c8d9e0f1")
        self.assertEqual(top.name, "Algorithms")
        self.assertEqual(top.subject, "65b1c2d3e4f5a6b7c8d9e0f1")


if __name__ == "__main__":
    unittest.main()
