# Upload Screen Dropdown Update

## Summary
Replaced the buffering autocomplete fields with static dropdown lists for subjects and topics in the upload screen. This provides a faster, more reliable user experience without needing to fetch data from the backend.

## Changes Made

### File: `lib/features/upload/presentation/screens/upload_screen.dart`

#### 1. Removed Backend Dependencies
- Removed imports for `ApiService`, `Subject`, and `Topic` models
- Removed `_loadSubjects()` and `_loadTopics()` methods
- Removed `_subjects` and `_topics` state variables
- Removed `_subjectController` (no longer needed)

#### 2. Added Static Data
Created predefined lists for subjects and topics:

**Subjects:**
- Computer Science
- Mathematics
- Physics
- Chemistry

**Topics by Subject:**

**Computer Science:**
- Data Structures & Algorithms
- Object-Oriented Programming
- Database Management
- Operating Systems
- Computer Networks
- Web Development
- Artificial Intelligence
- Machine Learning

**Mathematics:**
- Calculus
- Linear Algebra
- Statistics
- Discrete Mathematics
- Differential Equations

**Physics:**
- Mechanics
- Thermodynamics
- Electromagnetism
- Optics
- Quantum Physics

**Chemistry:**
- Organic Chemistry
- Inorganic Chemistry
- Physical Chemistry
- Analytical Chemistry

#### 3. Replaced Autocomplete with Dropdowns

**Subject Field:**
- Changed from `Autocomplete<Subject>` to `DropdownButtonFormField<String>`
- No loading spinner needed
- Instant selection
- Clean, simple UI

**Topic Field:**
- Changed from `Autocomplete<Topic>` to `DropdownButtonFormField<String>`
- Dynamically shows topics based on selected subject
- Disabled until subject is selected
- No loading spinner needed

## Benefits

✅ **No buffering** - Instant dropdown display
✅ **No network calls** - All data is local
✅ **Better UX** - Faster and more responsive
✅ **Simpler code** - Removed complex autocomplete logic
✅ **Reliable** - No dependency on backend availability

## User Experience

1. User opens Upload screen
2. Selects a file (PDF/PPT)
3. Enters a title
4. Selects subject from dropdown (4 options)
5. Selects topic from dropdown (filtered by subject)
6. Uploads the resource

## Future Enhancements

When ready to add dynamic features:
1. Fetch subjects/topics from Firestore
2. Allow users to add custom subjects/topics
3. Add search functionality within dropdowns
4. Sync with backend for consistency

## Testing

To test the changes:
1. Install the APK: `build/app/outputs/flutter-apk/app-debug.apk`
2. Navigate to Upload tab
3. Verify subject dropdown shows 4 subjects
4. Select a subject
5. Verify topic dropdown shows relevant topics
6. Complete upload flow

## Data Structure

The static data uses simple Maps:

```dart
// Subjects
{'id': 'cs', 'name': 'Computer Science'}

// Topics
{'id': 'cs_dsa', 'name': 'Data Structures & Algorithms'}
```

IDs are used for backend storage, names are displayed to users.
