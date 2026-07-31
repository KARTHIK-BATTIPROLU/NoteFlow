import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/models/resource.dart';
import 'package:noteflow/features/home/presentation/providers/search_provider.dart';

void main() {
  group('CommunityFeedNotifier State Tests', () {
    test('Initial CommunityFeedState properties', () {
      final state = CommunityFeedState();
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
      expect(state.selectedSubjectId, isNull);
    });

    test('CommunityFeedState copyWith updates subject filtering correctly', () {
      final state = CommunityFeedState(selectedSubjectId: 'subj123');
      expect(state.selectedSubjectId, equals('subj123'));

      final clearedState = state.copyWith(clearSubject: true);
      expect(clearedState.selectedSubjectId, isNull);

      final updatedState = state.copyWith(selectedSubjectId: 'subj456');
      expect(updatedState.selectedSubjectId, equals('subj456'));
    });

    test('CommunityFeedState copyWith appends resources correctly', () {
      final r1 = Resource(
        id: 'r1',
        title: 'Note 1',
        subjectId: 's1',
        topicId: 't1',
        firebaseUid: 'u1',
        fileId: 'f1',
        fileName: 'note1.pdf',
        contentType: 'application/pdf',
        size: 1024,
        likes: 5,
        downloads: 10,
        uploadedAt: DateTime.now(),
        uploaderHandle: 'student-abc123',
      );

      final r2 = Resource(
        id: 'r2',
        title: 'Note 2',
        subjectId: 's1',
        topicId: 't1',
        firebaseUid: 'u2',
        fileId: 'f2',
        fileName: 'note2.pdf',
        contentType: 'application/pdf',
        size: 2048,
        likes: 2,
        downloads: 4,
        uploadedAt: DateTime.now(),
        uploaderHandle: 'student-def456',
      );

      final state1 = CommunityFeedState(resources: [r1]);
      final state2 = state1.copyWith(resources: [...state1.resources, r2]);

      expect(state2.resources.length, equals(2));
      expect(state2.resources[0].title, equals('Note 1'));
      expect(state2.resources[1].title, equals('Note 2'));
      expect(state2.resources[1].uploaderHandle, equals('student-def456'));
    });
  });
}
