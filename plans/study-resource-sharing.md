# Plan: Study Resource Sharing Platform

> Source PRD: docs/PRD.md

## Architectural decisions

- **Routes**:
  - `/home` - Main app shell with navigation
  - `/upload` - Resource upload screen
  - `/search` - Search/browse resources screen
  - `/downloads` - Locally downloaded resources
- **Schema**:
  - `resources` collection: title, subject, topic, fileUrl, fileType, uploadedBy, uploadedAt
  - `subjects` collection: name (unique)
  - `topics` collection: name, subject
- **Key models**: Resource, Subject, Topic, UploadState
- **Auth**: Firebase Auth (already implemented)
- **File Storage**: Firebase Storage
- **Database**: MongoDB (connection via URI)
- **Local Cache**: Hive Flutter

---

## Phase 1: Upload Foundation

**User stories**: 4, 5, 6, 7, 8

### What to build

Full upload flow: user picks PDF/PPT file → enters title, subject, topic → file uploads to Firebase Storage → metadata saved to MongoDB → subject/topic auto-created if new.

### Acceptance criteria

- [ ] User can pick PDF or PPT file from device
- [ ] User can enter title, subject, and topic
- [ ] File uploads to Firebase Storage successfully
- [ ] Resource metadata saved to MongoDB
- [ ] New subjects/topics created automatically
- [ ] Upload progress shown to user

---

## Phase 2: Subject/Topic Browse

**User stories**: 9, 10, 11, 12

### What to build

Search by subject shows all topics under it. Search by topic shows all resource files for that topic from all students.

### Acceptance criteria

- [ ] User can search/select a subject
- [ ] All topics under that subject are listed
- [ ] User can search for a specific topic
- [ ] All resources for a topic are displayed with title, uploader info
- [ ] User can tap to preview a resource

---

## Phase 3: Preview & Local Download

**User stories**: 13, 14, 15, 16

### What to build

PDF preview within app, download to local Hive storage, open from local cache without internet.

### Acceptance criteria

- [ ] PDF preview renders within app
- [ ] User can download resource to local storage
- [ ] Downloaded files persist across app restarts
- [ ] User can browse downloaded files offline
- [ ] User can open downloaded files from local cache

---

## Phase 4: Home Screen Integration

**User stories**: (connects all phases)

### What to build

Unified app shell with bottom navigation between Upload, Search, and Downloads tabs. Smooth routing and state management.

### Acceptance criteria

- [ ] Bottom navigation between main sections
- [ ] Upload screen accessible from nav
- [ ] Search screen accessible from nav
- [ ] Downloads screen accessible from nav
- [ ] Auth state persists across navigation
