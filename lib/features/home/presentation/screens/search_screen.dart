import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/resource_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/toast.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedSubjectId;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for 300ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResourcesProvider(_searchQuery));
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Search',
                    style: AppTextStyles.headingLarge,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search resources...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),

            // Subject Filter Chips
            subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  color: AppColors.surface,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: subjects.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" chip
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text('All'),
                            selected: _selectedSubjectId == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSubjectId = null;
                              });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: _selectedSubjectId == null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _selectedSubjectId == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }
                      
                      final subject = subjects[index - 1];
                      final isSelected = _selectedSubjectId == subject.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(subject.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSubjectId = selected ? subject.id : null;
                            });
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
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Divider
            Divider(height: 1, color: AppColors.divider),

            // Results
            Expanded(
              child: searchResultsAsync.when(
                data: (resources) {
                  // Filter by selected subject if any
                  final filteredResources = _selectedSubjectId == null
                      ? resources
                      : resources.where((r) => r.subjectId == _selectedSubjectId).toList();

                  if (_searchQuery.isEmpty) {
                    return EmptyState(
                      message: 'Start searching',
                      subtitle: 'Type something to find resources',
                      icon: Icons.search_rounded,
                    );
                  }

                  if (filteredResources.isEmpty) {
                    return EmptyState(
                      message: 'No results found',
                      subtitle: 'Try different keywords or filters',
                      icon: Icons.search_off_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resource = filteredResources[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                  );
                },
                loading: () => const LoadingSkeleton(count: 5),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          error.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
