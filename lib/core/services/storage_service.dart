import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

class StorageService {
  // Explicitly use the default Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      print('=== STORAGE UPLOAD START ===');
      print('File: $fileName');
      print('Size: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      print('User: $userId');
      
      // Create storage reference with explicit path
      final path = 'resources/$userId/$fileName';
      print('Storage path: $path');
      print('Storage bucket: ${_storage.bucket}');
      
      final storageRef = _storage.ref().child(path);
      print('Storage reference created: ${storageRef.fullPath}');

      // Create metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'uploadedBy': userId,
          'originalName': fileName,
        },
      );
      print('Metadata: ${metadata.contentType}');

      // Start upload
      print('Starting upload task...');
      final uploadTask = storageRef.putData(bytes, metadata);

      // Listen to progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final percent = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('Upload progress: ${percent.toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
          print('Upload state: ${snapshot.state}');
          
          if (onProgress != null) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        },
        onError: (error) {
          print('Upload stream error: $error');
        },
      );

      // Wait for upload to complete
      print('Waiting for upload to complete...');
      final taskSnapshot = await uploadTask;
      print('Upload task completed!');
      print('Final state: ${taskSnapshot.state}');
      print('Bytes transferred: ${taskSnapshot.bytesTransferred}');
      
      // Get download URL
      print('Getting download URL...');
      final downloadUrl = await storageRef.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      print('=== STORAGE UPLOAD SUCCESS ===');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('=== FIREBASE STORAGE ERROR ===');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Error plugin: ${e.plugin}');
      print('Stack trace: ${e.stackTrace}');
      
      // Provide user-friendly error messages
      String userMessage;
      switch (e.code) {
        case 'unauthorized':
        case 'permission-denied':
          userMessage = 'Permission denied. Please check Firebase Storage rules.';
          break;
        case 'canceled':
          userMessage = 'Upload was canceled.';
          break;
        case 'unknown':
          userMessage = 'An unknown error occurred. Check your internet connection.';
          break;
        case 'object-not-found':
          userMessage = 'Storage bucket not found. Please check Firebase configuration.';
          break;
        case 'bucket-not-found':
          userMessage = 'Storage bucket does not exist. Please enable Firebase Storage.';
          break;
        case 'project-not-found':
          userMessage = 'Firebase project not found. Please check configuration.';
          break;
        case 'quota-exceeded':
          userMessage = 'Storage quota exceeded.';
          break;
        case 'unauthenticated':
          userMessage = 'User not authenticated. Please sign in again.';
          break;
        case 'retry-limit-exceeded':
          userMessage = 'Upload failed after multiple retries. Check your connection.';
          break;
        case 'invalid-checksum':
          userMessage = 'File upload corrupted. Please try again.';
          break;
        default:
          userMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      
      throw Exception(userMessage);
    } catch (e, stackTrace) {
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Upload failed: $e');
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }
}

class FilePickerService {
  Future<fp.PlatformFile?> pickFile({List<String>? allowedExtensions}) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: allowedExtensions ?? ['pdf', 'ppt', 'pptx'],
      withData: true,
    );

    return result?.files.isNotEmpty == true ? result!.files.first : null;
  }
}
