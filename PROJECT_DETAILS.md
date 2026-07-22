# PROJECT_DETAILS.md

A factual inventory of this repository. Every fact cites a file path (and line where useful). Items deduced from usage are marked `(inferred)`. Items not determinable from the code are marked `Not found in code`.

---

## 1. Identity

- **Name:** `noteflow` (from [pubspec.yaml](pubspec.yaml#L1); FastAPI title `"NoteFlow API"` in [backend/main.py:21](backend/main.py#L21)).
- **One-line purpose (from README):** "A comprehensive Flutter application with FastAPI backend for managing and sharing educational resources (PDFs, presentations) with MongoDB integration." ([README.md:3](README.md#L3)).
- **License:** "This project is for educational purposes." — no SPDX license / LICENSE file present ([README.md:331](README.md#L331)). No `LICENSE` file tracked.
- **Repo size:** 237 tracked files, ~8.0 MB total of tracked content (`git ls-files`).
- **Primary languages:** Dart (Flutter app, ~40 `.dart` files under `lib/`, 6909 lines), Python (FastAPI backend, 724 lines across `backend/`). Also Kotlin (Android host), Swift (iOS/macOS hosts), C++ (Windows/Linux hosts) — all Flutter-generated platform scaffolding.
- **pubspec version:** `0.1.0` ([pubspec.yaml:4](pubspec.yaml#L4)). App version shown in UI as `v1.0.0` ([lib/features/profile/presentation/screens/profile_screen.dart:681](lib/features/profile/presentation/screens/profile_screen.dart#L681)).
- **47 Markdown files** are tracked at the repo root (status/fix logs — see §2).

---

## 2. Repo structure

```
NoteFlow/
├── pubspec.yaml                 # Flutter package manifest & dependencies
├── pubspec.lock                 # Pinned dependency versions
├── analysis_options.yaml        # Dart lint config (includes flutter_lints)
├── firebase.json                # FlutterFire platform config (project noteflow-auth-project)
├── README.md                    # Project overview, setup, API list
├── logo.png / assets/images/logo.png  # App logo (splash + launcher icon source)
│
├── backend/                     # Python FastAPI backend
│   ├── main.py                  # All API endpoints, Firebase token verify, GridFS upload/download
│   ├── models.py                # Pydantic models (Subject/Topic/Resource Create+Response)
│   ├── database.py              # Motor (async Mongo) client + GridFS bucket setup; hardcoded Atlas URI
│   ├── init_db.py               # Standalone DB init: creates collections, indexes, sample data
│   ├── check_mongodb.py         # Standalone script: prints resource counts from local Mongo
│   ├── fix_uploaded_files.py    # Standalone migration: converts JWT-token firebase_uid fields to UID
│   ├── test_upload.py           # Standalone script: pings backend + local Mongo (not a unit test)
│   ├── requirements.txt         # Python deps (firebase-admin line is space-mangled — see §3)
│   ├── start.sh / start.bat     # Startup scripts (install deps, init db, run uvicorn)
│   ├── SETUP.md                 # Backend setup guide
│   └── .env                     # MONGODB_URL with live MongoDB Atlas credentials (TRACKED)
│
├── lib/                         # Flutter application source
│   ├── main.dart                # App entry: init Hive, init Firebase, ProviderScope, MaterialApp.router
│   ├── firebase_options.dart    # FlutterFire-generated Firebase config (API keys for all platforms)
│   ├── core/
│   │   ├── database/local_db.dart        # Hive 'downloads' box helpers
│   │   ├── models/                       # Subject, Topic, Resource models (API-facing)
│   │   ├── router/app_router.dart        # GoRouter config + auth redirect + page transitions
│   │   ├── services/
│   │   │   ├── api_service.dart           # HTTP client to backend (subjects/topics/resources/search/upload/file)
│   │   │   ├── api_provider.dart          # Riverpod provider for ApiService
│   │   │   └── theme_service.dart         # Hive-backed theme persistence + ThemeMode notifier
│   │   ├── theme/app_theme.dart          # Colors, text styles (Google Fonts Inter), light/dark themes
│   │   ├── utils/toast.dart              # SnackBar helper
│   │   └── widgets/                      # ResourceCard, SubjectChip, EmptyState, LoadingSkeleton
│   └── features/
│       ├── auth/
│       │   ├── data/auth_repository.dart          # FirebaseAuth wrapper (sign in/up/out, getIdToken)
│       │   └── presentation/
│       │       ├── providers/auth_provider.dart   # authState stream + AuthController
│       │       └── screens/                        # login, register, splash
│       ├── home/presentation/
│       │   ├── providers/search_provider.dart      # FutureProviders: subjects/topics/resources/search/user
│       │   └── screens/                            # home, search, topics, resources, pdf_viewer, downloads
│       ├── profile/presentation/screens/          # profile, edit_profile (+ userStatsProvider)
│       └── upload/
│           ├── data/
│           │   ├── resource_repository.dart        # thin wrapper over ApiService.uploadResource
│           │   └── models/                          # DUPLICATE/legacy models (resource/subject/topic + models.dart)
│           └── presentation/
│               ├── providers/upload_provider.dart  # FilePicker service + UploadNotifier state machine
│               └── screens/upload_screen.dart      # Upload form with STATIC predefined subjects/topics
│
├── test/                        # Flutter unit tests (3 files)
│   ├── resource_model_test.dart # Model JSON parse logic tests
│   ├── storage_service_test.dart# MIME-type / size / error-code logic tests (refers to Firebase Storage)
│   └── upload_flow_test.dart    # Upload state/validation/flow tests (refers to Firestore)
│
├── docs/PRD.md                  # Product requirements document
├── plans/study-resource-sharing.md  # Plan document (see §17 note: referenced in PRD; verify)
├── android/ ios/ macos/ linux/ windows/ web/   # Flutter platform host projects
├── *.bat / *.ps1                # Firewall / status helper scripts (ADD_FIREWALL_RULE.bat, add-firewall-rule.ps1, etc.)
└── (47 root-level *.md status/fix logs)         # e.g. UPLOAD_FIX_*.md, FIREBASE_*_SETUP.md, TEST_REPORT*.md
```

Root-level status/fix Markdown logs (selection, all tracked): `ACTION_PLAN.md`, `COMMANDS_REFERENCE.md`, `CRITICAL_FIX_FIREBASE_STORAGE.md`, `EXPLORE_AND_SEARCH_FIX.md`, `FINAL_FIX_127.md`, `FINAL_SIMPLE_FIX.md`, `FINAL_UPLOAD_FIX.md`, `FIREBASE_SETUP_GUIDE.md`, `FIREBASE_STORAGE_SETUP.md`, `FIREBASE_UPLOAD_FIX.md`, `HOT_RESTART_INSTRUCTIONS.md`, `IMPLEMENTATION_COMPLETE.md`, `MONGODB_UPLOAD_FIX.md`, `NOTEFLOW_COMPLETE_PROJECT_REPORT.md`, `NOTEFLOW_DOCUMENTATION_PART1/2/3.md`, `PROBLEM_IDENTIFIED_AND_FIXED.md`, `PROFILE_PICTURE_*.md`, `QUICK_FIX_STEPS.md`, `QUICK_REFERENCE.md`, `QUICK_START.md`, `README_UPLOAD_FIX.md`, `SIMPLE_SOLUTION.md`, `SOLUTION_SUMMARY.md`, `SPLASH_*.md`, `TEST_REPORT.md`, `TEST_REPORT_MOBILE.md`, `UPLOADS_FIXED.md`, `UPLOAD_*.md`, `USB_CONNECTION_FIX.md`, `VERIFICATION_COMPLETE.md`, `WAIT_FOR_BUILD.md`, `test_splash_screen.md`. (The README's structure section references `FLUTTER_SETUP.md`, which is **not** present in the repo — [README.md:69](README.md#L69), [README.md:146](README.md#L146).)

---

## 3. Tech stack & dependencies

### Runtimes / SDKs
- **Dart SDK constraint:** `^3.9.2` ([pubspec.yaml:7](pubspec.yaml#L7)).
- **Flutter:** SDK-pinned (uses `flutter` from SDK). Min Android SDK for launcher icons set to 21 ([pubspec.yaml:47](pubspec.yaml#L47)).
- **Python:** "3.8+" stated ([README.md:79](README.md#L79), [backend/SETUP.md:5](backend/SETUP.md#L5)). No `runtime.txt`/`pyproject.toml`.
- **Android build:** Java 11 source/target, Kotlin jvmTarget 11; `compileSdk`/`minSdk`/`targetSdk` inherited from Flutter ([android/app/build.gradle.kts:16-33](android/app/build.gradle.kts#L16-L33)). `namespace`/`applicationId` = `com.example.noteflow` ([android/app/build.gradle.kts:12](android/app/build.gradle.kts#L12), [:27](android/app/build.gradle.kts#L27)).

### Flutter dependencies ([pubspec.yaml:9-29](pubspec.yaml#L9-L29)) — constraint versions; `pubspec.lock` pins exact versions
| Package | Constraint | Used for |
|---|---|---|
| `firebase_core` | ^4.7.0 | Firebase initialization ([lib/main.dart:19](lib/main.dart#L19)) |
| `firebase_auth` | ^6.4.0 | Email/password auth ([lib/features/auth/data/auth_repository.dart](lib/features/auth/data/auth_repository.dart)) |
| `flutter_riverpod` | ^2.4.9 | State management / DI (providers throughout) |
| `go_router` | ^13.0.1 | Routing ([lib/core/router/app_router.dart](lib/core/router/app_router.dart)) |
| `http` | ^1.2.0 | REST calls to backend ([lib/core/services/api_service.dart](lib/core/services/api_service.dart)) |
| `syncfusion_flutter_pdfviewer` | ^33.2.4 | In-app PDF rendering ([lib/features/home/presentation/screens/pdf_viewer_screen.dart:3](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L3)) |
| `file_picker` | ^8.0.0 | Picking PDF/PPT to upload ([lib/features/upload/presentation/providers/upload_provider.dart:1](lib/features/upload/presentation/providers/upload_provider.dart#L1)) |
| `image_picker` | ^1.0.7 | Declared; no usage found in `lib/` `(inferred unused)` |
| `hive` | ^2.2.3 | Local key-value store |
| `hive_flutter` | ^1.1.0 | Hive Flutter bindings ([lib/core/database/local_db.dart:1](lib/core/database/local_db.dart#L1)) |
| `path_provider` | ^2.1.2 | Temp/downloads directories ([lib/core/services/api_service.dart:6](lib/core/services/api_service.dart#L6)) |
| `uuid` | ^4.3.3 | Declared; no usage found in `lib/` `(inferred unused)` |
| `url_launcher` | ^6.3.0 | Declared; no usage found in `lib/` `(inferred unused)` |
| `http_parser` | ^4.1.2 | `MediaType` for multipart upload ([lib/core/services/api_service.dart:3](lib/core/services/api_service.dart#L3)) |
| `permission_handler` | ^11.0.1 | Android storage permission for downloads ([lib/features/home/presentation/screens/pdf_viewer_screen.dart:4](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L4)) |
| `google_fonts` | ^6.2.1 | Inter font ([lib/core/theme/app_theme.dart:2](lib/core/theme/app_theme.dart#L2)) |
| `intl` | ^0.19.0 | Date formatting ([lib/core/widgets/resource_card.dart:2](lib/core/widgets/resource_card.dart#L2)) |
| `open_file` | ^3.3.2 | Open downloaded files ([lib/features/home/presentation/screens/downloads_screen.dart:4](lib/features/home/presentation/screens/downloads_screen.dart#L4)) |

### Flutter dev dependencies ([pubspec.yaml:31-35](pubspec.yaml#L31-L35))
- `flutter_test` (SDK) — unit tests.
- `flutter_lints` ^5.0.0 — lint rules ([analysis_options.yaml:1](analysis_options.yaml#L1)).
- `flutter_launcher_icons` ^0.13.1 — generates launcher icons for all platforms ([pubspec.yaml:43-59](pubspec.yaml#L43-L59)).

### Python dependencies ([backend/requirements.txt](backend/requirements.txt))
| Package | Version | Used for |
|---|---|---|
| `fastapi` | 0.109.2 | Web framework ([backend/main.py:1](backend/main.py#L1)) |
| `uvicorn[standard]` | 0.27.1 | ASGI server (startup scripts) |
| `motor` | 3.3.2 | Async MongoDB driver + GridFS ([backend/database.py:2](backend/database.py#L2)) |
| `pydantic` | 2.6.1 | Request/response models ([backend/models.py:1](backend/models.py#L1)) |
| `python-multipart` | 0.0.9 | Multipart form uploads `(inferred — required by FastAPI `UploadFile`/`Form`)` |
| `python-dotenv` | 1.0.1 | Loads `.env` ([backend/database.py:5-6](backend/database.py#L5-L6)) |
| `firebase-admin` | 6.4.0 | Firebase token verification ([backend/main.py:9-10](backend/main.py#L9-L10)). **Note:** this line is stored space-mangled as `f i r e b a s e - a d m i n = = 6 . 4 . 0` ([backend/requirements.txt:7](backend/requirements.txt#L7)), which `pip install -r` would not parse correctly. |

**Python imports not present in requirements.txt** (`(inferred)` extra/transitive deps):
- `pymongo` / `bson` — used directly in [backend/check_mongodb.py:1](backend/check_mongodb.py#L1), [backend/fix_uploaded_files.py:6](backend/fix_uploaded_files.py#L6), and `bson.ObjectId` in [backend/main.py:5](backend/main.py#L5) (ships with `motor`).
- `jwt` (PyJWT) — `import jwt as pyjwt` fallback decode in [backend/main.py:179](backend/main.py#L179); `import jwt` in [backend/fix_uploaded_files.py:2](backend/fix_uploaded_files.py#L2). **Not** in requirements.txt.
- `requests` — [backend/test_upload.py:1](backend/test_upload.py#L1). **Not** in requirements.txt.

---

## 4. Entry points & run commands

### Backend
- **Entry point:** `app = FastAPI(...)` in [backend/main.py:21](backend/main.py#L21).
- **Run (manual):** `uvicorn main:app --reload --host 0.0.0.0 --port 8000` ([README.md:123](README.md#L123), [backend/SETUP.md:48](backend/SETUP.md#L48)).
- **start.sh** ([backend/start.sh](backend/start.sh)): checks python3/pip3, `pip3 install -r requirements.txt`, pings Mongo, `python3 init_db.py`, then runs uvicorn on `0.0.0.0:8000`.
- **start.bat** ([backend/start.bat](backend/start.bat)): checks Python, installs deps, runs `init_db.py`, then uvicorn on `0.0.0.0:8000`.
- **init_db.py** ([backend/init_db.py](backend/init_db.py)): `python init_db.py` — creates collections, indexes, sample subjects/topics.
- Standalone scripts: `python check_mongodb.py`, `python fix_uploaded_files.py`, `python test_upload.py`.

### Flutter app
- **Entry point:** `void main()` in [lib/main.dart:10](lib/main.dart#L10) → `runApp(ProviderScope(child: MyApp()))`.
- **Run:** `flutter pub get` then `flutter run` ([README.md:132-143](README.md#L132-L143)).
- **Initial route:** `/` (SplashScreen) ([lib/core/router/app_router.dart:18](lib/core/router/app_router.dart#L18), [:33-39](lib/core/router/app_router.dart#L33-L39)).

### Helper scripts (Windows, repo root / backend)
- `ADD_FIREWALL_RULE.bat`, `FIX_FIREWALL_NOW.bat`, `add-firewall-rule.ps1`, `CHECK_BACKEND_STATUS.bat` — open port 8000 / status checks for local backend connectivity (content not exhaustively read).

### Docker / Compose
- **None found.** No `Dockerfile`, `docker-compose.yml`, or container config in the repo.

---

## 5. Configuration & environment

### Environment variables referenced
- `MONGODB_URL` — read via `os.getenv` in [backend/database.py:8-11](backend/database.py#L8-L11) (default = a live MongoDB Atlas URI, see secrets below), [backend/init_db.py:10](backend/init_db.py#L10) (default `mongodb://localhost:27017/`), [backend/fix_uploaded_files.py:12-15](backend/fix_uploaded_files.py#L12-L15) (default = Atlas URI).
- `TEMP` (OS env) — read via `Platform.environment['TEMP']` for download dir on the client ([lib/core/services/api_service.dart:283](lib/core/services/api_service.dart#L283)).

### Config files
- `backend/.env` ([backend/.env:1](backend/.env#L1)) — `MONGODB_URL=mongodb+srv://...` (see secrets).
- `DATABASE_NAME = "noteflow"` hardcoded ([backend/database.py:12](backend/database.py#L12), [backend/init_db.py:11](backend/init_db.py#L11), [backend/fix_uploaded_files.py:16](backend/fix_uploaded_files.py#L16)).
- `firebase.json` — FlutterFire config, project `noteflow-auth-project`.
- `lib/firebase_options.dart` — per-platform Firebase options.
- `android/app/google-services.json` — Android Firebase config.
- `analysis_options.yaml` — lint config.
- `.vscode/settings.json` — editor settings (tracked).

### Feature flags
- **None found** (no flag system).

### Secrets present in the repo (tracked)
- **MongoDB Atlas credentials in plaintext** (username `vivekgaddam02_db_user`, password embedded) — hardcoded as the default `MONGODB_URL` in [backend/database.py:10](backend/database.py#L10) and [backend/fix_uploaded_files.py:14](backend/fix_uploaded_files.py#L14), and in [backend/.env:1](backend/.env#L1).
- **Firebase API keys** for web/android/ios/macos/windows in [lib/firebase_options.dart:43-85](lib/firebase_options.dart#L43-L85) and [android/app/google-services.json:18](android/app/google-services.json#L18) (client-side Firebase keys; project `noteflow-auth-project`, project number `312243560479`).
- `.gitignore` lists `serviceAccount.json` and a broad `*.json` ([.gitignore:46-47](.gitignore#L47)), yet `firebase.json` and `android/app/google-services.json` are committed (committed before the ignore rule, or force-added). Commit `d87787c` is titled "chore: fully remove service account from tracking", indicating a Firebase service-account JSON was previously tracked and removed.
- Backend `firebase_admin.initialize_app()` is called with **no** explicit credential/service-account path ([backend/main.py:16-19](backend/main.py#L16-L19)); on failure it silently falls back (see §9).

---

## 6. Architecture facts

Two independently deployed components:

1. **Flutter client** (`lib/`) — feature-first layout (`core/` + `features/auth|home|profile|upload`). State/DI via Riverpod providers. Navigation via GoRouter. Talks to the backend over plain HTTP using the `http` package ([lib/core/services/api_service.dart](lib/core/services/api_service.dart)). Talks to Firebase Auth directly for authentication ([lib/features/auth/data/auth_repository.dart](lib/features/auth/data/auth_repository.dart)). Persists theme preference and downloaded-file metadata locally in Hive ([lib/core/services/theme_service.dart](lib/core/services/theme_service.dart), [lib/core/database/local_db.dart](lib/core/database/local_db.dart)).

2. **FastAPI backend** (`backend/`) — single-module API ([backend/main.py](backend/main.py)). Connects to MongoDB via Motor; stores file **bytes in GridFS** and **metadata in the `resources` collection** ([backend/main.py:196-270](backend/main.py#L196-L270)). Verifies Firebase ID tokens via `firebase-admin`, with an unsigned-JWT fallback ([backend/main.py:159-194](backend/main.py#L159-L194)).

### Client → backend wiring
- `ApiService.getBaseUrl()` returns `http://192.168.0.8:8000` on Android (a hardcoded LAN IP) and `http://localhost:8000` otherwise ([lib/core/services/api_service.dart:15-23](lib/core/services/api_service.dart#L15-L23)). **Discrepancy:** README/SETUP say Android emulator should use `http://10.0.2.2:8000` ([README.md:247](README.md#L247), [backend/SETUP.md:53](backend/SETUP.md#L53)).
- Riverpod provider graph: `apiServiceProvider` ([lib/core/services/api_provider.dart:4](lib/core/services/api_provider.dart#L4)) → consumed by `resourceRepositoryProvider` ([lib/features/upload/data/resource_repository.dart:6](lib/features/upload/data/resource_repository.dart#L6)) and the `search_provider` FutureProviders ([lib/features/home/presentation/providers/search_provider.dart](lib/features/home/presentation/providers/search_provider.dart)). `authStateProvider` drives `goRouterProvider` redirects ([lib/core/router/app_router.dart:15-30](lib/core/router/app_router.dart#L15-L30)).

### Notable architectural inconsistency — subject/topic identifiers
- The **Upload screen uses static hardcoded subject/topic IDs** like `cs`, `math`, `cs_dsa`, `phy_mechanics`, etc. ([lib/features/upload/presentation/screens/upload_screen.dart:22-62](lib/features/upload/presentation/screens/upload_screen.dart#L22-L62)). These string IDs are stored as `subject`/`topic` on the resource.
- The **Explore/Search screens fetch subjects from MongoDB** via `GET /subjects/`, whose IDs are Mongo `ObjectId` strings ([lib/features/home/presentation/providers/search_provider.dart:8-11](lib/features/home/presentation/providers/search_provider.dart#L8-L11)).
- The backend's enrichment code calls `ObjectId(subject)` to look up names ([backend/main.py:259-263](backend/main.py#L259-L263), [:352](backend/main.py#L352)); for the static IDs this raises and is swallowed, yielding `subject_name`/`topic_name` = `"Unknown"` ([backend/main.py:347-360](backend/main.py#L347-L360)). So uploaded resources and the `init_db.py` sample subjects are keyed differently.

### Legacy/duplicate code
- `lib/features/upload/data/models/` contains a **second, different `Resource` model** (fields `fileUrl`, `fileType`, `uploadedBy`, `toMap`/`fromMap`) ([lib/features/upload/data/models/resource.dart](lib/features/upload/data/models/resource.dart)) plus `subject.dart`, `topic.dart`, and a barrel `models.dart` ([lib/features/upload/data/models/models.dart](lib/features/upload/data/models/models.dart)). The app's active model is [lib/core/models/resource.dart](lib/core/models/resource.dart). No import of the upload-feature `models.dart` was found in active screens `(inferred legacy)`.

---

## 7. Data layer

- **DB engine:** MongoDB (database name `noteflow`). Driver: Motor (async) on the server ([backend/database.py:2,12](backend/database.py#L2)); PyMongo (sync) in helper scripts.
- **File storage:** MongoDB **GridFS** via `AsyncIOMotorGridFSBucket` ([backend/database.py:15,20,32-33](backend/database.py#L15-L33)). (README/PRD text still references Firebase Storage — see §17.)
- **ORM:** None. Pydantic models for validation/serialization; raw Mongo dict access.

### Collections
| Collection | Created in | Fields (from code) |
|---|---|---|
| `subjects` | [backend/main.py:53-55](backend/main.py#L53-L55), [backend/init_db.py:57-63](backend/init_db.py#L57-L63) | `_id` (ObjectId), `name` (str) — model `SubjectCreate`/`SubjectResponse` ([backend/models.py:25-30](backend/models.py#L25-L30)) |
| `topics` | [backend/main.py:57-59](backend/main.py#L57-L59), [backend/init_db.py:71-80](backend/init_db.py#L71-L80) | `_id`, `name` (str), `subject` (str id) — model `TopicCreate`/`TopicResponse` ([backend/models.py:33-39](backend/models.py#L33-L39)) |
| `resources` | [backend/main.py:61-63](backend/main.py#L61-L63) | `_id`, `title`, `subject`, `topic`, `firebase_uid`, `file_id` (GridFS id str), `file_name`, `content_type`, `size` (int), `likes` (int, default 0), `downloads` (int, default 0), `created_at` (datetime) — written at [backend/main.py:237-249](backend/main.py#L237-L249); model `ResourceCreate`/`ResourceResponse` ([backend/models.py:6-22](backend/models.py#L6-L22)) adds `id`, `subject_name`, `topic_name` |
| GridFS `fs.files` / `fs.chunks` | implicit via GridFS bucket | binary chunks + metadata `{contentType, firebase_uid}` ([backend/main.py:218-221](backend/main.py#L218-L221)) |

### Indexes ([backend/main.py:65-74](backend/main.py#L65-L74), [backend/init_db.py:36-48](backend/init_db.py#L36-L48))
- `subjects`: index on `name`.
- `topics`: compound index `(name, subject)`.
- `resources`: compound index `(title, subject, topic)` and index on `uploaded_at`. (Note: documents are written with field `created_at`, not `uploaded_at` — the `uploaded_at` index covers a field that is not populated by `/upload`.)

### Relationships (by string reference, not enforced)
- `topic.subject` → `subjects._id` (string). `resource.subject` → subject id, `resource.topic` → topic id, `resource.firebase_uid` → Firebase user UID.

### Client-side models
- `Resource` ([lib/core/models/resource.dart](lib/core/models/resource.dart)): `id, title, subjectId, topicId, firebaseUid, fileId, fileName, contentType, size, likes, downloads, uploadedAt, subjectName?, topicName?, description?, uploadedBy?`. `fromJson` accepts both snake_case (backend) and camelCase + Firestore `Timestamp {_seconds}` ([:38-68](lib/core/models/resource.dart#L38-L68)). `fileType` getter derives extension from filename/content-type ([:95-102](lib/core/models/resource.dart#L95-L102)).
- `Subject` ([lib/core/models/subject.dart](lib/core/models/subject.dart)): `id, name`.
- `Topic` ([lib/core/models/topic.dart](lib/core/models/topic.dart)): `id, name, subjectId`.

### Local storage (Hive)
- Box `downloads` (`Box<Map>`) — keyed by resourceId, stores download metadata ([lib/core/database/local_db.dart:4-27](lib/core/database/local_db.dart#L4-L27)).
- Box `settings` — key `theme_mode` (`light`/`dark`/`system`) ([lib/core/services/theme_service.dart:7-9,45-60](lib/core/services/theme_service.dart#L7-L60)).

---

## 8. API surface

### Backend endpoints (all in [backend/main.py](backend/main.py))
| Method | Path | Handler (line) | Purpose |
|---|---|---|---|
| GET | `/` | `root` ([:42](backend/main.py#L42)) | Returns welcome message |
| GET | `/subjects/` | `get_subjects` ([:78](backend/main.py#L78)) | List all subjects |
| POST | `/subjects/` | `create_subject` ([:91](backend/main.py#L91)) | Create a subject |
| GET | `/subjects/{subject_id}/topics/` | `get_topics` ([:101](backend/main.py#L101)) | List topics for a subject |
| POST | `/topics/` | `create_topic` ([:113](backend/main.py#L113)) | Create a topic |
| GET | `/topics/{topic_id}/resources/` | `get_resources_by_topic` ([:123](backend/main.py#L123)) | List resources for a topic |
| GET | `/resources/` | `get_all_resources` ([:135](backend/main.py#L135)) | List all resources |
| POST | `/upload` | `upload_resource` ([:196](backend/main.py#L196)) | Upload file to GridFS + save metadata (auth required) |
| GET | `/file/{file_id}` | `download_file` ([:272](backend/main.py#L272)) | Stream a file from GridFS |
| GET | `/search/` | `search_resources` ([:311](backend/main.py#L311)) | Search resources by `q` (title regex), optional `subject`/`topic` filters |
| GET | `/user/resources/` | `get_user_resources` ([:369](backend/main.py#L369)) | Resources uploaded by the authenticated user (auth required) |
| ~~POST~~ | ~~`/resources/`~~ | commented out ([:148-157](backend/main.py#L148-L157)) | Deprecated create endpoint (disabled) |

- CORS: wide-open — `allow_origins=["*"]`, all methods/headers, credentials allowed ([backend/main.py:24-30](backend/main.py#L24-L30)).
- Note: README/SETUP advertise `POST /resources/` for upload ([README.md:163](README.md#L163), [backend/SETUP.md:74](backend/SETUP.md#L74)), but the active upload endpoint is `POST /upload`.

### Client API calls ([lib/core/services/api_service.dart](lib/core/services/api_service.dart))
- `getSubjects()` → `GET /subjects/` ([:30-43](lib/core/services/api_service.dart#L30-L43)).
- `getTopics(subjectId)` → `GET /subjects/{id}/topics/` ([:46-59](lib/core/services/api_service.dart#L46-L59)).
- `getAllResources()` → `GET /resources/` ([:62-75](lib/core/services/api_service.dart#L62-L75)).
- `getUserResources(token)` → `GET /user/resources/` with `Authorization: Bearer` ([:78-96](lib/core/services/api_service.dart#L78-L96)).
- `searchResources({query, subjectId, topicId})` → `GET /search/?q&subject&topic` ([:99-119](lib/core/services/api_service.dart#L99-L119)).
- `getResources(topicId)` → `GET /topics/{id}/resources/` ([:122-135](lib/core/services/api_service.dart#L122-L135)).
- `uploadResource(...)` → `POST /upload` multipart with Bearer token, 120s timeout, progress callback ([:138-268](lib/core/services/api_service.dart#L138-L268)).
- `downloadFile(fileId)` → `GET /file/{id}`, writes to temp dir as `<id>.pdf` ([:272-309](lib/core/services/api_service.dart#L272-L309)).

### Third-party / external APIs called
- **Firebase Authentication** (client SDK) — sign in / register / sign out / getIdToken / reauthenticate / updateEmail / updatePassword / delete ([lib/features/auth/data/auth_repository.dart](lib/features/auth/data/auth_repository.dart), [lib/features/profile/presentation/screens/edit_profile_screen.dart:77-303](lib/features/profile/presentation/screens/edit_profile_screen.dart#L77-L303)).
- **Firebase Admin** token verification API (server) ([backend/main.py:168](backend/main.py#L168)).
- **Google Fonts** (Inter) fetched at runtime via `google_fonts` ([lib/core/theme/app_theme.dart:59](lib/core/theme/app_theme.dart#L59)).
- User `photoURL` loaded via `NetworkImage` when present ([lib/features/profile/presentation/screens/profile_screen.dart:216](lib/features/profile/presentation/screens/profile_screen.dart#L216)).

---

## 9. Authentication & authorization

- **Client auth:** Firebase Authentication, email/password. `AuthRepository` wraps `FirebaseAuth.instance` ([lib/features/auth/data/auth_repository.dart:12-57](lib/features/auth/data/auth_repository.dart#L12-L57)). `AuthController` (StateNotifier) exposes `login/register/logout/getIdToken` ([lib/features/auth/presentation/providers/auth_provider.dart](lib/features/auth/presentation/providers/auth_provider.dart)).
- **Route guarding:** GoRouter `redirect` sends unauthenticated users to `/login`, authenticated users away from login/register to `/home` ([lib/core/router/app_router.dart:19-29](lib/core/router/app_router.dart#L19-L29)).
- **Token usage:** Client attaches `Authorization: Bearer <firebase ID token>` to `/upload` and `/user/resources/` ([lib/core/services/api_service.dart:82-84](lib/core/services/api_service.dart#L82-L84), [:162](lib/core/services/api_service.dart#L162)).
- **Server verification:** `verify_firebase_token` dependency ([backend/main.py:159-194](backend/main.py#L159-L194)) parses the Bearer header, tries `firebase_admin.auth.verify_id_token`, and on **any failure falls back to decoding the JWT with `verify_signature: False`** (logged as "DEV MODE"), extracting `user_id`/`sub` ([backend/main.py:172-189](backend/main.py#L172-L189)). This means a request can authenticate without a verified signature if Admin verification fails.
- **Firebase Admin init:** `firebase_admin.initialize_app()` with no credentials, errors swallowed ([backend/main.py:16-19](backend/main.py#L16-L19)).
- **Authorization scope:** Only ownership filtering by `firebase_uid` on `/user/resources/` ([backend/main.py:381](backend/main.py#L381)). `/upload` stores the caller's UID. No roles/admin. `/subjects/`, `/topics/`, `/resources/`, `/search/`, `/file/{id}` are **unauthenticated** (any client can read all resources and download any file).
- **Profile/account:** `EditProfileScreen` performs re-auth with `EmailAuthProvider.credential`, then `verifyBeforeUpdateEmail`, `updatePassword`, and `user.delete()` ([lib/features/profile/presentation/screens/edit_profile_screen.dart:77-303](lib/features/profile/presentation/screens/edit_profile_screen.dart#L77-L303)).
- Password rule enforced in UI: min 6 chars ([lib/features/auth/presentation/screens/login_screen.dart:183-185](lib/features/auth/presentation/screens/login_screen.dart#L183-L185)).

---

## 10. Core logic

| Function / unit | File:line | What it does |
|---|---|---|
| `upload_resource` | [backend/main.py:196](backend/main.py#L196) | Reads file, enforces 50 MB `MAX_FILE_SIZE`, streams into GridFS, saves metadata, enriches subject/topic names |
| `download_file` | [backend/main.py:272](backend/main.py#L272) | Opens GridFS download stream and returns chunked `StreamingResponse` |
| `search_resources` | [backend/main.py:311](backend/main.py#L311) | Builds Mongo query (`title` regex case-insensitive via `re.escape`, optional subject/topic), sorts by `created_at` desc, enriches names |
| `verify_firebase_token` | [backend/main.py:159](backend/main.py#L159) | Firebase ID-token verification with unsigned-JWT fallback |
| `initialize_collections` | [backend/main.py:46](backend/main.py#L46) | Creates collections + indexes on startup |
| `extract_uid_from_jwt` / `fix_resources` | [backend/fix_uploaded_files.py:18,28](backend/fix_uploaded_files.py#L18) | Migration: rewrites `firebase_uid` fields that contain a full JWT into the decoded UID |
| `ApiService.uploadResource` | [lib/core/services/api_service.dart:138](lib/core/services/api_service.dart#L138) | Builds multipart request, sets content-type by extension, streams response, reports progress, maps errors |
| `ApiService.downloadFile` | [lib/core/services/api_service.dart:272](lib/core/services/api_service.dart#L272) | Downloads file bytes to a temp `.pdf` path |
| `Resource.fromJson` | [lib/core/models/resource.dart:38](lib/core/models/resource.dart#L38) | Tolerant JSON parsing across backend/Firestore field shapes incl. Timestamp |
| `UploadNotifier.upload` / `pickFile` | [lib/features/upload/presentation/providers/upload_provider.dart:76,107](lib/features/upload/presentation/providers/upload_provider.dart#L76) | File-pick with 200 MB max / 50 MB warning; validates fields; gets token; uploads; tracks state |
| `goRouterProvider` redirect | [lib/core/router/app_router.dart:19](lib/core/router/app_router.dart#L19) | Auth-based navigation gating |
| `ThemeModeNotifier` | [lib/core/services/theme_service.dart:64](lib/core/services/theme_service.dart#L64) | Persisted light/dark/system theme toggle |
| `userStatsProvider` | [lib/features/profile/presentation/screens/profile_screen.dart:14](lib/features/profile/presentation/screens/profile_screen.dart#L14) | Computes uploads (filter all resources by uid), downloads (Hive count), unique subjects |
| `_saveToDownloads` | [lib/features/home/presentation/screens/pdf_viewer_screen.dart:71](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L71) | Requests storage permission, copies temp PDF to Downloads dir, records in Hive |
| `_EmptyStatePainter` | [lib/core/widgets/empty_state.dart:63](lib/core/widgets/empty_state.dart#L63) | CustomPainter drawing empty-state illustration |

### Client-side validation thresholds
- Client upload: max **200 MB** (block), **50 MB** (warning) ([lib/features/upload/presentation/providers/upload_provider.dart:83-84](lib/features/upload/presentation/providers/upload_provider.dart#L83-L84)).
- Server upload: rejects > **50 MB** with HTTP 413 ([backend/main.py:210,226-227](backend/main.py#L210-L227)). **Discrepancy:** client permits files up to 200 MB that the server will reject.
- Allowed extensions: `pdf, ppt, pptx` ([lib/features/upload/presentation/providers/upload_provider.dart:15,79](lib/features/upload/presentation/providers/upload_provider.dart#L15)).
- In-app preview only for `pdf`; other types show a toast ([lib/features/home/presentation/screens/home_screen.dart:333-340](lib/features/home/presentation/screens/home_screen.dart#L333-L340)).
- Search input debounced 300 ms ([lib/features/home/presentation/screens/search_screen.dart:48](lib/features/home/presentation/screens/search_screen.dart#L48)).

---

## 11. Background / async work

- No job queue, cron, or worker process found.
- FastAPI lifecycle hooks: `@app.on_event("startup")` connects Mongo + initializes collections; `@app.on_event("shutdown")` closes the connection ([backend/main.py:32-40](backend/main.py#L32-L40)).
- File download uses an async generator to stream GridFS chunks (`file_stream`) ([backend/main.py:294-307](backend/main.py#L294-L307)).
- Client uses async streams for upload progress and `Future.delayed` timers for splash navigation / success reset; search uses a `Timer` debounce. No WebSockets/SSE.

---

## 12. Tests

- **Framework:** `flutter_test` (Dart). No Python test framework configured (`backend/test_upload.py` is a manual connectivity script, not pytest).
- **Test files (3, in [test/](test/)):**
  - [test/resource_model_test.dart](test/resource_model_test.dart) — ~11 tests across Resource/Subject/Topic model JSON parsing (backend + Firestore shapes, defaults, `fileType`, `toJson` structure).
  - [test/storage_service_test.dart](test/storage_service_test.dart) — ~11 tests: MIME-type mapping, storage-path construction, size thresholds, progress math, Firebase Storage error-code mapping.
  - [test/upload_flow_test.dart](test/upload_flow_test.dart) — ~9 tests: file-size/extension/form validation, predefined subject/topic mapping, upload state transitions, "Firestore" document structure, end-to-end step sequence.
- **Rough count:** ~31 `test(...)` cases across 7 `group(...)`s.
- **Coverage characteristics:** Tests largely **re-implement** the logic inline (copy of switch/validation code) rather than importing the production classes; `storage_service_test.dart` and `upload_flow_test.dart` reference **Firebase Storage / Firestore** concepts that the current backend (MongoDB/GridFS) does not use `(inferred legacy from an earlier Firebase-based design)`.
- No widget tests or integration_test directory present (PRD lists widget/integration tests as intended — §17).
- `ios/RunnerTests/RunnerTests.swift` and `macos/RunnerTests/RunnerTests.swift` are default Flutter host test stubs.

---

## 13. Build, CI/CD & deployment

- **CI/CD:** **None found.** No `.github/workflows/`, GitLab CI, CircleCI, Jenkins, or similar.
- **Dockerfiles / compose:** None.
- **IaC:** None (no Terraform/Pulumi/CloudFormation).
- **Android build:** Gradle Kotlin DSL; debug signing used for release builds (`signingConfig = signingConfigs.getByName("debug")`) and a `TODO` to add real signing ([android/app/build.gradle.kts:36-42](android/app/build.gradle.kts#L36-L42)). Google Services plugin applied ([android/app/build.gradle.kts:4](android/app/build.gradle.kts#L4)).
- **Platforms scaffolded:** Android, iOS, macOS, Linux, Windows, Web (full Flutter host directories present). Launcher icons generated for android/ios/web/windows/macos/linux ([pubspec.yaml:43-59](pubspec.yaml#L43-L59)).
- **Android permissions:** `INTERNET` is declared **only** in debug/profile manifests ([android/app/src/debug/AndroidManifest.xml:6](android/app/src/debug/AndroidManifest.xml#L6), [android/app/src/profile/AndroidManifest.xml:6](android/app/src/profile/AndroidManifest.xml#L6)); the main manifest ([android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)) declares no `INTERNET` or storage permissions. The app requests `Permission.storage` at runtime for downloads ([lib/features/home/presentation/screens/pdf_viewer_screen.dart:81](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L81)) and writes to `/storage/emulated/0/Download` on Android ([:90](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L90)).
- **Deployment target / hosting:** Backend designed for local/LAN (`localhost`, `10.0.2.2`, hardcoded `192.168.0.8`, port 8000); MongoDB on Atlas (cloud) via connection string. No production host/deploy config in code.
- **Environment stages:** None defined (single config; "DEV MODE" auth fallback is the only stage notion — [backend/main.py:176](backend/main.py#L176)).

---

## 14. Observability

- **Logging:** `print()` statements only. Backend: token verification and errors ([backend/main.py:170-189](backend/main.py#L170-L189)). Client: extensive `print()`/`debugPrint()` in upload/download flows ([lib/core/services/api_service.dart:149-266](lib/core/services/api_service.dart#L149-L266), [lib/main.dart:23](lib/main.dart#L23)).
- **Suggested debug commands** in README: `uvicorn main:app --log-level debug`, `flutter run -v` ([README.md:342-343](README.md#L342-L343)).
- **Monitoring / error tracking / metrics:** None (no Sentry, Crashlytics, Prometheus, OpenTelemetry, analytics SDK found).

---

## 15. Performance / scale features

- **DB indexes:** present (see §7).
- **Search:** server-side case-insensitive regex on `title`, sorted by `created_at` desc ([backend/main.py:336-340](backend/main.py#L336-L340)).
- **Pagination:** None — list/search endpoints use `to_list(length=None)` (returns all matching docs) ([backend/main.py:82](backend/main.py#L82), [:341](backend/main.py#L341)).
- **Rate limiting:** None.
- **Caching:** Client caches downloaded files to temp dir and records downloads in Hive for offline access ([lib/core/services/api_service.dart:281-301](lib/core/services/api_service.dart#L281-L301), [lib/core/database/local_db.dart](lib/core/database/local_db.dart)). Google Fonts caches fetched fonts `(inferred, package behavior)`.
- **Streaming:** File download is chunk-streamed from GridFS; upload reads the entire file into memory before writing (`await file.read()`) ([backend/main.py:224-229](backend/main.py#L224-L229)).
- **UI perf:** debounced search (300 ms), shimmer skeletons, `IndexedStack` to keep tab state.

---

## 16. Code-quality signals

- **Linter:** `flutter_lints` ^5.0.0 via `analysis_options.yaml` (`include: package:flutter_lints/flutter.yaml`) ([analysis_options.yaml:1](analysis_options.yaml#L1)).
- **Formatter / type-checker:** Dart analyzer (built-in); no additional formatter/type config. No Python linter/formatter/type-checker config (`ruff`/`black`/`mypy`/`flake8` not present).
- **TODO/FIXME/HACK comments:** A `Grep` for `TODO|FIXME|HACK|XXX` across `.dart`/`.py` returned **no matches**. The only TODOs are in generated Android Gradle config:
  - `// TODO: Specify your own unique Application ID ...` ([android/app/build.gradle.kts:26](android/app/build.gradle.kts#L26)).
  - `// TODO: Add your own signing config for the release build.` ([android/app/build.gradle.kts:38](android/app/build.gradle.kts#L38)).
- **Deprecated API usage `(inferred)`:** `@app.on_event("startup"/"shutdown")` (deprecated in modern FastAPI) ([backend/main.py:32,38](backend/main.py#L32)); `datetime.utcnow()` ([backend/main.py:248](backend/main.py#L248)); `withOpacity` (deprecated in newer Flutter) used alongside `withValues` ([lib/features/upload/presentation/screens/upload_screen.dart:212](lib/features/upload/presentation/screens/upload_screen.dart#L212) vs [lib/features/home/presentation/screens/home_screen.dart:211](lib/features/home/presentation/screens/home_screen.dart#L211)).

---

## 17. Metrics / data present

- **Sample/seed data:** `init_db.py` inserts 3 subjects (Mathematics, Physics, Computer Science) and 6 topics (Calculus, Linear Algebra, Mechanics, Thermodynamics, Data Structures, Algorithms) only if the DB is empty ([backend/init_db.py:56-81](backend/init_db.py#L56-L81)).
- **Hardcoded UI catalog:** Upload screen defines 4 subjects and 24 topics as static lists ([lib/features/upload/presentation/screens/upload_screen.dart:22-62](lib/features/upload/presentation/screens/upload_screen.dart#L22-L62)).
- **Thresholds present in code:** 50 MB server cap, 200 MB/50 MB client limits, 120 s upload timeout, 2 s splash delay, 300 ms search debounce, 1500 ms shimmer/splash animation.
- **No datasets, benchmarks, or real measured metrics** found in the repo.
- **Discrepancy between docs and code:** README "Tech Stack" lists `flutter_pdfview` and "Firebase Storage" ([README.md:299](README.md#L299), [README.md:10](README.md#L10)); the code actually uses `syncfusion_flutter_pdfviewer` ([lib/features/home/presentation/screens/pdf_viewer_screen.dart:3](lib/features/home/presentation/screens/pdf_viewer_screen.dart#L3)) and MongoDB GridFS for file storage. PRD ([docs/PRD.md:34-39,79](docs/PRD.md#L34-L39)) likewise specifies Firebase Storage + `flutter_pdfview` and "No file size limit", none of which match the implemented backend. PRD references a `plans/study-resource-sharing.md` plan file (present in tree).

---

## 18. Git facts

- **Commit count:** 4 (`git rev-list --count HEAD`).
- **Contributors:** 1 — `KARTHIK-BATTIPROLU <ugs24304_aid.battiprolu@cbit.org.in>` (`git shortlog -sne`).
- **Commit history (newest → oldest):**
  - `58cf8d2` — "Uploading done" — 2026-05-01 15:18:13 +0530
  - `d87787c` — "chore: fully remove service account from tracking" — 2026-05-01 12:39:45 +0530
  - `5730745` — "firs commit" — 2026-04-15 13:36:46 +0530
  - `09124d1` — "firs commit" — 2026-04-15 13:34:02 +0530
- **Last commit date:** 2026-05-01.
- **Current branch:** `master`.
- **Uncommitted at audit time** (from initial status): modified `lib/core/services/api_service.dart`, `pubspec.lock`; untracked status/fix Markdown files and `FIX_FIREWALL_NOW.bat`. (`PROJECT_DETAILS.md` is added by this audit.)

---

## 19. Unknowns (not determinable from code — fill in manually)

- Production hosting/deployment for the backend (the code targets localhost/LAN/Atlas; no deploy manifests). 
- Whether the MongoDB Atlas credentials in `backend/.env` / `database.py` are still live or have been rotated (they are committed in plaintext).
- Whether `firebase-admin` is actually installed/working in any environment (requirements.txt line is space-mangled; `initialize_app()` has no service-account path), i.e. whether token verification runs in real mode or the unsigned-JWT fallback.
- The intended canonical subject/topic identifier scheme (static string IDs from the Upload screen vs Mongo ObjectIds from `/subjects/`) — these are inconsistent in code.
- The real source/values of `pubspec.lock`-pinned versions vs the latest available (lock not transcribed here beyond constraints).
- Intended `INTERNET` permission for Android **release** builds (only declared for debug/profile).
- Contents/intent of the many root-level status/fix Markdown logs (treated here as historical notes, not specs).
- Whether `image_picker`, `uuid`, and `url_launcher` dependencies are intended for future features (no current usage found).
- Backend test strategy (no Python test runner configured); whether `test_upload.py`/`check_mongodb.py`/`fix_uploaded_files.py` are run manually or in any pipeline.
- Real-world data volumes, performance benchmarks, and number of actual users/resources (none in repo).
