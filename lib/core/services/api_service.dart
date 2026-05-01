import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/resource.dart';

class ApiService {
  // Backend server URL (MongoDB + GridFS)
  final String baseUrl = getBaseUrl();

  static String getBaseUrl() {
    try {
      if (Platform.isAndroid) {
        // Using computer's IP address for physical device
        return 'http://10.161.157.42:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }
  
  static String getFileDownloadUrl(String fileId) {
    return '${getBaseUrl()}/file/$fileId';
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
      print('Error fetching subjects: $e');
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
      print('Error fetching topics: $e');
      throw Exception('Failed to load topics: $e');
    }
  }

  // Get all resources from MongoDB
  Future<List<Resource>> getAllResources() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/resources/'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Resource.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all resources: $e');
      throw Exception('Failed to load resources: $e');
    }
  }

  // Get user's uploaded resources from MongoDB
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
      print('Error fetching user resources: $e');
      throw Exception('Failed to load user resources: $e');
    }
  }

  // Search resources in MongoDB
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
      print('Error searching resources: $e');
      throw Exception('Failed to search resources: $e');
    }
  }

  // Get resources for a topic from MongoDB
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
      print('Error fetching resources for topic: $e');
      throw Exception('Failed to load resources: $e');
    }
  }

  // Upload file to MongoDB GridFS via backend
  Future<Resource> uploadResource({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String subject,
    required String topic,
    required String firebaseUid,
    required String firebaseToken,
    void Function(double progress)? onProgress,
  }) async {
    try {
      print('=== UPLOAD TO MONGODB/GRIDFS START ===');
      print('Backend URL: $baseUrl/upload');
      print('Title: $title');
      print('Subject: $subject');
      print('Topic: $topic');
      print('File: $fileName');
      print('Size: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      print('User: $firebaseUid');
      
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add Firebase auth token
      request.headers['Authorization'] = 'Bearer $firebaseToken';
      print('Authorization header added');

      // Add form fields
      request.fields['title'] = title;
      request.fields['subject'] = subject;
      request.fields['topic'] = topic;
      print('Form fields added');

      // Determine content type
      final ext = fileName.split('.').last.toLowerCase();
      MediaType? contentType;
      if (ext == 'pdf') {
        contentType = MediaType('application', 'pdf');
      } else if (ext == 'ppt' || ext == 'pptx') {
        contentType = MediaType('application', 'vnd.ms-powerpoint');
      } else {
        contentType = MediaType('application', 'octet-stream');
      }
      print('Content type: $contentType');

      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      print('File added to request');

      // Send request with progress tracking and timeout
      if (onProgress != null) onProgress(0.1); // 10% - starting
      print('Sending request to backend...');
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // 2 minute timeout for large files
        onTimeout: () {
          print('=== UPLOAD TIMEOUT ===');
          print('Connection timed out after 120 seconds');
          print('Possible causes:');
          print('1. Backend server is not running');
          print('2. Firewall is blocking port 8000');
          print('3. Wrong IP address: $baseUrl');
          print('4. Network connectivity issues');
          print('');
          print('SOLUTIONS:');
          print('- Check if backend is running on $baseUrl');
          print('- Add Windows Firewall rule for port 8000');
          print('- Try USB debugging with: adb reverse tcp:8000 tcp:8000');
          throw Exception('Connection timeout - Cannot reach backend server at $baseUrl. Check firewall settings and ensure backend is running.');
        },
      );
      print('Response status: ${streamedResponse.statusCode}');
      
      // Track upload progress
      int bytesReceived = 0;
      final totalBytes = streamedResponse.contentLength ?? bytes.length;
      
      final responseBytes = <int>[];
      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        bytesReceived += chunk.length;
        
        if (onProgress != null && totalBytes > 0) {
          final progress = 0.1 + (bytesReceived / totalBytes * 0.9); // 10-100%
          onProgress(progress);
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      }
      
      final responseBody = utf8.decode(responseBytes);
      print('Response body received: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
      
      if (streamedResponse.statusCode == 200) {
        if (onProgress != null) onProgress(1.0); // 100% - complete
        print('=== UPLOAD SUCCESS ===');
        
        final responseData = jsonDecode(responseBody);
        return Resource.fromJson(responseData);
      } else {
        print('=== UPLOAD FAILED ===');
        print('Status code: ${streamedResponse.statusCode}');
        print('Response: $responseBody');
        throw Exception('Upload failed: ${streamedResponse.statusCode} - $responseBody');
      }
    } catch (e, stackTrace) {
      print('=== UPLOAD ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Provide helpful error messages
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception(
          'Cannot connect to backend server at $baseUrl.\n\n'
          'Possible solutions:\n'
          '1. Ensure backend is running\n'
          '2. Add Windows Firewall rule for port 8000\n'
          '3. Use USB debugging: adb reverse tcp:8000 tcp:8000\n'
          '4. Check network connectivity\n\n'
          'See QUICK_FIX_STEPS.md for detailed instructions.'
        );
      }
      
      throw Exception('Upload failed: $e');
    }
  }

  /// Downloads a file from GridFS and saves it to a temporary location
  /// Returns the local file path on success, throws exception on failure
  Future<String> downloadFile(String fileId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      print('Downloading file from GridFS: $fileId');
      final url = '$baseUrl/file/$fileId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Get temporary directory
        Directory tempDir;
        if (Platform.environment['TEMP'] != null) {
          tempDir = Directory(Platform.environment['TEMP']!);
        } else {
          tempDir = await getTemporaryDirectory();
        }
        
        // Create file path
        final filePath = '${tempDir.path}/$fileId.pdf';
        final file = File(filePath);
        
        // Write bytes to file
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded to: $filePath');
        
        if (onProgress != null) {
          onProgress(1.0);
        }
        
        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
      throw Exception('Download error: $e');
    }
  }
}
