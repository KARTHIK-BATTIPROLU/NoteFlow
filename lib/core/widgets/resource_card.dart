import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/resource.dart';
import '../theme/app_theme.dart';
import 'subject_chip.dart';

/// A beautiful card widget that displays a single resource
/// with file type badge, title, subject/topic chips, metadata, and tap interaction
class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + File Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      resource.title,
                      style: AppTextStyles.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // File Type Badge
                  _buildFileTypeBadge(),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Subject and Topic Chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (resource.subjectName != null)
                    SubjectChip(
                      label: resource.subjectName!,
                      type: ChipType.subject,
                    ),
                  if (resource.topicName != null)
                    SubjectChip(
                      label: resource.topicName!,
                      type: ChipType.topic,
                    ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Divider
              const Divider(height: 1),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Footer: Uploader, Date, Stats
              Row(
                children: [
                  // Uploader Icon + Name
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _getUploaderName(),
                    style: AppTextStyles.bodySmall,
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Upload Date
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDate(resource.uploadedAt),
                    style: AppTextStyles.bodySmall,
                  ),
                  
                  const Spacer(),
                  
                  // Download Count
                  Icon(
                    Icons.download_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${resource.downloads}',
                    style: AppTextStyles.bodySmall,
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // View/Like Count
                  Icon(
                    Icons.favorite_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${resource.likes}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build file type badge with appropriate color and icon
  Widget _buildFileTypeBadge() {
    final fileType = resource.fileType.toUpperCase();
    Color badgeColor;
    IconData icon;

    switch (resource.fileType.toLowerCase()) {
      case 'pdf':
        badgeColor = AppColors.pdfRed;
        icon = Icons.picture_as_pdf;
        break;
      case 'ppt':
      case 'pptx':
        badgeColor = AppColors.pptOrange;
        icon = Icons.slideshow;
        break;
      default:
        badgeColor = AppColors.otherBlue;
        icon = Icons.insert_drive_file;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            fileType,
            style: AppTextStyles.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get uploader name (first 8 characters of firebase_uid)
  String _getUploaderName() {
    if (resource.firebaseUid.length <= 8) {
      return resource.firebaseUid;
    }
    return '${resource.firebaseUid.substring(0, 8)}...';
  }

  /// Format date as "2 hours ago" or "Jan 15"
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
