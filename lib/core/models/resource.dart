class Resource {
  final String id;
  final String title;
  final String subjectId;
  final String topicId;
  final String fileUrl;
  final String fileType;
  final String uploadedBy;
  final DateTime uploadedAt;

  Resource({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.topicId,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      title: json['title'],
      subjectId: json['subject'],
      topicId: json['topic'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subjectId,
      'topic': topicId,
      'file_url': fileUrl,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
