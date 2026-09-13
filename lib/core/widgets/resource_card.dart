import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/resource.dart';
import '../services/api_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import 'subject_chip.dart';

/// A beautiful card widget that displays a single resource
/// with file type badge, title, subject/topic chips, metadata, and tap interaction
class ResourceCard extends ConsumerStatefulWidget {
  final Resource resource;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
  });

  @override
  ConsumerState<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends ConsumerState<ResourceCard> {
  late int _likesCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.resource.likes;
  }

  Future<void> _handleLike() async {
    if (_isLiked) return;
    setState(() {
      _isLiked = true;
      _likesCount += 1;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final updated = await apiService.likeResource(widget.resource.id);
      if (mounted) {
        setState(() {
          _likesCount = updated;
        });
        Toast.show(context, 'Liked "${widget.resource.title}"');
      }
    } catch (e) {
      // Keep optimistic count
    }
  }

  void _handleShare() async {
    final title = widget.resource.title;
    final subject = widget.resource.subjectName ?? 'General';
    final topic = widget.resource.topicName ?? 'Notes';
    final uploader = widget.resource.uploaderHandle ?? 'student';

    final shareText =
        'Check out "$title" on NoteFlow!\n'
        'Subject: $subject | Topic: $topic\n'
        'Shared by: @$uploader';

    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      Toast.show(context, 'Note details copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
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
                      widget.resource.title,
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
                  if (widget.resource.subjectName != null)
                    SubjectChip(
                      label: widget.resource.subjectName!,
                      type: ChipType.subject,
                    ),
                  if (widget.resource.topicName != null)
                    SubjectChip(
                      label: widget.resource.topicName!,
                      type: ChipType.topic,
                    ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Divider
              const Divider(height: 1),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Footer: Uploader, Date, Stats & Actions
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
                    _formatDate(widget.resource.uploadedAt),
                    style: AppTextStyles.bodySmall,
                  ),
                  
                  const Spacer(),
                  
                  // Download Count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${widget.resource.downloads}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Interactive Like Button
                  InkWell(
                    onTap: _handleLike,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_outline,
                            size: 16,
                            color: _isLiked ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$_likesCount',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _isLiked ? AppColors.error : null,
                              fontWeight: _isLiked ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Interactive Share Button
                  InkWell(
                    onTap: _handleShare,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
    final fileType = widget.resource.fileType.toUpperCase();
    Color badgeColor;
    IconData icon;

    switch (widget.resource.fileType.toLowerCase()) {
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
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
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

  /// Get uploader name (pseudonymous handle or truncated uid)
  String _getUploaderName() {
    if (widget.resource.uploaderHandle != null && widget.resource.uploaderHandle!.isNotEmpty) {
      return widget.resource.uploaderHandle!;
    }
    if (widget.resource.firebaseUid.length <= 8) {
      return widget.resource.firebaseUid;
    }
    return '${widget.resource.firebaseUid.substring(0, 8)}...';
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
