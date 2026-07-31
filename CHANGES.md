# NoteFlow Scalable Base Changes (`feat/base-scalable`)

This release fixes the core taxonomy disconnect between the Flutter client and FastAPI backend, migrates binary storage from MongoDB GridFS to Cloudflare R2 object storage with short-lived presigned URLs, converts Explore tab into a real paginated community feed, adds pseudonymous uploader attribution, enforces security standards, and cleans up dead legacy code.

---

## 1. Summary of Changes per File

### Backend (`backend/`)
- **[storage.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/storage.py)** (NEW): Boto3 Cloudflare R2 client. Exposes helpers for presigned PUT (`presign_put`), presigned GET (`presign_get`), `head_object`, `delete_object`, and header range validation (`get_object_range`).
- **[migrate_gridfs_to_r2.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/migrate_gridfs_to_r2.py)** (NEW): One-time migration utility to transfer legacy GridFS files into Cloudflare R2 and update resource metadata documents.
- **[database.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/database.py)**: Added startup environment variable validation (failing loud if missing), added `users` collection accessor, removed legacy GridFS bucket initialization.
- **[models.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/models.py)**: Updated Pydantic schemas (`UploadInitRequest`, `UploadInitResponse`, `UploadCompleteRequest`, `ResourceResponse`, `DownloadResponse`, `UserDoc`).
- **[main.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/main.py)**:
  - Startup check for required environment variables.
  - Initialized collection indexes for `created_at`, `sha256`, `firebase_uid`, `subject`, and unique `users.firebase_uid`.
  - Implemented `enrich_resources` helper with **batched lookups** for subjects, topics, and user handles.
  - Added `POST /uploads/init` (50MB size limit, content-type allowlist check, SHA-256 deduplication, rate limit check, presigned PUT URL generation).
  - Added `POST /uploads/complete` (R2 head verification, PDF/PPTX magic-byte validation, pseudonymous handle upsert `student-<6 chars>`, document insert).
  - Added `GET /resources/` (paginated `skip`/`limit`, optional `subject` filter, newest first).
  - Added `GET /resources/{id}/download` (presigned GET URL with disposition header, atomic `$inc` downloads counter).
  - Removed legacy GridFS upload/download endpoints (`POST /upload` and `GET /file/{file_id}`).
  - Replaced exception string leakage with logging and generic HTTP 500/400 errors.
- **[init_db.py](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/init_db.py)**: Seed taxonomy using subject MongoDB ObjectId strings for topics. Idempotent seed script.
- **[requirements.txt](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/backend/requirements.txt)**: Added `boto3==1.34.44`.

### Flutter Client (`lib/`)
- **[pubspec.yaml](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/pubspec.yaml)**: Added `crypto: ^3.0.3` dependency for SHA-256 calculation.
- **[lib/core/models/resource.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/core/models/resource.dart)**: Added `storageKey`, `sha256`, and `uploaderHandle`. Removed legacy Firestore timestamp parsing and unused fields.
- **[lib/core/services/api_service.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/core/services/api_service.dart)**:
  - Implemented 3-step upload: compute SHA-256 -> `POST /uploads/init` -> direct HTTP PUT to Cloudflare R2 presigned URL -> `POST /uploads/complete`.
  - Implemented R2 presigned GET download flow in `downloadFile(resourceId)`.
  - Added `getCommunityResources({skip, limit, subjectId})` with pagination.
  - Removed dead debug & firewall workaround strings.
- **[lib/features/upload/presentation/screens/upload_screen.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/upload/presentation/screens/upload_screen.dart)**:
  - Removed static `_predefinedSubjects` and `_predefinedTopics` slug lists.
  - Dynamically populated Subject and Topic dropdowns from backend providers (`subjectsProvider` & `topicsProvider`).
  - Submitted real MongoDB ObjectId strings on upload.
- **[lib/features/upload/presentation/providers/upload_provider.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/upload/presentation/providers/upload_provider.dart)**:
  - Matched client limit to backend `MAX_FILE_SIZE` (50 MB).
  - Streamed/read files from disk on mobile/desktop without buffering into RAM twice.
- **[lib/features/home/presentation/providers/search_provider.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/home/presentation/providers/search_provider.dart)**:
  - Added `communityFeedProvider` with pagination state, infinite scroll support, and server-side subject filtering.
- **[lib/features/home/presentation/screens/home_screen.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/home/presentation/screens/home_screen.dart)**:
  - Explore tab converted to a paginated community feed of all uploaded resources, newest first.
  - Added infinite scroll scroll listener and pull-to-refresh.
- **[lib/features/profile/presentation/screens/profile_screen.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/profile/presentation/screens/profile_screen.dart)**:
  - Updated user stats provider to use `userResourcesProvider`.
- **[lib/core/widgets/resource_card.dart](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/core/widgets/resource_card.dart)**:
  - Displayed `uploaderHandle` (e.g. `student-a1b2c3`) on resource cards.
- **[lib/features/upload/data/models/](file:///c:/Users/Karthik/OneDrive/Desktop/NoteFlow/lib/features/upload/data/models/)** (DELETED): Removed dead legacy Firestore model barrel and files.

---

## 2. Required Environment Variables

Set these environment variables in your deployment environment (e.g., Render / local `.env`):

| Variable Name | Description | Example / Note |
|---|---|---|
| `MONGODB_URL` | MongoDB connection URI | `mongodb+srv://user:pass@cluster.mongodb.net/noteflow` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Service Account JSON string | `{ "type": "service_account", ... }` |
| `R2_ACCOUNT_ID` | Cloudflare Account ID | `a1b2c3d4e5f6...` |
| `R2_ENDPOINT` | Cloudflare R2 S3 API Endpoint | `https://<account_id>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | R2 API Token Access Key ID | `abc123xyz...` |
| `R2_SECRET_ACCESS_KEY` | R2 API Token Secret Access Key | `secret123...` |
| `R2_BUCKET` | R2 Storage Bucket Name | `noteflow-resources` |

---

## 3. Manual Step-by-Step Operator Setup

1. **Cloudflare R2 Bucket & API Token**:
   - Log into Cloudflare Dashboard -> **R2 Object Storage**.
   - Create a new bucket named `noteflow-resources`.
   - Go to **Manage R2 API Tokens** -> Create API Token with **Edit** (Read & Write) permissions for `noteflow-resources`.
   - Copy the `Account ID`, `Access Key ID`, and `Secret Access Key`.

2. **Configure Environment Variables**:
   - In Render (or backend hosting platform), set `MONGODB_URL`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `R2_ACCOUNT_ID`, `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and `R2_BUCKET`.

3. **Rotate Leaked MongoDB Atlas Credentials**:
   - Log into MongoDB Atlas -> **Database Access**.
   - Rotate or reset password for any database user credentials previously committed in legacy `.env` files.

4. **Seed Database Taxonomy**:
   - Run `python backend/init_db.py` to seed subjects and topics with real ObjectIds and create indexes.

5. **(Optional) Migrate Existing GridFS Files**:
   - If legacy GridFS uploads exist, run `python backend/migrate_gridfs_to_r2.py` to transfer them to R2.

---

## 4. Deliberately Skipped Out-of-Scope Items

- Resumable/tus multipart uploads (single presigned PUT URL is used for files <= 50MB).
- Dedicated search engine like Algolia/Elasticsearch (MongoDB regex search retained).
- PDF thumbnail generation.
- Reputation/ratings/reviews system.
- Database migration away from MongoDB.
