# Profile Picture Feature - Testing Guide

## Quick Start

### Prerequisites
1. ✅ `image_picker` package installed (run `flutter pub get`)
2. ✅ Firebase Storage enabled in Firebase Console
3. ✅ Storage rules allow profile picture uploads
4. ✅ User is signed in to the app

### Test the Feature (5 minutes)

## Test 1: Pick Image from Gallery

1. **Open the app** and sign in
2. **Navigate to Profile tab** (bottom navigation)
3. **Tap "Edit Profile"** button
4. **Tap on the profile picture** (circular avatar at top)
5. **Dialog appears** with two options:
   - Gallery
   - Camera
6. **Select "Gallery"**
7. **Choose an image** from your device
8. **Image displays immediately** in the profile picture circle
9. **Tap "Save"** button (top right)
10. **Wait for upload** (should be quick for profile pictures)
11. **Success message appears**: "Profile updated successfully!"
12. **Navigate back** to Profile screen
13. **Verify**: Profile picture is now displayed

✅ **Expected Result**: Your selected image is now your profile picture

## Test 2: Take Photo with Camera

1. **Navigate to Edit Profile** screen
2. **Tap on the profile picture**
3. **Select "Camera"** from the dialog
4. **Take a photo** using your device camera
5. **Confirm the photo**
6. **Image displays immediately**
7. **Tap "Save"**
8. **Verify**: New photo is uploaded and displayed

✅ **Expected Result**: Camera photo becomes your profile picture

## Test 3: Cancel Image Selection

1. **Navigate to Edit Profile** screen
2. **Tap on the profile picture**
3. **Select "Gallery"** or "Camera"
4. **Press back/cancel** without selecting an image
5. **Verify**: Profile picture remains unchanged

✅ **Expected Result**: No changes made, original picture still displayed

## Test 4: Update Profile Picture Multiple Times

1. **Set a profile picture** (Test 1)
2. **Navigate back to Edit Profile**
3. **Verify**: Current profile picture is displayed
4. **Tap on profile picture** again
5. **Select a different image**
6. **Tap "Save"**
7. **Verify**: New image replaces the old one

✅ **Expected Result**: Profile picture updates successfully each time

## Test 5: Profile Picture Persists

1. **Set a profile picture**
2. **Close the app completely**
3. **Reopen the app**
4. **Navigate to Profile tab**
5. **Verify**: Profile picture is still displayed

✅ **Expected Result**: Profile picture persists after app restart

## Test 6: No Internet Connection

1. **Turn off WiFi and mobile data**
2. **Navigate to Edit Profile**
3. **Select a new profile picture**
4. **Tap "Save"**
5. **Verify**: Error message appears about upload failure

✅ **Expected Result**: User-friendly error message displayed

## Test 7: Profile Picture Display Locations

Check that profile picture displays in all these locations:

1. **Profile Screen**:
   - ✅ Large circular avatar at top of screen
   
2. **Edit Profile Screen**:
   - ✅ Circular avatar with camera icon overlay
   - ✅ Shows selected image before upload
   - ✅ Shows existing profile picture
   - ✅ Falls back to initials if no picture

✅ **Expected Result**: Profile picture displays consistently everywhere

## Visual Verification Checklist

### Profile Screen
```
┌─────────────────────────┐
│      Profile            │
├─────────────────────────┤
│                         │
│      ┌─────────┐        │
│      │  [IMG]  │        │  ← Profile picture displays here
│      └─────────┘        │
│                         │
│    John Doe             │
│    john@example.com     │
│    Member since Jan 2024│
│                         │
│  [Edit Profile Button]  │
│                         │
└─────────────────────────┘
```

### Edit Profile Screen
```
┌─────────────────────────┐
│  Edit Profile    [Save] │
├─────────────────────────┤
│                         │
│      ┌─────────┐        │
│      │  [IMG]  │ 📷     │  ← Tap to change picture
│      └─────────┘        │     Camera icon = clickable
│                         │
│  Display Name           │
│  [John Doe        ]     │
│                         │
│  Email                  │
│  [john@example.com]     │
│                         │
└─────────────────────────┘
```

