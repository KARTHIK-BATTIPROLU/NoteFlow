import 'dart:io';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String fileName,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'resources/$userId/$fileName';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: _getContentType(fileName)),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await uploadTask;
    return await ref.getDownloadURL();
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
