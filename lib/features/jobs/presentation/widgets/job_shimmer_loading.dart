import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated skeleton loading placeholder for job cards (Material 3 style)
class JobShimmerLoading extends StatefulWidget {
  final int itemCount;

  const JobShimmerLoading({
    super.key,
    this.itemCount = 5,
  });

  @override
  State<JobShimmerLoading> createState() => _JobShimmerLoadingState();
}

class _JobShimmerLoadingState extends State<JobShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildSkeletonCard(opacity),
        );
      },
    );
  }

  Widget _buildSkeletonCard(double opacity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Logo placeholder + Title/Company lines
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBox(width: 48, height: 48, radius: 12, opacity: opacity),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBox(
                      width: double.infinity,
                      height: 16,
                      radius: 4,
                      opacity: opacity,
                    ),
                    const SizedBox(height: 8),
                    _buildBox(width: 140, height: 13, radius: 4, opacity: opacity),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBox(width: 24, height: 24, radius: 12, opacity: opacity),
            ],
          ),
          const SizedBox(height: 14),
          // Salary & Location pills
          Row(
            children: [
              _buildBox(width: 120, height: 24, radius: 8, opacity: opacity),
              const SizedBox(width: 8),
              _buildBox(width: 90, height: 24, radius: 8, opacity: opacity),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          // Bottom row: tag chips + relative time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBox(width: 60, height: 20, radius: 6, opacity: opacity),
                  const SizedBox(width: 6),
                  _buildBox(width: 70, height: 20, radius: 6, opacity: opacity),
                ],
              ),
              _buildBox(width: 65, height: 14, radius: 4, opacity: opacity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBox({
    required double width,
    required double height,
    required double radius,
    required double opacity,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: opacity * 0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
