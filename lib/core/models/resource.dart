class Resource {
  final String id;
  final String title;
  final String subjectId;
  final String topicId;
  final String firebaseUid;
  final String fileId;
  final String fileName;
  final String contentType;
  final int size;
  final int likes;
  final int downloads;
  final DateTime uploadedAt;
  final String? subjectName;
  final String? topicName;
  final String? description;
  final String? uploadedBy;

  Resource({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.topicId,
    required this.firebaseUid,
    required this.fileId,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.likes,
    required this.downloads,
    required this.uploadedAt,
    this.subjectName,
    this.topicName,
    this.description,
    this.uploadedBy,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    // Handle both backend format and Firestore format
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      // Firestore Timestamp
      if (dateValue is Map && dateValue.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue['_seconds'] * 1000);
      }
      return DateTime.now();
    }

    return Resource(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      subjectId: json['subject'] ?? json['subjectId'] ?? '',
      topicId: json['topic'] ?? json['topicId'] ?? '',
      firebaseUid: json['firebase_uid'] ?? json['firebaseUid'] ?? '',
      fileId: json['file_id'] ?? json['fileId'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? 'unknown',
      contentType: json['content_type'] ?? json['contentType'] ?? 'application/octet-stream',
      size: json['size'] ?? 0,
      likes: json['likes'] ?? 0,
      downloads: json['downloads'] ?? 0,
      uploadedAt: parseDate(json['uploaded_at'] ?? json['uploadedAt'] ?? json['created_at']),
      subjectName: json['subject_name'] ?? json['subjectName'],
      topicName: json['topic_name'] ?? json['topicName'],
      description: json['description'],
      uploadedBy: json['uploaded_by'] ?? json['uploadedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subjectId,
      'topic': topicId,
      'firebase_uid': firebaseUid,
      'file_id': fileId,
      'file_name': fileName,
      'content_type': contentType,
      'size': size,
      'likes': likes,
      'downloads': downloads,
      'created_at': uploadedAt.toIso8601String(),
      'subject_name': subjectName,
      'topic_name': topicName,
      'description': description,
      'uploaded_by': uploadedBy,
    };
  }
  
  String get downloadUrl {
    return fileId;
  }
  
  String get fileType {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    if (contentType == 'application/pdf') return 'pdf';
    if (contentType == 'application/vnd.ms-powerpoint' || contentType == 'application/vnd.openxmlformats-officedocument.presentationml.presentation') return 'ppt';
    return 'unknown';
  }
}