### Image Source Dialog
```
┌─────────────────────────┐
│  Choose Image Source    │
├─────────────────────────┤
│                         │
│  📷  Gallery            │  ← Tap to open gallery
│                         │
│  📸  Camera             │  ← Tap to open camera
│                         │
└─────────────────────────┘
```

## Common Issues and Solutions

### Issue 1: "Failed to pick image" error
**Cause**: Permission denied or image picker error
**Solution**: 
- Check app permissions in device settings
- Grant camera and storage permissions
- Restart the app

### Issue 2: "Permission denied" during upload
**Cause**: Firebase Storage rules blocking upload
**Solution**:
- Go to Firebase Console → Storage → Rules
- Update rules to allow profile picture uploads (see FIREBASE_STORAGE_SETUP.md)
- Publish the rules

### Issue 3: Image doesn't display after upload
**Cause**: Network image loading issue or cache
**Solution**:
- Check internet connection
- Restart the app
- Verify image uploaded in Firebase Console → Storage → Files → profile_pictures

### Issue 4: Upload takes too long
**Cause**: Large image file or slow connection
**Solution**:
- Images are automatically compressed to 512x512 @ 85% quality
- Check internet connection speed
- Try a different image

### Issue 5: Profile picture shows initials instead of image
**Cause**: No profile picture set or failed to load
**Solution**:
- Upload a profile picture in Edit Profile
- Check Firebase Auth user profile has photoURL set
- Verify image URL is accessible

## Performance Expectations

- **Image Selection**: Instant (< 1 second)
- **Image Preview**: Instant (displays immediately)
- **Image Upload**: 1-3 seconds (for compressed 512x512 image)
- **Image Display**: 1-2 seconds (first load, then cached)

## Firebase Console Verification

### Check Upload Success:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **noteflow-auth-project**
3. Click **Storage** → **Files**
4. Navigate to: `profile_pictures/{userId}/profile.jpg`
5. Click on the file to see details
6. Verify:
   - ✅ File exists
   - ✅ Size is reasonable (< 100 KB typically)
   - ✅ Content type is `image/jpeg`
   - ✅ Download URL is accessible

### Check User Profile:
1. Go to Firebase Console → **Authentication** → **Users**
2. Find your user
3. Check **Photo URL** field
4. Should contain: `https://firebasestorage.googleapis.com/...`

## Automated Testing (Optional)

If you want to write automated tests:

```dart
// Test image picker
testWidgets('Profile picture picker opens on tap', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byIcon(Icons.camera_alt));
  await tester.pumpAndSettle();
  expect(find.text('Choose Image Source'), findsOneWidget);
});

// Test image display
testWidgets('Profile picture displays when URL is set', (tester) async {
  // Mock user with photoURL
  // Verify NetworkImage is displayed
});
```

## Success Criteria

✅ All tests pass
✅ Profile picture uploads successfully
✅ Profile picture displays in all locations
✅ Image persists after app restart
✅ Error handling works correctly
✅ Performance is acceptable (< 3 seconds upload)

## Next Steps After Testing

1. ✅ Test on physical device (not just emulator)
2. ✅ Test with different image sizes and formats
3. ✅ Test with poor network conditions
4. ✅ Verify Firebase Storage rules are secure
5. ✅ Monitor Firebase Storage usage and costs
6. ✅ Consider adding image cropping feature (future enhancement)

## Support

If you encounter issues:
1. Check the logs for error messages
2. Verify Firebase Storage is enabled
3. Check Firebase Storage rules
4. Review PROFILE_PICTURE_IMPLEMENTATION.md for details
5. Check FIREBASE_STORAGE_SETUP.md for setup instructions

---

**Feature Status**: ✅ Ready for Testing
**Last Updated**: 2026-05-01
