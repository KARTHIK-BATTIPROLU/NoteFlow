# NoteFlow Backend Setup Guide

## Prerequisites

- Python 3.8+
- MongoDB (local or cloud instance like MongoDB Atlas)
- pip (Python package manager)

## Installation Steps

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure MongoDB Connection

Set the MongoDB connection URL as an environment variable (optional):

```bash
# For local MongoDB (default)
export MONGODB_URL="mongodb://localhost:27017/"

# For MongoDB Atlas or remote instance
export MONGODB_URL="mongodb+srv://username:password@cluster.mongodb.net/"
```

If not set, it defaults to `mongodb://localhost:27017/`

### 3. Initialize Database Collections

Run the initialization script to create collections and add sample data:

```bash
python init_db.py
```

This will:
- Create `subjects`, `topics`, and `resources` collections
- Set up indexes for better search performance
- Add sample subjects and topics (if database is empty)

### 4. Start the Backend Server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- Local: `http://localhost:8000`
- Android Emulator: `http://10.0.2.2:8000`

### 5. Verify Installation

Open your browser and navigate to:
- API Root: `http://localhost:8000/`
- API Docs: `http://localhost:8000/docs`

## API Endpoints

### Subjects
- `GET /subjects/` - Get all subjects
- `POST /subjects/` - Create a new subject

### Topics
- `GET /subjects/{subject_id}/topics/` - Get topics for a subject
- `POST /topics/` - Create a new topic

### Resources
- `GET /resources/` - Get all resources
- `GET /topics/{topic_id}/resources/` - Get resources for a topic
- `POST /resources/` - Upload a new resource
- `GET /search/?q={query}` - Search resources by title

### Search Parameters
- `q` - Search query (searches in title)
- `subject` - Filter by subject ID
- `topic` - Filter by topic ID

Example: `GET /search/?q=calculus&subject=123`

## MongoDB Collections Structure

### subjects
```json
{
  "_id": "ObjectId",
  "name": "Mathematics"
}
```

### topics
```json
{
  "_id": "ObjectId",
  "name": "Calculus",
  "subject": "subject_id"
}
```

### resources
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

## Troubleshooting

### MongoDB Connection Issues

1. **Local MongoDB not running:**
   ```bash
   # Start MongoDB service
   sudo systemctl start mongod  # Linux
   brew services start mongodb-community  # macOS
   ```

2. **Connection refused:**
   - Check if MongoDB is running on port 27017
   - Verify firewall settings

3. **Authentication failed:**
   - Update MONGODB_URL with correct credentials
   - Check MongoDB user permissions

### Port Already in Use

If port 8000 is already in use:
```bash
uvicorn main:app --reload --port 8001
```

Don't forget to update the Flutter app's API URL accordingly.

## Development Tips

- Use MongoDB Compass for visual database management
- Check API documentation at `/docs` for interactive testing
- Monitor logs for debugging: `uvicorn main:app --log-level debug`
