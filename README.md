# NoteFlow - Educational Resource Management System

A comprehensive Flutter application with FastAPI backend for managing and sharing educational resources (PDFs, presentations) with MongoDB integration.

## 🎯 Features

### ✅ Implemented Features

- **MongoDB Collections**: Automatic creation and initialization of subjects, topics, and resources collections
- **File Upload**: Upload PDFs and presentations to Firebase Storage with metadata stored in MongoDB
- **Enhanced Search**: Beautiful card-based search interface with real-time filtering
- **PDF Preview**: In-app PDF viewer with swipe navigation and file caching
- **Subject & Topic Management**: Organize resources by subjects and topics
- **User Authentication**: Firebase Authentication integration
- **Offline Support**: Local caching of downloaded files
- **Responsive UI**: Material Design with custom cards and chips

### 🎨 UI Highlights

- **Card View**: Resources displayed as beautiful cards with:
  - Color-coded file type icons (PDF, PPT)
  - Title and relative upload time
  - Subject and topic chips with icons
  - Tap to preview functionality
  
- **Search Interface**:
  - Real-time search as you type
  - Clear button for quick reset
  - Empty state messages
  - Loading indicators

- **PDF Viewer**:
  - Full-screen preview
  - Horizontal swipe navigation
  - Custom title bar
  - Automatic file caching

## 📁 Project Structure

```
noteflow/
├── backend/                    # FastAPI Backend
│   ├── main.py                # API endpoints
│   ├── models.py              # Pydantic models
│   ├── database.py            # MongoDB connection
│   ├── init_db.py             # Database initialization script
│   ├── requirements.txt       # Python dependencies
│   ├── start.sh               # Linux/Mac startup script
│   ├── start.bat              # Windows startup script
│   └── SETUP.md               # Backend setup guide
│
├── lib/                       # Flutter Application
│   ├── core/
│   │   ├── models/            # Data models
│   │   ├── services/          # API services
│   │   ├── router/            # Navigation
│   │   └── database/          # Local storage
│   ├── features/
│   │   ├── auth/              # Authentication
│   │   ├── home/              # Main screens
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── search_screen.dart      # ✨ Enhanced search
│   │   │       │   └── pdf_viewer_screen.dart  # ✨ PDF preview
│   │   │       └── providers/
│   │   └── upload/            # File upload
│   └── main.dart
│
├── FLUTTER_SETUP.md           # Flutter setup guide
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites

- **Backend**:
  - Python 3.8+
  - MongoDB (local or MongoDB Atlas)
  - pip

- **Frontend**:
  - Flutter SDK 3.9.2+
  - Firebase project configured
  - Android Studio / Xcode

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Set MongoDB URL (optional)**:
   ```bash
   # For local MongoDB (default)
   export MONGODB_URL="mongodb://localhost:27017/"
   
   # For MongoDB Atlas
   export MONGODB_URL="mongodb+srv://username:password@cluster.mongodb.net/"
   ```

4. **Initialize database**:
   ```bash
   python init_db.py
   ```

5. **Start the server**:
   ```bash
   # Linux/Mac
   ./start.sh
   
   # Windows
   start.bat
   
   # Or manually
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

   The API will be available at:
   - Local: http://localhost:8000
   - API Docs: http://localhost:8000/docs

### Flutter Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:
   - Ensure `firebase_options.dart` is configured
   - Enable Firebase Storage and Authentication

3. **Run the app**:
   ```bash
   flutter run
   ```

For detailed setup instructions, see [FLUTTER_SETUP.md](FLUTTER_SETUP.md)

## 📚 API Documentation

### Endpoints

#### Subjects
- `GET /subjects/` - Get all subjects
- `POST /subjects/` - Create a new subject

#### Topics
- `GET /subjects/{subject_id}/topics/` - Get topics for a subject
- `POST /topics/` - Create a new topic

#### Resources
- `GET /resources/` - Get all resources
- `GET /topics/{topic_id}/resources/` - Get resources for a topic
- `POST /resources/` - Upload a new resource

