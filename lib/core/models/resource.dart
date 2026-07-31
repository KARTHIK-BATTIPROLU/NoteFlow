class Resource {
  final String id;
  final String title;
  final String subjectId;
  final String topicId;
  final String firebaseUid;
  final String? storageKey;
  final String fileId;
  final String fileName;
  final String contentType;
  final int size;
  final String? sha256;
  final int likes;
  final int downloads;
  final DateTime uploadedAt;
  final String? subjectName;
  final String? topicName;
  final String? uploaderHandle;

  Resource({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.topicId,
    required this.firebaseUid,
    this.storageKey,
    required this.fileId,
    required this.fileName,
    required this.contentType,
    required this.size,
    this.sha256,
    required this.likes,
    required this.downloads,
    required this.uploadedAt,
    this.subjectName,
    this.topicName,
    this.uploaderHandle,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
      return DateTime.now();
    }

    final key = json['storage_key'] ?? json['file_id'] ?? json['fileId'] ?? '';

    return Resource(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      subjectId: json['subject'] ?? json['subjectId'] ?? '',
      topicId: json['topic'] ?? json['topicId'] ?? '',
      firebaseUid: json['firebase_uid'] ?? json['firebaseUid'] ?? '',
      storageKey: json['storage_key'],
      fileId: key,
      fileName: json['file_name'] ?? json['fileName'] ?? 'unknown',
      contentType: json['content_type'] ?? json['contentType'] ?? 'application/octet-stream',
      size: json['size'] ?? 0,
      sha256: json['sha256'],
      likes: json['likes'] ?? 0,
      downloads: json['downloads'] ?? 0,
      uploadedAt: parseDate(json['created_at'] ?? json['uploaded_at'] ?? json['uploadedAt']),
      subjectName: json['subject_name'] ?? json['subjectName'],
      topicName: json['topic_name'] ?? json['topicName'],
      uploaderHandle: json['uploader_handle'] ?? json['uploaderHandle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subjectId,
      'topic': topicId,
      'firebase_uid': firebaseUid,
      'storage_key': storageKey,
      'file_id': fileId,
      'file_name': fileName,
      'content_type': contentType,
      'size': size,
      'sha256': sha256,
      'likes': likes,
      'downloads': downloads,
      'created_at': uploadedAt.toIso8601String(),
      'subject_name': subjectName,
      'topic_name': topicName,
      'uploader_handle': uploaderHandle,
    };
  }

  String get fileType {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    if (contentType == 'application/pdf') return 'pdf';
    if (contentType == 'application/vnd.ms-powerpoint' ||
        contentType == 'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
      return 'ppt';
    }
    return 'unknown';
  }
}
