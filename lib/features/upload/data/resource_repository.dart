import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/resource.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ResourceRepository(apiService);
});

class ResourceRepository {
  final ApiService _apiService;

  ResourceRepository(this._apiService);

  Future<Resource> uploadResource({
    required dynamic bytes,
    required String fileName,
    required String title,
    required String subject,
    required String topic,
    required String firebaseUid,
    required String firebaseToken,
    void Function(double progress)? onProgress,
  }) async {
    return await _apiService.uploadResource(
      bytes: bytes,
      fileName: fileName,
      title: title,
      subject: subject,
      topic: topic,
      firebaseUid: firebaseUid,
      firebaseToken: firebaseToken,
      onProgress: onProgress,
    );
  }
}
