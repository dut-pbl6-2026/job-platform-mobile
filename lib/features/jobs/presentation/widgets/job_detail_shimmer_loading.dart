import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated skeleton loading placeholder for Job Detail screen (Material 3 style)
class JobDetailShimmerLoading extends StatefulWidget {
  const JobDetailShimmerLoading({super.key});

  @override
  State<JobDetailShimmerLoading> createState() =>
      _JobDetailShimmerLoadingState();
}

class _JobDetailShimmerLoadingState extends State<JobDetailShimmerLoading>
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

    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo & name skeleton
              Row(
                children: [
                  _buildBox(
                    width: 60,
                    height: 60,
                    radius: 16,
                    opacity: opacity,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBox(
                          width: double.infinity,
                          height: 20,
                          radius: 4,
                          opacity: opacity,
                        ),
                        const SizedBox(height: 8),
                        _buildBox(
                          width: 140,
                          height: 14,
                          radius: 4,
                          opacity: opacity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title skeleton
              _buildBox(
                width: double.infinity,
                height: 24,
                radius: 6,
                opacity: opacity,
              ),
              const SizedBox(height: 8),
              _buildBox(width: 200, height: 24, radius: 6, opacity: opacity),
              const SizedBox(height: 20),

              // Key metrics card skeleton
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildBox(
                            width: double.infinity,
                            height: 48,
                            radius: 10,
                            opacity: opacity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBox(
                            width: double.infinity,
                            height: 48,
                            radius: 10,
                            opacity: opacity,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBox(
                            width: double.infinity,
                            height: 48,
                            radius: 10,
                            opacity: opacity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBox(
                            width: double.infinity,
                            height: 48,
                            radius: 10,
                            opacity: opacity,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Description
              _buildBox(width: 160, height: 18, radius: 4, opacity: opacity),
              const SizedBox(height: 12),
              _buildBox(
                width: double.infinity,
                height: 14,
                radius: 4,
                opacity: opacity,
              ),
              const SizedBox(height: 6),
              _buildBox(
                width: double.infinity,
                height: 14,
                radius: 4,
                opacity: opacity,
              ),
              const SizedBox(height: 6),
              _buildBox(width: 240, height: 14, radius: 4, opacity: opacity),
              const SizedBox(height: 24),

              // Section 2: Requirements
              _buildBox(width: 160, height: 18, radius: 4, opacity: opacity),
              const SizedBox(height: 12),
              _buildBox(
                width: double.infinity,
                height: 14,
                radius: 4,
                opacity: opacity,
              ),
              const SizedBox(height: 6),
              _buildBox(
                width: double.infinity,
                height: 14,
                radius: 4,
                opacity: opacity,
              ),
              const SizedBox(height: 20),

              // Skill chips skeleton
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  4,
                  (index) => _buildBox(
                    width: 80,
                    height: 28,
                    radius: 8,
                    opacity: opacity,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
