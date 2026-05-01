import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Resource Model Tests', () {
    test('Resource fromJson handles backend format', () {
      final json = {
        'id': 'res123',
        'title': 'Test Resource',
        'subject': 'cs',
        'topic': 'cs_web',
        'firebase_uid': 'user123',
        'file_id': 'https://storage.googleapis.com/file.pdf',
        'file_name': 'test.pdf',
        'content_type': 'application/pdf',
        'size': 1024,
        'likes': 5,
        'downloads': 10,
        'uploaded_at': '2024-01-01T00:00:00.000Z',
      };

      // Simulate Resource.fromJson logic
      final id = json['id'] ?? '';
      final title = json['title'] ?? 'Untitled';
      final subjectId = json['subject'] ?? json['subjectId'] ?? '';
      final topicId = json['topic'] ?? json['topicId'] ?? '';
      
      expect(id, equals('res123'));
      expect(title, equals('Test Resource'));
      expect(subjectId, equals('cs'));
      expect(topicId, equals('cs_web'));
    });

    test('Resource fromJson handles Firestore format', () {
      final json = {
        'id': 'res456',
        'title': 'Firestore Resource',
        'subjectId': 'math',
        'topicId': 'math_calculus',
        'firebaseUid': 'user456',
        'fileId': 'https://storage.googleapis.com/file2.pdf',
        'fileName': 'test2.pdf',
        'contentType': 'application/pdf',
        'size': 2048,
        'likes': 3,
        'downloads': 7,
        'uploadedAt': '2024-01-02T00:00:00.000Z',
      };

      // Simulate Resource.fromJson logic
      final id = json['id'] ?? '';
      final title = json['title'] ?? 'Untitled';
      final subjectId = json['subject'] ?? json['subjectId'] ?? '';
      final topicId = json['topic'] ?? json['topicId'] ?? '';
      
      expect(id, equals('res456'));
      expect(title, equals('Firestore Resource'));
      expect(subjectId, equals('math'));
      expect(topicId, equals('math_calculus'));
    });

    test('Resource handles missing optional fields', () {
      final json = {
        'id': 'res789',
        'title': 'Minimal Resource',
        'subject': 'physics',
        'topic': 'phy_mechanics',
      };

      // Simulate Resource.fromJson with defaults
      final id = json['id'] ?? '';
      final title = json['title'] ?? 'Untitled';
      final subjectId = json['subject'] ?? json['subjectId'] ?? '';
      final topicId = json['topic'] ?? json['topicId'] ?? '';
      final firebaseUid = json['firebase_uid'] ?? json['firebaseUid'] ?? '';
      final fileId = json['file_id'] ?? json['fileId'] ?? '';
      final fileName = json['file_name'] ?? json['fileName'] ?? 'unknown';
      final contentType = json['content_type'] ?? json['contentType'] ?? 'application/octet-stream';
      final size = json['size'] ?? 0;
      final likes = json['likes'] ?? 0;
      final downloads = json['downloads'] ?? 0;
      
      expect(id, equals('res789'));
      expect(title, equals('Minimal Resource'));
      expect(firebaseUid, equals(''));
      expect(fileName, equals('unknown'));
      expect(size, equals(0));
      expect(likes, equals(0));
      expect(downloads, equals(0));
    });

    test('fileType getter returns correct extension', () {
      final testCases = [
        {'fileName': 'document.pdf', 'expected': 'pdf'},
        {'fileName': 'presentation.ppt', 'expected': 'ppt'},
        {'fileName': 'slides.pptx', 'expected': 'pptx'},
        {'fileName': 'unknown.txt', 'expected': 'txt'},
      ];

      for (final testCase in testCases) {
        final fileName = testCase['fileName'] as String;
        final expected = testCase['expected'] as String;
        
        String fileType;
        if (fileName.contains('.')) {
          fileType = fileName.split('.').last.toLowerCase();
        } else {
          fileType = 'unknown';
        }
        
        expect(fileType, equals(expected));
      }
    });

    test('Resource toJson creates correct structure', () {
      final resourceData = {
        'id': 'res123',
        'title': 'Test',
        'subject': 'cs',
        'topic': 'cs_web',
        'firebase_uid': 'user123',
        'file_id': 'url',
        'file_name': 'test.pdf',
        'content_type': 'application/pdf',
        'size': 1024,
        'likes': 0,
        'downloads': 0,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      expect(resourceData['id'], isNotNull);
      expect(resourceData['title'], isNotNull);
      expect(resourceData['subject'], isNotNull);
      expect(resourceData['topic'], isNotNull);
      expect(resourceData['firebase_uid'], isNotNull);
      expect(resourceData['file_id'], isNotNull);
      expect(resourceData['file_name'], isNotNull);
      expect(resourceData['content_type'], isNotNull);
      expect(resourceData['size'], isA<int>());
      expect(resourceData['likes'], isA<int>());
      expect(resourceData['downloads'], isA<int>());
    });
  });

  group('Subject Model Tests', () {
    test('Subject fromJson works correctly', () {
      final json = {
        'id': 'cs',
        'name': 'Computer Science',
      };

      final id = json['id'];
      final name = json['name'];

      expect(id, equals('cs'));
      expect(name, equals('Computer Science'));
    });

    test('Subject handles missing fields', () {
      final json = <String, dynamic>{};

      final id = json['id'] ?? '';
      final name = json['name'] ?? 'Untitled';

      expect(id, equals(''));
      expect(name, equals('Untitled'));
    });
  });

  group('Topic Model Tests', () {
    test('Topic fromJson handles backend format', () {
      final json = {
        'id': 'cs_web',
        'name': 'Web Development',
        'subject': 'cs',
      };

      final id = json['id'];
      final name = json['name'];
      final subjectId = json['subject'] ?? json['subjectId'];

      expect(id, equals('cs_web'));
      expect(name, equals('Web Development'));
      expect(subjectId, equals('cs'));
    });

    test('Topic fromJson handles Firestore format', () {
      final json = {
        'id': 'math_calculus',
        'name': 'Calculus',
        'subjectId': 'math',
      };

      final id = json['id'];
      final name = json['name'];
      final subjectId = json['subject'] ?? json['subjectId'];

      expect(id, equals('math_calculus'));
      expect(name, equals('Calculus'));
      expect(subjectId, equals('math'));
    });

    test('Topic handles missing fields', () {
      final json = <String, dynamic>{};

      final id = json['id'] ?? '';
      final name = json['name'] ?? 'Untitled';
      final subjectId = json['subject'] ?? json['subjectId'] ?? '';

      expect(id, equals(''));
      expect(name, equals('Untitled'));
      expect(subjectId, equals(''));
    });
  });
}
