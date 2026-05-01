# Firebase Setup Guide for NoteFlow

## Current Issue
Upload is failing with error: `[firebase_storage/object-not-found] No object exists at the desired reference.`

This typically means Firebase Storage rules are blocking the upload or Firebase isn't properly configured.

## Required Firebase Configuration

### 1. Firebase Storage Rules

Your Firebase Storage rules must allow authenticated users to upload files. 

**Go to Firebase Console → Storage → Rules**

Replace with these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow anyone to read files
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Allow authenticated users to upload to their own folder
    match /resources/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**OR for testing, use permissive rules (NOT for production):**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### 2. Firestore Rules

Your Firestore rules must allow authenticated users to create documents.

**Go to Firebase Console → Firestore Database → Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Subjects collection - read only
    match /subjects/{subjectId} {
      allow read: if true;
      allow write: if false; // Only admins should create subjects
    }
    
    // Topics collection - read only
    match /topics/{topicId} {
      allow read: if true;
      allow write: if false; // Only admins should create topics
    }
    
    // Resources collection
    match /resources/{resourceId} {
      // Anyone can read
      allow read: if true;
      
      // Authenticated users can create
      allow create: if request.auth != null
                    && request.resource.data.firebaseUid == request.auth.uid;
      
      // Only owner can update/delete
      allow update, delete: if request.auth != null 
                            && resource.data.firebaseUid == request.auth.uid;
    }
  }
}
```

**OR for testing, use permissive rules (NOT for production):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 3. Firebase Authentication

Ensure Firebase Authentication is enabled:

**Go to Firebase Console → Authentication → Sign-in method**

- Enable **Email/Password** authentication
- Ensure users can sign up and sign in

### 4. Check Firebase Project Configuration

Verify your `android/app/google-services.json` file is present and up-to-date:

1. Go to Firebase Console → Project Settings
2. Download the latest `google-services.json`
3. Replace the file in `android/app/google-services.json`

### 5. Verify Firebase Initialization

Check that Firebase is properly initialized in your app. The `lib/main.dart` should have:

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

## Upload Flow

### Current Implementation:

1. **User selects file** → File picker gets bytes
2. **User fills form** → Title, Subject, Topic
3. **User clicks Upload** → Triggers upload process
4. **Upload to Storage** (10-85% progress)
   - Path: `resources/{userId}/{timestamp_filename.pdf}`
   - Returns download URL
5. **Save to Firestore** (85-100% progress)
   - Collection: `resources`
   - Document with metadata

### Expected Firestore Document Structure:

```json
{
  "title": "Random Processes",
  "subjectId": "math",
  "topicId": "math_stats",
  "firebaseUid": "user-firebase-uid",
  "uploadedBy": "user-firebase-uid",
  "fileId": "https://firebasestorage.googleapis.com/...",
  "fileName": "1234567890_SC-202-ENGG-MATHS.pdf",
  "contentType": "application/pdf",
  "size": 842400,
  "likes": 0,
  "downloads": 0,
  "uploadedAt": Timestamp
}
```

### Expected Storage Structure:

```
gs://your-bucket/
  └── resources/
      └── {userId}/
          ├── 1234567890_SC-202-ENGG-MATHS.pdf
          ├── 1234567891_Assignment.pdf
          └── ...
```

## Debugging Steps

### 1. Check Firebase Console

**Storage:**
- Go to Firebase Console → Storage
- Check if any files are being uploaded
- Check the "Usage" tab to see if uploads are happening

**Firestore:**
- Go to Firebase Console → Firestore Database
- Check if `resources` collection exists
- Check if documents are being created

### 2. Check Logs

The updated code now includes detailed logging. Check the logcat output for:

```
StorageService: Starting upload for...
StorageService: File size: ...
StorageService: Upload path: ...
StorageService: Upload progress: ...
StorageService: Upload completed...
StorageService: Download URL obtained: ...
```

If you see errors like:
- `Permission denied` → Fix Storage/Firestore rules
- `Network error` → Check internet connection
- `Invalid argument` → Check file bytes are valid

### 3. Test with Permissive Rules

Temporarily set both Storage and Firestore rules to allow all reads/writes:

```javascript
// Storage
allow read, write: if true;

// Firestore
allow read, write: if true;
```

If upload works with permissive rules, the issue is with your security rules.

### 4. Check User Authentication

Ensure the user is properly authenticated:

```dart
final user = FirebaseAuth.instance.currentUser;
print('User: ${user?.uid}');
print('Email: ${user?.email}');
```

## Common Issues and Solutions

### Issue 1: "object-not-found" Error
**Cause:** File wasn't uploaded to Storage
**Solutions:**
- Check Storage rules allow write access
- Verify user is authenticated
- Check internet connection
- Verify Firebase Storage is enabled in console

### Issue 2: "Permission Denied" Error
**Cause:** Security rules blocking the operation
**Solutions:**
- Update Storage rules to allow authenticated writes
- Update Firestore rules to allow authenticated creates
- Verify user is signed in

### Issue 3: Upload Progress Stuck
**Cause:** Network issue or large file
**Solutions:**
- Check internet connection
- Try smaller file
- Check file size limit (200MB max)

### Issue 4: Firestore Document Not Created
**Cause:** Firestore rules or network issue
**Solutions:**
- Check Firestore rules allow create
- Verify Firestore is enabled
- Check logs for specific error

## Testing Checklist

- [ ] Firebase Storage rules allow authenticated writes
- [ ] Firestore rules allow authenticated creates
- [ ] User is signed in (check with `FirebaseAuth.instance.currentUser`)
- [ ] Internet connection is active
- [ ] `google-services.json` is up-to-date
- [ ] Firebase is initialized in `main.dart`
- [ ] File size is under 200MB
- [ ] File type is PDF or PPT/PPTX

## Next Steps

1. **Apply the permissive rules** (for testing)
2. **Rebuild and install** the app
3. **Try uploading** a small PDF file
4. **Check logcat** for detailed error messages
5. **Check Firebase Console** to see if file appears in Storage
6. **Once working**, apply proper security rules
