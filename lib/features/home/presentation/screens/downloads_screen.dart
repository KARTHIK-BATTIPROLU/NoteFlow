import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/utils/toast.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatFileSize(dynamic size) {
    try {
      if (size == null) return 'Unknown size';
      
      final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (type.contains('ppt') || type.contains('presentation')) {
      return Icons.slideshow;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String? fileType) {
    if (fileType == null) return AppColors.otherBlue;
    
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) {
      return AppColors.pdfRed;
    } else if (type.contains('ppt') || type.contains('presentation')) {
      return AppColors.pptOrange;
    }
    return AppColors.otherBlue;
  }

  Future<void> _openFile(BuildContext context, Map download) async {
    final localPath = download['localPath'];
    if (localPath == null) {
      Toast.show(context, 'File path not found', isError: true);
      return;
    }

    try {
      final result = await OpenFile.open(localPath.toString());
      if (result.type != ResultType.done && context.mounted) {
        Toast.show(context, result.message, isError: true);
      }
    } catch (e) {
      if (context.mounted) {
        Toast.show(context, 'Failed to open file: $e', isError: true);
      }
    }
  }

  Future<void> _deleteFile(BuildContext context, String resourceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Download',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'Are you sure you want to remove this file from downloads?',
          style: AppTextStyles.bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDb.removeDownloadedFile(resourceId);
      if (context.mounted) {
        Toast.show(context, 'Download removed');
      }
    }
  }

  Future<void> _clearAllDownloads(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Downloads',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'Are you sure you want to remove all downloaded files? This action cannot be undone.',
          style: AppTextStyles.bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear All',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDb.downloadsBox.clear();
      if (context.mounted) {
        Toast.show(context, 'All downloads cleared');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = LocalDb.getAllDownloads();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'My downloads',
          style: AppTextStyles.headingMedium,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: downloads.isNotEmpty
            ? [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () => _clearAllDownloads(context),
                  tooltip: 'Clear all',
                ),
              ]
            : null,
      ),
      body: downloads.isEmpty
          ? const EmptyState(
              message: 'No downloads yet',
              subtitle: 'Files you view will appear here for offline access',
              icon: Icons.download_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final download = downloads[index];
                final resourceId = download['id']?.toString() ?? '';
                final title = download['title']?.toString() ?? 'Unknown Document';
                final fileType = download['fileType']?.toString();
                final subjectName = download['subject_name']?.toString() ?? 
                                   download['subjectName']?.toString();
                final topicName = download['topic_name']?.toString() ?? 
                                 download['topicName']?.toString();
                final size = download['size'];
                final downloadedAt = download['downloaded_at'] ?? 
                                    download['downloadedAt'] ?? 
                                    download['created_at'] ?? 
                                    download['createdAt'];

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getFileColor(fileType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            _getFileIcon(fileType),
                            color: _getFileColor(fileType),
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: AppSpacing.md),

                        // File Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                title,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: AppSpacing.xs),

                              // Subject + Topic
                              if (subjectName != null || topicName != null)
                                Text(
                                  [
                                    if (subjectName != null) subjectName,
                                    if (topicName != null) topicName,
                                  ].join(' • '),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              const SizedBox(height: AppSpacing.xs),

                              // Size + Date
                              Row(
                                children: [
                                  Icon(
                                    Icons.storage_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatFileSize(size),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(downloadedAt),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Action Buttons
                        Column(
                          children: [
                            // Open Button
                            IconButton(
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _openFile(context, download),
                              tooltip: 'Open',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),

                            // Delete Button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () => _deleteFile(context, resourceId),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
