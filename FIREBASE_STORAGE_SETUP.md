# Firebase Storage Setup - CRITICAL STEPS

## Your Firebase Project
- **Project ID**: `noteflow-auth-project`
- **Storage Bucket**: `noteflow-auth-project.firebasestorage.app`

## STEP 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **noteflow-auth-project**
3. Click **Storage** in the left menu
4. If you see "Get Started", click it to enable Storage
5. Choose **Start in test mode** (we'll secure it later)
6. Click **Done**

## STEP 2: Set Storage Rules (CRITICAL!)

1. In Firebase Console → Storage
2. Click the **Rules** tab
3. Replace ALL content with this:

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

4. Click **Publish**
5. Wait for "Rules published successfully" message

## STEP 3: Set Firestore Rules

1. In Firebase Console → Firestore Database
2. Click the **Rules** tab
3. Replace ALL content with this:

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

4. Click **Publish**

## STEP 4: Verify Setup

### Check Storage is Enabled:
1. Go to Firebase Console → Storage
2. You should see the **Files** tab
3. You should see your bucket: `noteflow-auth-project.firebasestorage.app`

### Check Rules are Applied:
1. Storage → Rules tab
2. Should show: `allow read, write: if true;`
3. Status should be: **Published**

## STEP 5: Test Upload

1. Install the new APK: `build/app/outputs/flutter-apk/app-debug.apk`
2. Open the app
3. Go to Upload tab
4. Select a small PDF file
5. Fill in the form
6. Click Upload

### Check Logs:
You should see in logcat:
```
I/flutter: === STORAGE UPLOAD START ===
I/flutter: File: 1234567890_file.pdf
I/flutter: Size: 842400 bytes (0.80 MB)
I/flutter: Storage bucket: noteflow-auth-project.firebasestorage.app
I/flutter: Upload progress: 25.0%
I/flutter: Upload progress: 50.0%
I/flutter: Upload progress: 100.0%
I/flutter: === STORAGE UPLOAD SUCCESS ===
```

### Check Firebase Console:
1. Go to Storage → Files
2. You should see: `resources/{userId}/filename.pdf`
3. Click on it to verify it uploaded

## Common Errors and Solutions

### Error: "bucket-not-found"
**Solution**: Firebase Storage is not enabled
- Go to Firebase Console → Storage
- Click "Get Started" to enable it

### Error: "permission-denied" or "unauthorized"
**Solution**: Storage rules are blocking uploads
- Go to Storage → Rules
- Set to: `allow read, write: if true;`
- Click Publish

### Error: "unauthenticated"
**Solution**: User is not signed in
- Make sure you're logged into the app
- Check Firebase Console → Authentication → Users

### Error: "object-not-found"
**Solution**: Multiple possible causes
1. Storage not enabled → Enable it
2. Wrong bucket name → Check firebase_options.dart
3. Rules blocking → Update rules
4. Network issue → Check internet connection

## Verification Checklist

Before testing upload:
- [ ] Firebase Storage is enabled (can see Files tab)
- [ ] Storage rules set to `allow read, write: if true;`
- [ ] Firestore rules set to `allow read, write: if true;`
- [ ] Rules are published (green checkmark)
- [ ] User is signed in to the app
- [ ] Device has internet connection
- [ ] New APK is installed

## After Upload Works

Once uploads are working, you can secure the rules:

### Secure Storage Rules (with Profile Pictures):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Anyone can read
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Only authenticated users can upload to their resource folder
    match /resources/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Only authenticated users can upload their own profile picture
    match /profile_pictures/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Secure Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /resources/{resourceId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
        && resource.data.firebaseUid == request.auth.uid;
    }
    
    match /subjects/{subjectId} {
      allow read: if true;
    }
    
    match /topics/{topicId} {
      allow read: if true;
    }
  }
}
```

## Need Help?

If upload still fails after following all steps:
1. Share the logcat output (look for "=== STORAGE UPLOAD" lines)
2. Screenshot of Firebase Console → Storage → Files
3. Screenshot of Firebase Console → Storage → Rules
