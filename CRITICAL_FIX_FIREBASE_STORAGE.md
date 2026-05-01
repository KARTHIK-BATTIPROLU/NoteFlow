# CRITICAL: Firebase Storage Not Enabled

## The Problem

Your app shows: **"Storage bucket not found. Please check Firebase configuration."**

This means **Firebase Storage is NOT enabled** in your Firebase Console.

## The Solution (2 Minutes)

### Step 1: Go to Firebase Console
https://console.firebase.google.com/project/noteflow-auth-project/storage

### Step 2: Enable Storage

You will see one of two things:

#### Option A: "Get Started" Button
If you see a "Get Started" button:
1. Click **"Get Started"**
2. Click **"Next"** (accept default location)
3. Click **"Done"**

#### Option B: Storage Already Enabled
If you see the "Files" tab, Storage is already enabled.

### Step 3: Set Rules

1. Click the **"Rules"** tab
2. Delete everything
3. Paste this:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

4. Click **"Publish"**

### Step 4: Verify

1. Go back to "Files" tab
2. You should see your bucket: `noteflow-auth-project.firebasestorage.app`
3. Status should be "Active"

## Why This Happens

Firebase Storage is a **separate service** that must be explicitly enabled. Just having Firebase Auth and Firestore doesn't automatically enable Storage.

## After Enabling

1. **Restart the app** (close and reopen)
2. **Try uploading** again
3. **Check Firebase Console → Storage → Files** to see your uploaded file

## If It Still Doesn't Work

Check these:

### 1. User is Signed In
```
Go to Profile tab → Should show your email
```

### 2. Internet Connection
```
Check WiFi/mobile data is working
```

### 3. Firebase Rules
```
Make sure rules allow authenticated writes
```

### 4. Check Logs
```
adb logcat | grep "flutter"
```

Look for:
- `=== STORAGE UPLOAD START ===`
- Any error messages

## Common Errors After Enabling

### "Permission Denied"
**Fix**: Update Storage rules (see Step 3 above)

### "Unauthenticated"
**Fix**: Sign out and sign in again

### "Network Error"
**Fix**: Check internet connection

## Quick Test

After enabling Storage, try uploading a small PDF (< 1 MB) first to verify it works.

## Visual Guide

### Before Enabling:
```
Firebase Console → Storage
┌─────────────────────────────┐
│                             │
│    [Get Started Button]     │
│                             │
└─────────────────────────────┘
```

### After Enabling:
```
Firebase Console → Storage
┌─────────────────────────────┐
│ Files | Rules | Usage       │
├─────────────────────────────┤
│ Bucket: noteflow-auth...    │
│ Status: Active              │
│                             │
│ (Empty - no files yet)      │
└─────────────────────────────┘
```

### After First Upload:
```
Firebase Console → Storage → Files
┌─────────────────────────────┐
│ resources/                  │
│   └─ user123/               │
│       └─ 1234567890_file.pdf│
└─────────────────────────────┘
```

## Checklist

Before trying upload again:

- [ ] Firebase Storage enabled (see "Files" tab)
- [ ] Storage rules published
- [ ] User is signed in (check Profile tab)
- [ ] Internet connection active
- [ ] App restarted after enabling Storage

## Expected Behavior After Fix

1. Select file → ✅ File selected
2. Fill form → ✅ Form filled
3. Click Upload → ✅ Progress bar shows
4. Upload completes → ✅ Success message
5. Check Firebase Console → ✅ File appears in Storage
6. Check Firestore → ✅ Document created in `resources` collection

## Need Help?

If upload still fails after enabling Storage:
1. Share screenshot of Firebase Console → Storage page
2. Share logcat output: `adb logcat | grep "flutter"`
3. Share the exact error message shown in app
