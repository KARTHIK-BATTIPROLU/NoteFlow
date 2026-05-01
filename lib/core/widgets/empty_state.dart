import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A centered empty state widget with illustration and message
/// Uses CustomPainter for SVG-style illustration
class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            CustomPaint(
              size: const Size(200, 200),
              painter: _EmptyStatePainter(
                color: AppColors.primary.withOpacity(0.1),
                accentColor: AppColors.primary,
                icon: icon,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Message
            Text(
              message,
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter for empty state illustration
class _EmptyStatePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final IconData? icon;

  _EmptyStatePainter({
    required this.color,
    required this.accentColor,
    this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    canvas.drawCircle(center, radius, paint);

    // Draw accent circle outline
    canvas.drawCircle(center, radius * 0.8, accentPaint);

    // Draw icon if provided
    if (icon != null) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            fontSize: size.width * 0.4,
            fontFamily: icon!.fontFamily,
            color: accentColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - iconPainter.width / 2,
          center.dy - iconPainter.height / 2,
        ),
      );
    } else {
      // Draw default illustration (document with magnifying glass)
      _drawDefaultIllustration(canvas, size, center, accentPaint);
    }
  }

  void _drawDefaultIllustration(
    Canvas canvas,
    Size size,
    Offset center,
    Paint paint,
  ) {
    // Draw document shape
    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.4,
        height: size.height * 0.5,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(docRect, paint);

    // Draw document lines
    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final y = center.dy - size.height * 0.15 + (i * size.height * 0.08);
      canvas.drawLine(
        Offset(center.dx - size.width * 0.15, y),
        Offset(center.dx + size.width * 0.15, y),
        linePaint,
      );
    }

    // Draw magnifying glass
    final glassCenter = Offset(
      center.dx + size.width * 0.15,
      center.dy + size.height * 0.15,
    );
    canvas.drawCircle(glassCenter, size.width * 0.08, paint);
    
    // Draw magnifying glass handle
    final handlePath = Path()
      ..moveTo(
        glassCenter.dx + size.width * 0.06,
        glassCenter.dy + size.height * 0.06,
      )
      ..lineTo(
        glassCenter.dx + size.width * 0.12,
        glassCenter.dy + size.height * 0.12,
      );
    canvas.drawPath(handlePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
