import os
import sys
import unittest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

# Set up test environment variables
os.environ["MONGODB_URL"] = "mongodb://localhost:27017/"
os.environ["R2_ACCOUNT_ID"] = "test-account"
os.environ["R2_ENDPOINT"] = "https://test.r2.cloudflarestorage.com"
os.environ["R2_ACCESS_KEY_ID"] = "test-key"
os.environ["R2_SECRET_ACCESS_KEY"] = "test-secret"
os.environ["R2_BUCKET"] = "test-bucket"

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import main
import storage

class TestNoteFlowApiIntegration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client_cm = TestClient(main.app)
        cls.client = cls.client_cm.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.client_cm.__exit__(None, None, None)

    def test_00_health_endpoint(self):
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["db"], "connected")

    def test_01_root_endpoint(self):
        resp = self.client.get("/")
        self.assertEqual(resp.status_code, 200)
        self.assertIn("message", resp.json())

    def test_02_get_subjects_and_topics(self):
        resp = self.client.get("/subjects/")
        self.assertEqual(resp.status_code, 200)
        subjects = resp.json()
        self.assertIsInstance(subjects, list)
        self.assertGreater(len(subjects), 0)

        # Pick first subject and fetch its topics
        subject_id = subjects[0]["id"]
        topic_resp = self.client.get(f"/subjects/{subject_id}/topics/")
        self.assertEqual(topic_resp.status_code, 200)
        self.assertIsInstance(topic_resp.json(), list)

    def test_03_create_subject_and_topic(self):
        # Create a new subject
        subj_name = f"Test Engineering {os.urandom(3).hex()}"
        res_subj = self.client.post("/subjects/", json={"name": subj_name})
        self.assertEqual(res_subj.status_code, 200)
        created_subj = res_subj.json()
        self.assertEqual(created_subj["name"], subj_name)
        subj_id = created_subj["id"]

        # Create topic for this subject
        topic_name = "Algorithms & Complexity"
        res_topic = self.client.post("/topics/", json={"name": topic_name, "subject": subj_id})
        self.assertEqual(res_topic.status_code, 200)
        created_topic = res_topic.json()
        self.assertEqual(created_topic["name"], topic_name)
        self.assertEqual(created_topic["subject"], subj_id)

    def test_04_community_feed_pagination(self):
        resp = self.client.get("/resources/?skip=0&limit=5")
        self.assertEqual(resp.status_code, 200)
        self.assertIsInstance(resp.json(), list)

    def test_05_search_resources(self):
        resp = self.client.get("/search/?q=math")
        self.assertEqual(resp.status_code, 200)
        self.assertIsInstance(resp.json(), list)

    def test_06_unauthenticated_protected_routes(self):
        # Without Bearer header, protected endpoints must reject
        resp_init = self.client.post("/uploads/init", json={
            "title": "Unauthorized Test",
            "subject": "69dfe16f79312d6b02504d74",
            "topic": "69dfe16f79312d6b02504d77",
            "file_name": "test.pdf",
            "content_type": "application/pdf",
            "size": 1024,
            "sha256": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
        })
        self.assertIn(resp_init.status_code, [401, 403, 422])

        resp_user = self.client.get("/user/resources/")
        self.assertIn(resp_user.status_code, [401, 403, 422])

    @patch("storage.presign_put", return_value="https://test.r2.cloudflarestorage.com/upload-put-url")
    def test_07_authenticated_upload_init(self, mock_presign):
        main.app.dependency_overrides[main.verify_firebase_token] = lambda: "test_integration_uid_456"
        try:
            resp = self.client.post("/uploads/init", json={
                "title": "Authenticated Notes",
                "subject": "69dfe16f79312d6b02504d74",
                "topic": "69dfe16f79312d6b02504d77",
                "file_name": "test_notes.pdf",
                "content_type": "application/pdf",
                "size": 4096,
                "sha256": "aabbcc1234567890aabbcc1234567890aabbcc1234567890aabbcc1234567890"
            }, headers={"Authorization": "Bearer valid_test_token"})
            self.assertEqual(resp.status_code, 200)
            data = resp.json()
            self.assertIn("upload_url", data)
            self.assertIn("key", data)
            self.assertEqual(data["upload_url"], "https://test.r2.cloudflarestorage.com/upload-put-url")
        finally:
            main.app.dependency_overrides.pop(main.verify_firebase_token, None)

    def test_08_invalid_download_resource_id(self):
        resp = self.client.get("/resources/not-a-valid-object-id/download")
        self.assertEqual(resp.status_code, 400)
        self.assertIn("Invalid resource ID format", resp.json()["detail"])

    def test_09_invalid_get_resource_id(self):
        resp = self.client.get("/resources/invalid-object-id")
        self.assertEqual(resp.status_code, 400)
        self.assertIn("Invalid resource ID format", resp.json()["detail"])

    def test_10_invalid_like_resource_id(self):
        resp = self.client.post("/resources/invalid-object-id/like")
        self.assertEqual(resp.status_code, 400)
        self.assertIn("Invalid resource ID format", resp.json()["detail"])

if __name__ == "__main__":
    unittest.main()
