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

  Future<Resource> createResource({
    required String title,
    required String subject,
    required String topic,
    required String fileUrl,
    required String fileType,
    required String uploadedBy,
  }) async {
    final resourceData = {
      'title': title,
      'subject': subject,
      'topic': topic,
      'file_url': fileUrl,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
    };

    return await _apiService.createResource(resourceData);
  }
}
