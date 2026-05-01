import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Type of chip to determine styling
enum ChipType {
  subject,
  topic,
}

/// A styled chip widget for displaying subject or topic names
/// with appropriate colors and styling
class SubjectChip extends StatelessWidget {
  final String label;
  final ChipType type;

  const SubjectChip({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine colors based on chip type
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ChipType.subject:
        backgroundColor = isDark 
            ? AppColors.chipSubject.withOpacity(0.2)
            : AppColors.chipSubjectBg;
        textColor = AppColors.chipSubject;
        icon = Icons.book_outlined;
        break;
      case ChipType.topic:
        backgroundColor = isDark
            ? AppColors.chipTopic.withOpacity(0.2)
            : AppColors.chipTopicBg;
        textColor = AppColors.chipTopic;
        icon = Icons.label_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
