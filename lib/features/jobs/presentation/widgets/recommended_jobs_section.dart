import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/job_model.dart';
import '../../domain/models/recommended_job_model.dart';
import 'recommended_job_card.dart';

/// Horizontal personalized recommendations section with refresh and shimmer (RECOMMEND-01, W13)
class RecommendedJobsSection extends StatefulWidget {
  final List<RecommendedJob> recommendations;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<RecommendedJob> onJobTap;
  final ValueChanged<JobModel>? onBookmarkToggle;
  final Set<String> savingIds;

  const RecommendedJobsSection({
    super.key,
    required this.recommendations,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onJobTap,
    this.onBookmarkToggle,
    this.savingIds = const {},
  });

  @override
  State<RecommendedJobsSection> createState() => _RecommendedJobsSectionState();
}

class _RecommendedJobsSectionState extends State<RecommendedJobsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isManualRefreshing || widget.isLoading) return;
    setState(() => _isManualRefreshing = true);
    _spinController.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
        setState(() => _isManualRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading &&
        widget.errorMessage == null &&
        widget.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Việc làm gợi ý cho bạn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Cá nhân hóa theo hồ sơ và kỹ năng của bạn',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Refresh Button with rotational animation
            IconButton(
              key: const Key('refresh_recommendations_button'),
              tooltip: 'Làm mới gợi ý',
              visualDensity: VisualDensity.compact,
              icon: RotationTransition(
                turns: _spinController,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: (_isManualRefreshing || widget.isLoading)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              onPressed: (_isManualRefreshing || widget.isLoading)
                  ? null
                  : _handleRefresh,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Section Content
        if (widget.isLoading)
          const RecommendedJobsShimmer()
        else if (widget.errorMessage != null)
          _buildErrorCard()
        else
          _buildRecommendationsList(),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final listHeight = textScale > 1.0
        ? (260.0 + (textScale - 1.0) * 80.0)
        : 260.0;

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        key: const Key('recommended_jobs_list'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.recommendations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = widget.recommendations[index];
          final isSaving = widget.savingIds.contains(item.job.id);

          return RecommendedJobCard(
            key: Key('recommended_job_${item.job.id}'),
            recommendation: item,
            onTap: () => widget.onJobTap(item),
            onBookmarkToggle: widget.onBookmarkToggle != null
                ? () => widget.onBookmarkToggle!(item.job)
                : null,
            isBookmarkLoading: isSaving,
          );
        },
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleRefresh,
            child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder loader for recommended jobs cards
class RecommendedJobsShimmer extends StatefulWidget {
  const RecommendedJobsShimmer({super.key});

  @override
  State<RecommendedJobsShimmer> createState() => _RecommendedJobsShimmerState();
}

class _RecommendedJobsShimmerState extends State<RecommendedJobsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final shimmerHeight = textScale > 1.0
        ? (260.0 + (textScale - 1.0) * 80.0)
        : 260.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.35);
        return SizedBox(
          height: shimmerHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Container(
              width: 300,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(
                                alpha: opacity,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(
                                alpha: opacity,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
