class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'_id': id, 'name': name};
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(id: map['_id']?.toString() ?? '', name: map['name'] ?? '');
  }
}
