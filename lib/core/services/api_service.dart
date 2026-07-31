import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/resource.dart';

class ApiService {
  final String baseUrl = getBaseUrl();

  static String getBaseUrl() {
    return 'https://noteflow-uxwh.onrender.com';
  }

  // Get subjects from MongoDB
  Future<List<Subject>> getSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/subjects/'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load subjects: $e');
    }
  }

  // Get topics from MongoDB
  Future<List<Topic>> getTopics(String subjectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/subjects/$subjectId/topics/'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Topic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load topics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load topics: $e');
    }
  }

  // Get community resources with pagination and optional subject filtering
  Future<List<Resource>> getCommunityResources({
    int skip = 0,
    int limit = 20,
    String? subjectId,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (subjectId != null && subjectId.isNotEmpty) {
        queryParams['subject'] = subjectId;
      }

      final uri = Uri.parse('$baseUrl/resources/').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Resource.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load resources: $e');
    }
  }

  // Legacy fallback: get all resources
  Future<List<Resource>> getAllResources() async {
    return getCommunityResources(skip: 0, limit: 50);
  }

  // Get user's uploaded resources
  Future<List<Resource>> getUserResources(String firebaseToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/resources/'),
        headers: {
          'Authorization': 'Bearer $firebaseToken',
        },
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Resource.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user resources: $e');
    }
  }

  // Search resources
  Future<List<Resource>> searchResources({String? query, String? subjectId, String? topicId}) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (subjectId != null && subjectId.isNotEmpty) queryParams['subject'] = subjectId;
      if (topicId != null && topicId.isNotEmpty) queryParams['topic'] = topicId;

      final uri = Uri.parse('$baseUrl/search/').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Resource.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search resources: $e');
    }
  }

  // Get resources for a topic
  Future<List<Resource>> getResources(String topicId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics/$topicId/resources/'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Resource.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load resources: $e');
    }
  }

  // 3-step presigned URL upload flow directly to Cloudflare R2
  Future<Resource> uploadResource({
    required Uint8List bytes,
    String? filePath,
    required String fileName,
    required String title,
    required String subject,
    required String topic,
    required String firebaseUid,
    required String firebaseToken,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Determine content type
      final ext = fileName.split('.').last.toLowerCase();
      String contentType;
      if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'pptx') {
        contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else if (ext == 'ppt') {
        contentType = 'application/vnd.ms-powerpoint';
      } else {
        contentType = 'application/octet-stream';
      }

      // Compute SHA-256 hash
      if (onProgress != null) onProgress(0.05);
      final sha256Hash = sha256.convert(bytes).toString();

      // Step A: POST /uploads/init
      if (onProgress != null) onProgress(0.15);
      final initUri = Uri.parse('$baseUrl/uploads/init');
      final initResponse = await http.post(
        initUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
        body: jsonEncode({
          'title': title,
          'subject': subject,
          'topic': topic,
          'file_name': fileName,
          'content_type': contentType,
          'size': bytes.length,
          'sha256': sha256Hash,
        }),
      );

      if (initResponse.statusCode != 200) {
        throw Exception('Upload init failed (${initResponse.statusCode}): ${initResponse.body}');
      }

      final initData = jsonDecode(initResponse.body);
      if (initData['duplicate'] == true) {
        throw Exception('Duplicate upload detected. This resource already exists in NoteFlow.');
      }

      final uploadUrl = initData['upload_url'] as String;
      final storageKey = initData['key'] as String;

      // Step B: HTTP PUT file directly to Cloudflare R2 presigned URL
      if (onProgress != null) onProgress(0.30);
      
      if (filePath != null && filePath.isNotEmpty && !Platform.isWindows && (Platform.isAndroid || Platform.isIOS)) {
        // Stream from file path on mobile for memory efficiency
        final file = File(filePath);
        final fileStream = file.openRead();
        final totalLength = await file.length();
        
        final putRequest = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
        putRequest.headers['Content-Type'] = contentType;
        putRequest.contentLength = totalLength;

        int bytesSent = 0;
        fileStream.listen(
          (chunk) {
            bytesSent += chunk.length;
            if (onProgress != null && totalLength > 0) {
              final progress = 0.30 + (bytesSent / totalLength * 0.50);
              onProgress(progress);
            }
          },
          onDone: () {},
          onError: (e) {},
        );

        final putStream = putRequest.sink;
        await for (var chunk in fileStream) {
          putStream.add(chunk);
        }
        await putStream.close();
      } else {
        // Fallback: direct bytes PUT
        final putResponse = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        );

        if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
          throw Exception('Direct storage upload failed (${putResponse.statusCode}): ${putResponse.body}');
        }
      }

      // Step C: POST /uploads/complete
      if (onProgress != null) onProgress(0.90);
      final completeUri = Uri.parse('$baseUrl/uploads/complete');
      final completeResponse = await http.post(
        completeUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
        body: jsonEncode({
          'key': storageKey,
          'title': title,
          'subject': subject,
          'topic': topic,
          'file_name': fileName,
          'content_type': contentType,
          'size': bytes.length,
          'sha256': sha256Hash,
        }),
      );

      if (completeResponse.statusCode != 200) {
        throw Exception('Upload completion failed (${completeResponse.statusCode}): ${completeResponse.body}');
      }

      if (onProgress != null) onProgress(1.0);
      final resourceData = jsonDecode(completeResponse.body);
      return Resource.fromJson(resourceData);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Download file via presigned GET URL from R2
  Future<String> downloadFile(
    String resourceId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Step 1: Get presigned download URL from backend
      final downloadInfoUri = Uri.parse('$baseUrl/resources/$resourceId/download');
      final infoResponse = await http.get(downloadInfoUri);

      if (infoResponse.statusCode != 200) {
        throw Exception('Failed to get download URL: HTTP ${infoResponse.statusCode}');
      }

      final infoData = jsonDecode(infoResponse.body);
      final downloadUrl = infoData['download_url'] as String;

      // Step 2: Download file directly from presigned R2 URL
      final fileResponse = await http.get(Uri.parse(downloadUrl));
      if (fileResponse.statusCode != 200) {
        throw Exception('Storage download failed: HTTP ${fileResponse.statusCode}');
      }

      // Determine extension
      String ext = 'pdf';
      final contentTypeHeader = fileResponse.headers['content-type'] ?? '';
      if (contentTypeHeader.contains('powerpoint') || contentTypeHeader.contains('presentation')) {
        ext = 'pptx';
      }

      Directory tempDir;
      if (Platform.environment['TEMP'] != null) {
        tempDir = Directory(Platform.environment['TEMP']!);
      } else {
        tempDir = await getTemporaryDirectory();
      }

      final filePath = '${tempDir.path}/resource_$resourceId.$ext';
      final file = File(filePath);
      await file.writeAsBytes(fileResponse.bodyBytes);

      if (onProgress != null) onProgress(1.0);
      return filePath;
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }
}
