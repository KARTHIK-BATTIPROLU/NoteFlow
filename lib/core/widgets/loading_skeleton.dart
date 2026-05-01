import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmer-style loading placeholder for resource cards
/// Uses AnimationController for smooth shimmer effect
class LoadingSkeleton extends StatefulWidget {
  final int count;

  const LoadingSkeleton({
    super.key,
    this.count = 3,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: widget.count,
      shrinkWrap: true, // Important: allows ListView to size itself
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling since parent handles it
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title skeleton
                    Row(
                      children: [
                        Expanded(
                          child: _buildShimmerBox(
                            height: 24,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildShimmerBox(
                          height: 24,
                          width: 60,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Chips skeleton
                    Row(
                      children: [
                        _buildShimmerBox(
                          height: 24,
                          width: 80,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildShimmerBox(
                          height: 24,
                          width: 100,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    const Divider(height: 1),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Footer skeleton
                    Row(
                      children: [
                        _buildShimmerBox(
                          height: 16,
                          width: 80,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildShimmerBox(
                          height: 16,
                          width: 60,
                        ),
                        const Spacer(),
                        _buildShimmerBox(
                          height: 16,
                          width: 30,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildShimmerBox(
                          height: 16,
                          width: 30,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double height,
    required double width,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surfaceDark : AppColors.divider;
    final highlightColor = isDark 
        ? AppColors.dividerDark 
        : AppColors.surface;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}
