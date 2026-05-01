## 🔌 API DOCUMENTATION

### Base URL
- **Local Development**: \http://localhost:8000\
- **Android Emulator**: \http://10.0.2.2:8000\
- **Physical Device**: \http://YOUR_COMPUTER_IP:8000\
- **Production**: \https://your-domain.com\

### API Endpoints

#### 1. Root Endpoint
\\\
GET /
\\\
**Description**: Health check endpoint  
**Response**:
\\\json
{
  "message": "Welcome to NoteFlow API"
}
\\\

#### 2. Get All Subjects
\\\
GET /subjects/
\\\
**Description**: Retrieve all subjects  
**Response**: Array of Subject objects
\\\json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "name": "Mathematics"
  }
]
\\\

#### 3. Create Subject
\\\
POST /subjects/
\\\
**Request Body**:
\\\json
{
  "name": "Physics"
}
\\\
**Response**: Created Subject object

#### 4. Get Topics by Subject
\\\
GET /subjects/{subject_id}/topics/
\\\
**Parameters**:
- \subject_id\: MongoDB ObjectId
**Response**: Array of Topic objects
\\\json
[
  {
    "id": "507f1f77bcf86cd799439012",
    "name": "Calculus",
    "subject": "507f1f77bcf86cd799439011"
  }
]
\\\

#### 5. Create Topic
\\\
POST /topics/
\\\
**Request Body**:
\\\json
{
  "name": "Quantum Mechanics",
  "subject": "507f1f77bcf86cd799439011"
}
\\\
**Response**: Created Topic object

#### 6. Get Resources by Topic
\\\
GET /topics/{topic_id}/resources/
\\\
**Parameters**:
- \	opic_id\: MongoDB ObjectId
**Response**: Array of Resource objects

#### 7. Get All Resources
\\\
GET /resources/
\\\
**Description**: Retrieve all resources  
**Response**: Array of Resource objects with enriched data
\\\json
[
  {
    "id": "507f1f77bcf86cd799439013",
    "title": "Introduction to Calculus",
    "subject": "507f1f77bcf86cd799439011",
    "topic": "507f1f77bcf86cd799439012",
    "firebase_uid": "user123",
    "file_id": "507f1f77bcf86cd799439014",
    "file_name": "calculus.pdf",
    "content_type": "application/pdf",
    "size": 2048576,
    "likes": 0,
    "downloads": 0,
    "created_at": "2026-05-01T00:00:00Z",
    "subject_name": "Mathematics",
    "topic_name": "Calculus"
  }
]
\\\

#### 8. Upload Resource
\\\
POST /upload
\\\
**Headers**:
- \Authorization: Bearer {firebase_token}\
**Request**: multipart/form-data
- \	itle\: string (required)
- \subject\: string (required)
- \	opic\: string (required)
- \ile\: file (required, max 50MB)

**Response**: Created Resource object

#### 9. Download File
\\\
GET /file/{file_id}
\\\
**Parameters**:
- \ile_id\: GridFS ObjectId
**Response**: File stream with appropriate content-type
**Headers**:
- \Content-Type\: application/pdf | application/vnd.ms-powerpoint
- \Content-Disposition\: inline; filename="..."

#### 10. Search Resources
\\\
GET /search/
\\\
**Query Parameters**:
- \q\: Search query (optional)
- \subject\: Subject ID filter (optional)
- \	opic\: Topic ID filter (optional)

**Examples**:
- \/search/?q=calculus\
- \/search/?subject=507f1f77bcf86cd799439011\
- \/search/?q=intro&subject=507f1f77bcf86cd799439011\

**Response**: Array of filtered Resource objects

### API Response Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication failed |
| 404 | Not Found | Resource not found |
| 413 | Payload Too Large | File exceeds 50MB limit |
| 500 | Internal Server Error | Server error |

### Authentication Flow

1. User logs in via Firebase Auth (Flutter app)
2. Firebase returns ID token
3. Token sent in Authorization header: \Bearer {token}\
4. Backend verifies token with Firebase Admin SDK
5. Request processed if token valid

---

## 📱 FRONTEND ARCHITECTURE

### Project Structure

\\\
lib/
├── core/
│   ├── database/
│   │   └── local_db.dart              # Hive initialization
│   ├── models/
│   │   ├── resource.dart              # Resource model
│   │   ├── subject.dart               # Subject model
│   │   └── topic.dart                 # Topic model
│   ├── router/
│   │   └── app_router.dart            # GoRouter configuration
│   ├── services/
│   │   └── api_service.dart           # HTTP API client
│   ├── theme/
│   │   └── app_theme.dart             # Design system
│   ├── utils/
│   │   └── toast.dart                 # Toast notifications
│   └── widgets/
│       ├── empty_state.dart           # Empty state widget
│       ├── loading_skeleton.dart      # Loading placeholder
│       ├── resource_card.dart         # Resource card widget
│       └── subject_chip.dart          # Subject chip widget
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart   # Firebase auth logic
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart # Auth state management
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── register_screen.dart
│   │           └── splash_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── search_provider.dart # Search state
│   │       └── screens/
│   │           ├── downloads_screen.dart
│   │           ├── home_screen.dart
│   │           ├── pdf_viewer_screen.dart
│   │           ├── resources_screen.dart
│   │           ├── search_screen.dart
│   │           └── topics_screen.dart
│   ├── profile/
│   │   └── presentation/
│   │       └── screens/
│   │           └── profile_screen.dart
│   └── upload/
│       └── presentation/
│           └── screens/
│               └── upload_screen.dart
├── firebase_options.dart              # Firebase configuration
└── main.dart                          # App entry point
\\\

