class Topic {
  final String id;
  final String name;
  final String subject;

  Topic({required this.id, required this.name, required this.subject});

  Map<String, dynamic> toMap() {
    return {'_id': id, 'name': name, 'subject': subject};
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['_id']?.toString() ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
    );
  }
}
