import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/resource.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class ApiService {
  final FirestoreService _firestoreService = FirestoreService();

  // For physical Android device, use your computer's local IP
  // For emulator, use 10.0.2.2
  final String baseUrl = getBaseUrl();

  static String getBaseUrl() {
    try {
      if (Platform.isAndroid) {
        // Using computer's IP address for physical device
        return 'http://192.168.0.16:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }
  
  static String getFileDownloadUrl(String fileId) {
    return '${getBaseUrl()}/file/$fileId';
  }

  // Use Firestore instead of backend API
  Future<List<Subject>> getSubjects() async {
    return _firestoreService.getSubjects();
  }

  Future<List<Topic>> getTopics(String subjectId) async {
    return _firestoreService.getTopics(subjectId);
  }

  Future<List<Resource>> getAllResources() async {
    return _firestoreService.getAllResources();
  }

  Future<List<Resource>> searchResources({String? query, String? subjectId, String? topicId}) async {
    return _firestoreService.searchResources(
      query: query,
      subjectId: subjectId,
      topicId: topicId,
    );
  }

  Future<List<Resource>> getResources(String topicId) async {
    return _firestoreService.getResources(topicId);
  }

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
      print('ApiService: Starting upload process');
      print('ApiService: Title: $title, Subject: $subject, Topic: $topic');
      print('ApiService: File: $fileName, Size: ${bytes.length} bytes');
      
      // Upload file to Firebase Storage
      final storageService = StorageService();
      
      if (onProgress != null) onProgress(0.1); // 10% - starting
      
      // Update progress for upload phase (10-85%)
      final downloadUrl = await storageService.uploadFile(
        bytes: bytes,
        fileName: fileName,
        userId: firebaseUid,
        onProgress: (storageProgress) {
          if (onProgress != null) {
            onProgress(0.1 + (storageProgress * 0.75)); // 10-85% for storage upload
          }
        },
      );

      print('ApiService: File uploaded successfully, URL: $downloadUrl');
      if (onProgress != null) onProgress(0.9); // 90% - file uploaded

      // Create resource metadata in Firestore
      final resourceData = {
        'title': title,
        'subjectId': subject,
        'topicId': topic,
        'firebaseUid': firebaseUid,
        'uploadedBy': firebaseUid,
        'fileId': downloadUrl,
        'fileName': fileName,
        'contentType': _getContentType(fileName),
        'size': bytes.length,
        'likes': 0,
        'downloads': 0,
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      print('ApiService: Saving metadata to Firestore');
      if (onProgress != null) onProgress(0.95); // 95% - saving metadata

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('resources')
          .add(resourceData);

      print('ApiService: Metadata saved with ID: ${docRef.id}');
      if (onProgress != null) onProgress(1.0); // 100% - complete

      // Return the created resource
      return Resource(
        id: docRef.id,
        title: title,
        subjectId: subject,
        topicId: topic,
        firebaseUid: firebaseUid,
        uploadedBy: firebaseUid,
        fileId: downloadUrl,
        fileName: fileName,
        contentType: _getContentType(fileName),
        size: bytes.length,
        likes: 0,
        downloads: 0,
        uploadedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('ApiService: Upload failed with error: $e');
      print('ApiService: Stack trace: $stackTrace');
      throw Exception('Upload failed: $e');
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      default:
        return 'application/octet-stream';
    }
  }

  /// Downloads a file from GridFS and saves it to a temporary location
  /// Returns the local file path on success, throws exception on failure
  Future<String> downloadFile(String fileId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
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
        
        if (onProgress != null) {
          onProgress(1.0);
        }
        
        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  // Deprecated: old creation via JSON metadata
  Future<Resource> createResource(Map<String, dynamic> resourceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resources/'),
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