### State Management (Riverpod)

#### Providers Used:

1. **authStateProvider**
   - Type: StreamProvider<User?>
   - Purpose: Firebase auth state
   - Scope: Global

2. **authControllerProvider**
   - Type: StateNotifierProvider
   - Purpose: Auth actions (login, register, logout)
   - Scope: Global

3. **subjectsProvider**
   - Type: FutureProvider<List<Subject>>
   - Purpose: Fetch subjects from API
   - Scope: Global

4. **allResourcesProvider**
   - Type: FutureProvider<List<Resource>>
   - Purpose: Fetch all resources
   - Scope: Global

5. **searchQueryProvider**
   - Type: StateProvider<String>
   - Purpose: Search input state
   - Scope: Search screen

6. **searchResultsProvider**
   - Type: FutureProvider<List<Resource>>
   - Purpose: Search results
   - Scope: Search screen

7. **themeModeProvider**
   - Type: StateProvider<ThemeMode>
   - Purpose: Dark/Light mode toggle
   - Scope: Global

### Navigation (GoRouter)

#### Routes:

\\\dart
/ (splash)
├── /login
├── /register
└── /home
    ├── /home/topics/:subjectId
    └── /home/topics/:subjectId/:topicId/resources
/pdf-viewer (modal)
\\\

#### Route Guards:
- Unauthenticated users → Redirect to /login
- Authenticated users on /login → Redirect to /home
- Splash screen → Auto-redirect based on auth state

#### Custom Transitions:
- Fade + Slide animation
- Duration: 200ms
- Curve: easeInOut

---

## 🎨 DESIGN SYSTEM

### Brand Identity

**Brand Name**: NoteFlow  
**Tagline**: "Your study companion"  
**Design Philosophy**: "Notion meets Linear"  
**Visual Style**: Clean, modern, professional

### Color Palette

#### Primary Colors
- **Primary**: #4F46E5 (Indigo) - Main brand color
- **Primary Dark**: #6366F1 (Lighter Indigo) - Dark mode variant
- **Accent**: #10B981 (Emerald) - Success, highlights

#### Background Colors
- **Light Background**: #F8F7FF (Lavender-white)
- **Dark Background**: #0F0F1A (Deep blue-black)
- **Light Surface**: #FFFFFF (Pure white)
- **Dark Surface**: #1A1A2E (Dark surface)

#### Text Colors
- **Light Primary Text**: #1F2937 (Almost black)
- **Dark Primary Text**: #F9FAFB (Almost white)
- **Light Secondary Text**: #6B7280 (Gray)
- **Dark Secondary Text**: #9CA3AF (Light gray)

#### File Type Colors
- **PDF**: #DC2626 (Red)
- **PPT**: #F97316 (Orange)
- **Other**: #2563EB (Blue)

### Typography

**Font Family**: Inter (Google Fonts)

#### Text Styles:

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Heading Large | 32px | Bold | Page titles |
| Heading Medium | 24px | Bold | Section headers |
| Heading Small | 20px | SemiBold | Card titles |
| Body Large | 16px | Regular | Primary text |
| Body Medium | 14px | Regular | Secondary text |
| Body Small | 12px | Regular | Metadata |
| Caption | 11px | Regular | Timestamps |
| Button Text | 14px | SemiBold | Buttons |

### Spacing System

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight spacing |
| sm | 8px | Small gaps |
| md | 16px | Standard spacing |
| lg | 24px | Large gaps |
| xl | 32px | Section spacing |
| xxl | 48px | Page spacing |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| sm | 8px | Small elements |
| md | 12px | Cards, inputs |
| lg | 16px | Large cards |
| xl | 24px | Modals |
| pill | 100px | Chips, badges |

### Component Library

#### 1. ResourceCard
**Purpose**: Display resource information  
**Features**:
- File type icon (color-coded)
- Title text
- Subject chip
- Topic chip
- Metadata (time, downloads, likes)
- Tap gesture

#### 2. SubjectChip
**Purpose**: Display subject tags  
**Features**:
- Icon
- Label
- Blue color scheme
- Tap gesture

#### 3. LoadingSkeleton
**Purpose**: Loading placeholder  
**Features**:
- Shimmer animation
- Card-shaped
- Configurable count
- Matches ResourceCard layout

#### 4. EmptyState
**Purpose**: Empty list feedback  
**Features**:
- Icon
- Message
- Optional action button

#### 5. Toast
**Purpose**: User feedback  
**Features**:
- Bottom position
- Auto-dismiss
- Success/Error variants

---

