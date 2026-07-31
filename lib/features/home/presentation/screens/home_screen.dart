import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/resource_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/utils/toast.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../upload/presentation/screens/upload_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/search_provider.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ExploreTab(),
          SearchScreen(),
          UploadScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Refresh Explore tab when returning from Upload tab
            if (_previousIndex == 2 && index == 0) {
              ref.read(communityFeedProvider.notifier).refresh();
            }
            setState(() {
              _previousIndex = _currentIndex;
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upload_rounded),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Explore Tab with Paginated Community Feed
class _ExploreTab extends ConsumerStatefulWidget {
  const _ExploreTab();

  @override
  ConsumerState<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<_ExploreTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(communityFeedProvider.notifier).refresh();
    ref.invalidate(subjectsProvider);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserName() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'NoteFlow',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                tooltip: 'Logout',
              ),
            ],
          ),

          // Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                '${_getGreeting()}, ${_getUserName()}',
                style: AppTextStyles.headingLarge,
              ),
            ),
          ),

          // Subject Filter Chips
          SliverToBoxAdapter(
            child: subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) return const SizedBox.shrink();

                return SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: subjects.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" chip
                        final isAllSelected = feedState.selectedSubjectId == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: isAllSelected,
                            onSelected: (selected) {
                              ref.read(communityFeedProvider.notifier).selectSubject(null);
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: isAllSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isAllSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }

                      final subject = subjects[index - 1];
                      final isSelected = feedState.selectedSubjectId == subject.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(subject.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref
                                .read(communityFeedProvider.notifier)
                                .selectSubject(selected ? subject.id : null);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          avatar: isSelected
                              ? null
                              : Icon(
                                  Icons.book_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Feed Header Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                'Explore notes',
                style: AppTextStyles.headingMedium,
              ),
            ),
          ),

          // Community Feed List
          _buildFeedList(context, feedState),

          // Loading More Indicator at bottom
          if (feedState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedList(BuildContext context, CommunityFeedState feedState) {
    if (feedState.isLoading && feedState.resources.isEmpty) {
      return const SliverToBoxAdapter(
        child: LoadingSkeleton(count: 5),
      );
    }

    if (feedState.error != null && feedState.resources.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load notes',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                feedState.error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => ref.read(communityFeedProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (feedState.resources.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No notes available in community feed',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Be the first to share notes!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final resource = feedState.resources[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: ResourceCard(
              resource: resource,
              onTap: () {
                if (resource.fileType.toLowerCase() == 'pdf') {
                  context.push('/pdf-viewer', extra: resource);
                } else {
                  Toast.show(
                    context,
                    'Only PDF files can be previewed in-app',
                  );
                }
              },
            ),
          );
        },
        childCount: feedState.resources.length,
      ),
    );
  }
}
