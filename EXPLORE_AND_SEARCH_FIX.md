# Explore Page and Search Functionality Fix

## Summary
Fixed the explore page to show only the current user's uploaded files from MongoDB, while ensuring the search functionality searches through ALL files uploaded by anyone.

## Changes Made

### Backend Changes (backend/main.py)

1. **Added New Endpoint: `/user/resources/`**
   - Returns only resources uploaded by the authenticated user
   - Requires Firebase authentication token
   - Filters resources by `firebase_uid`
   - Enriches results with subject and topic names
   - Sorts by creation date (newest first)

2. **Updated `/search/` Endpoint**
   - Changed sorting from `uploaded_at` to `created_at` for consistency
   - Continues to search ALL resources (not filtered by user)
   - Allows searching across all files uploaded by anyone

### Flutter Frontend Changes

#### 1. Auth Repository (lib/features/auth/data/auth_repository.dart)
- Added `getIdToken()` method to retrieve Firebase ID token for authenticated API calls

#### 2. Auth Controller (lib/features/auth/presentation/providers/auth_provider.dart)
- Added `getIdToken()` method to expose token retrieval to other parts of the app

#### 3. API Service (lib/core/services/api_service.dart)
- Added `getUserResources(String firebaseToken)` method
- Calls the new `/user/resources/` endpoint with authentication header
- Returns list of resources uploaded by the current user

#### 4. Search Provider (lib/features/home/presentation/providers/search_provider.dart)
- Added `userResourcesProvider` that fetches only the current user's resources
- Uses Firebase token for authentication
- Existing `searchResourcesProvider` continues to search ALL resources

#### 5. Home Screen (lib/features/home/presentation/screens/home_screen.dart)
- **Explore Tab Changes:**
  - Changed from `allResourcesProvider` to `userResourcesProvider`
  - Now shows only the current user's uploaded files
  - Updated title from "Recent uploads" to "My uploads"
  - Updated empty state message to encourage first upload
  - Updated refresh logic to invalidate `userResourcesProvider`

- **Search Tab:**
  - Continues to use `searchResourcesProvider`
  - Searches through ALL files uploaded by anyone
  - No changes needed - already working correctly

## How It Works Now

### Explore Tab (Tab 1)
- Shows only files uploaded by the currently logged-in user
- Fetches data from `/user/resources/` endpoint
- Requires authentication
- Filters by subject using chips
- Pull-to-refresh updates user's files
- Auto-refreshes when returning from Upload tab

### Search Tab (Tab 2)
- Searches through ALL files uploaded by anyone
- Fetches data from `/search/` endpoint
- No authentication required for search
- Filters by subject using chips
- Real-time search with 300ms debounce

## Testing Checklist

- [ ] Login with a user account
- [ ] Upload some files
- [ ] Verify Explore tab shows only your uploaded files
- [ ] Switch to Search tab
- [ ] Verify Search shows all files from all users
- [ ] Test subject filtering on both tabs
- [ ] Test pull-to-refresh on Explore tab
- [ ] Upload a new file and verify it appears in Explore tab
- [ ] Logout and login with different user
- [ ] Verify Explore tab shows different files for different users

## API Endpoints Summary

| Endpoint | Purpose | Authentication | Filters |
|----------|---------|----------------|---------|
| `/resources/` | Get all resources | No | None |
| `/user/resources/` | Get current user's resources | Yes (Bearer token) | By user |
| `/search/` | Search all resources | No | By query, subject, topic |
| `/topics/{topic_id}/resources/` | Get resources by topic | No | By topic |

## Notes

- The backend uses Firebase Admin SDK to verify tokens
- Token verification has a dev fallback for local testing
- All endpoints return enriched data with subject and topic names
- Resources are sorted by creation date (newest first)
- The search functionality remains global to allow users to discover content from others
