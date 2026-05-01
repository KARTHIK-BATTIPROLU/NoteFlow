# Firebase Upload Fix

## Problem
The upload functionality was trying to connect to a backend server at `192.168.0.16:8000/upload` which wasn't running, causing "Software caused connection abort" errors.

## Solution
Updated the upload process to use Firebase Storage and Firestore directly, eliminating the need for a backend server.

## Changes Made

### File: `lib/core/services/api_service.dart`

#### Updated `uploadResource()` Method

**Before:**
- Used HTTP multipart request to backend server
- Required backend server running at `192.168.0.16:8000`
- Single-step upload process

**After:**
- Uses Firebase Storage for file upload
- Uses Firestore for metadata storage
- Two-step process with detailed progress tracking

#### New Upload Flow:

1. **Upload File to Firebase Storage (0-80% progress)**
   - Uploads file bytes to `resources/{userId}/{fileName}`
   - Sets appropriate content type (PDF, PPT, etc.)
   - Returns download URL

2. **Save Metadata to Firestore (80-100% progress)**
   - Creates document in `resources` collection
   - Stores all resource metadata
   - Returns created Resource object

#### Metadata Stored in Firestore:

```dart
{
  'title': 'Resource Title',
  'subjectId': 'cs',
  'topicId': 'cs_web',
  'firebaseUid': 'user-id',
  'uploadedBy': 'user-id',
  'fileId': 'https://storage.googleapis.com/...',
  'fileName': 'file.pdf',
  'contentType': 'application/pdf',
  'size': 90200,
  'likes': 0,
  'downloads': 0,
  'uploadedAt': Timestamp
}
```

### Added Imports:
- `cloud_firestore/cloud_firestore.dart`
- `firebase_storage/firebase_storage.dart`
- `storage_service.dart`

### Removed Dependencies:
- `http_parser` (no longer needed for multipart uploads)

## Progress Tracking

The upload now provides accurate progress feedback:

- **0-80%**: File upload to Firebase Storage
- **85%**: File uploaded successfully
- **90%**: Saving metadata to Firestore
- **100%**: Upload complete

## Benefits

✅ **No backend required** - Direct Firebase integration
✅ **Better progress tracking** - Real-time upload progress
✅ **More reliable** - Uses Firebase's robust infrastructure
✅ **Scalable** - Firebase handles all file storage and serving
✅ **Secure** - Firebase Security Rules can control access
✅ **Cost-effective** - No need to maintain backend server

## Firebase Storage Structure

```
resources/
  └── {userId}/
      ├── 1234567890_Assignment-2.pdf
      ├── 1234567891_Lecture-Notes.pdf
      └── ...
```

## Firestore Structure

```
resources/ (collection)
  └── {auto-generated-id}/ (document)
      ├── title: "Java Strings"
      ├── subjectId: "cs"
      ├── topicId: "cs_web"
      ├── firebaseUid: "user123"
      ├── uploadedBy: "user123"
      ├── fileId: "https://storage.googleapis.com/..."
      ├── fileName: "Assignment-2.pdf"
      ├── contentType: "application/pdf"
      ├── size: 90200
      ├── likes: 0
      ├── downloads: 0
      └── uploadedAt: Timestamp
```

## Testing

To test the upload functionality:

1. **Install the APK**: `build/app/outputs/flutter-apk/app-debug.apk`
2. **Navigate to Upload tab**
3. **Select a PDF or PPT file**
4. **Fill in the form**:
   - Title: "Test Upload"
   - Subject: "Computer Science"
   - Topic: "Web Development"
5. **Click "Upload Resource"**
6. **Watch progress bar** (should show 0-100%)
7. **Success message** should appear
8. **Check Firestore** console to verify document created
9. **Check Firebase Storage** to verify file uploaded

## Error Handling

The upload now properly handles errors:
- File selection errors
- Storage upload errors
- Firestore write errors
- Network connectivity issues

All errors are caught and displayed to the user with meaningful messages.

## Next Steps

1. **Add Firebase Security Rules** for Storage and Firestore
2. **Implement file size limits** (e.g., max 10MB)
3. **Add file type validation** on the server side
4. **Implement duplicate detection**
5. **Add thumbnail generation** for PDFs
6. **Track upload analytics**

## Security Considerations

### Firebase Storage Rules (Recommended):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /resources/{userId}/{fileName} {
      // Allow authenticated users to upload to their own folder
      allow write: if request.auth != null && request.auth.uid == userId;
      // Allow anyone to read
      allow read: if true;
    }
  }
}
```

### Firestore Rules (Recommended):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /resources/{resourceId} {
      // Allow authenticated users to create
      allow create: if request.auth != null;
      // Allow anyone to read
      allow read: if true;
      // Only owner can update/delete
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.firebaseUid;
    }
  }
}
```
