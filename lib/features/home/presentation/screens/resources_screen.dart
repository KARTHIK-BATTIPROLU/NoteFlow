import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/resource_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/toast.dart';
import '../providers/search_provider.dart';

class ResourcesScreen extends ConsumerWidget {
  final String topicId;
  final String topicName;

  const ResourcesScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider(topicId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          topicName,
          style: AppTextStyles.headingMedium,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return EmptyState(
              message: 'No resources yet',
              subtitle: 'Be the first to upload a resource for this topic!',
              icon: Icons.folder_open,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ResourceCard(
                  resource: resource,
                  onTap: () {
                    // Navigate to PDF viewer with full Resource object
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
                  'Failed to load resources',
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
    );
  }
}
