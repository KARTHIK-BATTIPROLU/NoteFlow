import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/resource.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/Web.
  final String baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  Future<List<Subject>> getSubjects() async {
    final response = await http.get(Uri.parse('\$baseUrl/subjects/'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Subject.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  Future<List<Topic>> getTopics(String subjectId) async {
    final response = await http.get(Uri.parse('\$baseUrl/subjects/\$subjectId/topics/'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Topic.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load topics');
    }
  }

  Future<List<Resource>> getResources(String topicId) async {
    final response = await http.get(Uri.parse('\$baseUrl/topics/\$topicId/resources/'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Resource.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load resources');
    }
  }

  Future<Resource> createResource(Map<String, dynamic> resourceData) async {
    final response = await http.post(
      Uri.parse('\$baseUrl/resources/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(resourceData),
    );
    
    if (response.statusCode == 200) {
      return Resource.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create resource');
    }
  }
}
