import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/resource_repository.dart';
import '../../../../features/auth/data/auth_repository.dart';

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
      state = state.copyWith(selectedFile: file);
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
      final storage = _ref.read(storageServiceProvider);
      final repository = _ref.read(resourceRepositoryProvider);

      final file = File(state.selectedFile!.path!);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${state.selectedFile!.name}';
      final fileType = state.selectedFile!.extension ?? 'pdf';

      final fileUrl = await storage.uploadFile(
        file: file,
        fileName: fileName,
        userId: user.uid,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      await repository.createResource(
        title: state.title,
        subject: state.subject,
        topic: state.topic,
        fileUrl: fileUrl,
        fileType: fileType,
        uploadedBy: user.uid,
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
