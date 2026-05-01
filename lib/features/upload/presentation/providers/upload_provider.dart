import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../data/resource_repository.dart';

// File picker service provider
final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

class FilePickerService {
  Future<PlatformFile?> pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['pdf', 'ppt', 'pptx'],
      withData: true,
    );

    return result?.files.isNotEmpty == true ? result!.files.first : null;
  }
}

class UploadState {
  final PlatformFile? selectedFile;
  final String title;
  final String subject;
  final String topic;
  final double uploadProgress;
  final bool isUploading;
  final String? error;
  final bool isSuccess;

  UploadState({
    this.selectedFile,
    this.title = '',
    this.subject = '',
    this.topic = '',
    this.uploadProgress = 0,
    this.isUploading = false,
    this.error,
    this.isSuccess = false,
  });

  UploadState copyWith({
    PlatformFile? selectedFile,
    String? title,
    String? subject,
    String? topic,
    double? uploadProgress,
    bool? isUploading,
    String? error,
    bool? isSuccess,
  }) {
    return UploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;

  UploadNotifier(this._ref) : super(UploadState());

  void setTitle(String value) => state = state.copyWith(title: value);
  void setSubject(String value) => state = state.copyWith(subject: value);
  void setTopic(String value) => state = state.copyWith(topic: value);

  Future<void> pickFile() async {
    final picker = _ref.read(filePickerServiceProvider);
    final file = await picker.pickFile(
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
    );
    if (file != null) {
      // Check file size (200MB = 200 * 1024 * 1024 bytes)
      const maxSizeBytes = 200 * 1024 * 1024;
      const warningSizeBytes = 50 * 1024 * 1024;
      
      if (file.size > maxSizeBytes) {
        state = state.copyWith(
          error: 'File size exceeds 200MB limit. Please select a smaller file.',
        );
        return;
      }
      
      // Set warning for large files (50MB+)
      String? warning;
      if (file.size > warningSizeBytes) {
        final sizeMB = (file.size / (1024 * 1024)).toStringAsFixed(1);
        warning = 'Large file ($sizeMB MB) - upload may take time on mobile data';
      }
      
      state = state.copyWith(
        selectedFile: file,
        error: warning, // Use error field to show warning
      );
    }
  }

  Future<void> upload() async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: 'Please select a file');
      return;
    }
    if (state.title.isEmpty) {
      state = state.copyWith(error: 'Please enter a title');
      return;
    }
    if (state.subject.isEmpty) {
      state = state.copyWith(error: 'Please enter a subject');
      return;
    }
    if (state.topic.isEmpty) {
      state = state.copyWith(error: 'Please enter a topic');
      return;
    }

    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = state.copyWith(error: 'You must be logged in to upload');
      return;
    }

    state = state.copyWith(isUploading: true, error: null, uploadProgress: 0);

    try {
      final repository = _ref.read(resourceRepositoryProvider);

      final bytes = state.selectedFile!.bytes;
      if (bytes == null) {
        throw Exception('File bytes not available');
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${state.selectedFile!.name}';
      
      final token = await user.getIdToken();
      if (token == null) throw Exception('Unable to get authentication token');

      await repository.uploadResource(
        bytes: bytes,
        fileName: fileName,
        title: state.title,
        subject: state.subject,
        topic: state.topic,
        firebaseUid: user.uid,
        firebaseToken: token,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  void reset() {
    state = UploadState();
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((
  ref,
) {
  return UploadNotifier(ref);
});
