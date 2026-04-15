# PRD: Study Resource Sharing Platform

## Problem Statement

Students struggle to find relevant study materials before exams, wasting time searching across multiple platforms (WhatsApp, Telegram, friends) without a centralized, structured way to access shared resources.

## Solution

A mobile and web platform where students can upload study resources (PDF, PPT) with subject and topic metadata, and quickly search/browse resources shared by other students. Reduces exam preparation stress by providing instant access to shared study materials.

## User Stories

1. As a student, I want to register with email and password, so that I can access the platform securely
2. As a registered student, I want to log in with my credentials, so that I can access my account
3. As a logged-in student, I want to log out, so that I can secure my account when using shared devices
4. As a logged-in student, I want to upload a PDF or PPT file, so that I can share study resources with other students
5. As a student uploading a resource, I want to provide a title, so that others can identify my resource
6. As a student uploading a resource, I want to specify a subject, so that resources can be categorized
7. As a student uploading a resource, I want to specify a topic within a subject, so that resources are more precisely discoverable
8. As a student uploading a resource, I want the subject and topic to be automatically added to searchable lists, so that future students can find them
9. As a student, I want to search by subject, so that I can see all available topics within that subject
10. As a student, I want to see all topics under a searched subject, so that I know what materials exist
11. As a student, I want to search by topic, so that I can find all files shared for that topic across all students
12. As a student, I want to see a list of resources for a topic, so that I can browse and choose what to study
13. As a student, I want to preview a PDF file within the app, so that I can quickly check if it's useful before downloading
14. As a student, I want to download a resource to my device, so that I can study offline
15. As a student, I want downloaded files to be stored locally, so that I can access them without internet
16. As a student, I want to open downloaded resources from local storage, so that I can study without re-downloading

## Implementation Decisions

- **Platform**: Flutter (Android, iOS, Web)
- **Authentication**: Firebase Authentication (email/password)
- **File Storage**: Firebase Storage (for uploaded PDF/PPT files)
- **Database**: MongoDB (connection via provided URI string)
- **Local Storage**: Hive Flutter (for caching downloaded files and offline access)
- **PDF Preview**: flutter_pdfview package
- **File Types**: PDF and PPT only (MVP scope)
- **No file size limit** for MVP

### Data Models

**Resource Document**
```
{
  _id: ObjectId,
  title: String,
  subject: String,
  topic: String,
  fileUrl: String,
  fileType: String (pdf/ppt),
  uploadedBy: String (userId),
  uploadedAt: DateTime
}
```

**Subject Collection** (for fast autocomplete/listing)
```
{
  _id: ObjectId,
  name: String (unique)
}
```

**Topic Collection** (for fast autocomplete/listing)
```
{
  _id: ObjectId,
  name: String,
  subject: String (foreign reference)
}
```

### Key Modules

1. **Resource Repository**: Handles CRUD operations for resources against MongoDB
2. **Subject/Topic Service**: Manages subject and topic collections, auto-creation on resource upload
3. **Search Service**: Queries resources by subject (returns topics) and by topic (returns resources)
4. **File Upload Service**: Uploads files to Firebase Storage
5. **Local Cache Service**: Manages Hive database for downloaded files
6. **PDF Preview Service**: Handles PDF rendering with flutter_pdfview

## Testing Decisions

- **Unit tests**: Repository methods, search logic, subject/topic auto-creation
- **Widget tests**: Upload form, search interface, resource list display
- **Integration tests**: Full upload flow, search-to-preview flow
- Tests should verify external behavior only (not internal implementation details)
- Similar test patterns exist in the codebase for auth repository

## Out of Scope

- User profiles or contribution tracking
- File editing or metadata updates after upload
- File deletion by owner
- Likes, comments, ratings
- Advanced search (full-text, filters)
- Graph database (Neo4j) integration
- Vector-based search
- OAuth providers (Google, etc.)
- DOCX, images, or other file types
- File size limits
- Social features

## Further Notes

- Subjects and topics are created dynamically when uploading (no admin panel needed)
- Search by subject returns aggregated topic list; search by topic returns all resource files for that topic
- Firebase Storage chosen for file hosting as it's free tier compatible and integrates with existing Firebase setup
- MongoDB chosen for flexible document storage and readiness for future graph database layer
