class Resource {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final String fileUrl;
  final String fileType;
  final String uploadedBy;
  final DateTime uploadedAt;

  Resource({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'subject': subject,
      'topic': topic,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['_id']?.toString() ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: map['uploadedAt'] is DateTime
          ? map['uploadedAt']
          : DateTime.tryParse(map['uploadedAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }
}