#### Search (✨ New)
- `GET /search/?q={query}` - Search resources by title
- `GET /search/?q={query}&subject={id}` - Search with subject filter
- `GET /search/?q={query}&topic={id}` - Search with topic filter

### MongoDB Collections

#### subjects
```json
{
  "_id": "ObjectId",
  "name": "Mathematics"
}
```

#### topics
```json
{
  "_id": "ObjectId",
  "name": "Calculus",
  "subject": "subject_id"
}
```

#### resources
```json
{
  "_id": "ObjectId",
  "title": "Introduction to Calculus",
  "subject": "subject_id",
  "topic": "topic_id",
  "file_url": "https://...",
  "file_type": "application/pdf",
  "uploaded_by": "user@example.com",
  "uploaded_at": "2024-01-01T00:00:00Z"
}
```

## 🎯 How to Use

### 1. Initialize Backend
```bash
cd backend
python init_db.py  # Creates collections and adds sample data
uvicorn main:app --reload
```

### 2. Run Flutter App
```bash
flutter run
```

### 3. Upload Resources
1. Go to **Upload** tab
2. Enter title, subject ID, and topic ID
3. Select a PDF/PPT file
4. Click **Upload**

### 4. Search and Preview
1. Go to **Search** tab
2. Type to search by title
3. Click any card to preview the PDF
4. Swipe to navigate through pages

## 🔧 Configuration

### Backend Configuration

**MongoDB URL**: Set via environment variable
```bash
export MONGODB_URL="mongodb://localhost:27017/"
```

**Server Port**: Default is 8000, change in startup command
```bash
uvicorn main:app --reload --port 8001
```

### Flutter Configuration

**API Base URL**: Auto-detected by platform in `lib/core/services/api_service.dart`
- Android Emulator: `http://10.0.2.2:8000`
- iOS/Web: `http://localhost:8000`

## 🐛 Troubleshooting

### Backend Issues

**MongoDB Connection Failed**:
- Ensure MongoDB is running: `sudo systemctl start mongod`
- Check connection URL
- Verify firewall settings

**Port Already in Use**:
```bash
uvicorn main:app --reload --port 8001
```

### Flutter Issues

**Backend Connection Failed**:
- Verify backend is running
- Check API URL in `api_service.dart`
- For Android emulator, use `10.0.2.2` not `localhost`

**PDF Preview Not Working**:
- Check internet connection
- Verify Firebase Storage permissions
- Ensure file is a valid PDF

**Search Not Working**:
- Verify backend `/search/` endpoint
- Check MongoDB has data
- Run `python init_db.py` for sample data

## 📖 Documentation

- [Backend Setup Guide](backend/SETUP.md)
- [Flutter Setup Guide](FLUTTER_SETUP.md)
- [API Documentation](http://localhost:8000/docs) (when server is running)

## 🛠️ Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **MongoDB**: NoSQL database with Motor async driver
- **Pydantic**: Data validation
- **Uvicorn**: ASGI server

### Frontend
- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management
- **GoRouter**: Navigation
- **Firebase**: Authentication & Storage
- **flutter_pdfview**: PDF rendering
- **Hive**: Local database

## 🎨 Screenshots

### Search Screen
- Card-based layout with file icons
- Subject and topic chips
- Real-time search filtering
- Relative time display

### PDF Viewer
- Full-screen preview
- Swipe navigation
- Custom title bar
- Loading indicators

## 🚧 Future Enhancements

- [ ] Advanced filters (by subject, topic, date)
- [ ] Sorting options (newest, oldest, alphabetical)
- [ ] Favorites/bookmarks
- [ ] Download progress indicator
- [ ] Offline mode
- [ ] Share functionality
- [ ] Comments and ratings
- [ ] Full-text search in PDF content
- [ ] Batch upload
- [ ] Admin dashboard

## 📝 License

This project is for educational purposes.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For issues or questions:
1. Check the documentation in `backend/SETUP.md` and `FLUTTER_SETUP.md`
2. Review API docs at `/docs` endpoint
3. Check backend logs: `uvicorn main:app --log-level debug`
4. Check Flutter logs: `flutter run -v`

---

Made with ❤️ for education
