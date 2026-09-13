import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noteflow/core/services/api_service.dart';

void main() {
  group('ApiService Unit Tests with MockClient', () {
    test('getSubjects parses response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/subjects/') {
          return http.Response(
            jsonEncode([
              {'id': 'subj1', 'name': 'Computer Science'},
              {'id': 'subj2', 'name': 'Mathematics'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final subjects = await apiService.getSubjects();

      expect(subjects.length, equals(2));
      expect(subjects[0].id, equals('subj1'));
      expect(subjects[0].name, equals('Computer Science'));
      expect(subjects[1].name, equals('Mathematics'));
    });

    test('getTopics parses response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/topics/')) {
          return http.Response(
            jsonEncode([
              {'id': 'top1', 'name': 'Algorithms', 'subject': 'subj1'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final topics = await apiService.getTopics('subj1');

      expect(topics.length, equals(1));
      expect(topics[0].id, equals('top1'));
      expect(topics[0].name, equals('Algorithms'));
      expect(topics[0].subjectId, equals('subj1'));
    });

    test('getCommunityResources passes pagination and subject query params', () async {
      late Uri capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode([
            {
              'id': 'res1',
              'title': 'Test Resource',
              'subject': 'subj1',
              'topic': 'top1',
              'firebase_uid': 'uid1',
              'file_name': 'test.pdf',
              'content_type': 'application/pdf',
              'size': 1024,
              'likes': 0,
              'downloads': 0,
              'created_at': DateTime.now().toIso8601String(),
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final resources = await apiService.getCommunityResources(
        skip: 20,
        limit: 10,
        subjectId: 'subj1',
      );

      expect(capturedUri.queryParameters['skip'], equals('20'));
      expect(capturedUri.queryParameters['limit'], equals('10'));
      expect(capturedUri.queryParameters['subject'], equals('subj1'));
      expect(resources.length, equals(1));
      expect(resources[0].title, equals('Test Resource'));
    });

    test('searchResources builds proper query parameters', () async {
      late Uri capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      await apiService.searchResources(query: 'machine learning', subjectId: 'subj_ai');

      expect(capturedUri.queryParameters['q'], equals('machine learning'));
      expect(capturedUri.queryParameters['subject'], equals('subj_ai'));
    });

    test('getDownloadUrl returns presigned URL', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/resources/res123/download') {
          return http.Response(
            jsonEncode({'download_url': 'https://r2.cloudflarestorage.com/test.pdf'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final url = await apiService.getDownloadUrl('res123');
      expect(url, equals('https://r2.cloudflarestorage.com/test.pdf'));
    });

    test('likeResource increments likes count', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/resources/res123/like' && request.method == 'POST') {
          return http.Response(
            jsonEncode({'resource_id': 'res123', 'likes': 5}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final likes = await apiService.likeResource('res123');
      expect(likes, equals(5));
    });

    test('getResource returns single resource', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/resources/res123') {
          return http.Response(
            jsonEncode({
              'id': 'res123',
              'title': 'Shared Discrete Math Notes',
              'subject': 'subj1',
              'topic': 'top1',
              'firebase_uid': 'uid99',
              'file_name': 'discrete.pdf',
              'content_type': 'application/pdf',
              'size': 2048,
              'likes': 12,
              'downloads': 34,
              'created_at': DateTime.now().toIso8601String(),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000');
      final resource = await apiService.getResource('res123');
      expect(resource.id, equals('res123'));
      expect(resource.title, equals('Shared Discrete Math Notes'));
      expect(resource.likes, equals(12));
    });
  });
}

