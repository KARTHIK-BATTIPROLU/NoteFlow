import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_provider.dart';
import '../../../../core/models/subject.dart';
import '../../../../core/models/topic.dart';
import '../../../../core/models/resource.dart';

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSubjects();
});

final topicsProvider = FutureProvider.family<List<Topic>, String>((ref, subjectId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTopics(subjectId);
});

final resourcesProvider = FutureProvider.family<List<Resource>, String>((ref, topicId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getResources(topicId);
});
