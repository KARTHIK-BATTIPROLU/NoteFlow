class Topic {
  final String id;
  final String name;
  final String subjectId;

  Topic({
    required this.id,
    required this.name,
    required this.subjectId,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      subjectId: json['subject'] ?? json['subjectId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subjectId,
    };
  }
}
