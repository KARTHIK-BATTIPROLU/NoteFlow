import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_provider.dart';
import '../../../../core/models/subject.dart';
import '../../../../core/models/topic.dart';
import '../../../../core/models/resource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

final userResourcesProvider = FutureProvider<List<Resource>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final authController = ref.watch(authControllerProvider.notifier);
  final token = await authController.getIdToken();
  
  if (token == null) {
    throw Exception('User not authenticated');
  }
  
  return apiService.getUserResources(token);
});

final searchResourcesProvider = FutureProvider.family<List<Resource>, String>((ref, query) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.searchResources(query: query);
});

// Community Feed State & Notifier with Pagination and Server-side Subject Filtering
class CommunityFeedState {
  final List<Resource> resources;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? selectedSubjectId;

  CommunityFeedState({
    this.resources = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.selectedSubjectId,
  });

  CommunityFeedState copyWith({
    List<Resource>? resources,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? selectedSubjectId,
    bool clearSubject = false,
  }) {
    return CommunityFeedState(
      resources: resources ?? this.resources,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      selectedSubjectId: clearSubject ? null : (selectedSubjectId ?? this.selectedSubjectId),
    );
  }
}

class CommunityFeedNotifier extends StateNotifier<CommunityFeedState> {
  final Ref _ref;
  static const int _pageSize = 20;

  CommunityFeedNotifier(this._ref) : super(CommunityFeedState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final items = await apiService.getCommunityResources(
        skip: 0,
        limit: _pageSize,
        subjectId: state.selectedSubjectId,
      );

      state = state.copyWith(
        resources: items,
        isLoading: false,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final nextItems = await apiService.getCommunityResources(
        skip: state.resources.length,
        limit: _pageSize,
        subjectId: state.selectedSubjectId,
      );

      state = state.copyWith(
        resources: [...state.resources, ...nextItems],
        isLoadingMore: false,
        hasMore: nextItems.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void selectSubject(String? subjectId) {
    if (state.selectedSubjectId == subjectId) return;

    if (subjectId == null) {
      state = state.copyWith(clearSubject: true);
    } else {
      state = state.copyWith(selectedSubjectId: subjectId);
    }
    refresh();
  }
}

final communityFeedProvider = StateNotifierProvider<CommunityFeedNotifier, CommunityFeedState>((ref) {
  return CommunityFeedNotifier(ref);
});
