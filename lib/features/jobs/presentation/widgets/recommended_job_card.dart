import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/bookmark_button.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../domain/models/recommended_job_model.dart';

/// Commercial-grade Recommended Job Card widget with match score and rationale (RECOMMEND-01, W13)
class RecommendedJobCard extends StatelessWidget {
  final RecommendedJob recommendation;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarkLoading;

  const RecommendedJobCard({
    super.key,
    required this.recommendation,
    required this.onTap,
    this.onBookmarkToggle,
    this.isBookmarkLoading = false,
  });

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF0D9488); // Teal / Emerald
    if (score >= 70) return AppColors.primary; // Blue
    if (score >= 50) return const Color(0xFFD97706); // Amber
    return AppColors.error;
  }

  IconData _getReasonIcon(String? matchType) {
    switch (matchType?.toLowerCase()) {
      case 'skills':
        return Icons.auto_awesome_rounded;
      case 'trending':
        return Icons.local_fire_department_rounded;
      case 'search_history':
      case 'history':
        return Icons.history_rounded;
      case 'location':
        return Icons.place_rounded;
      case 'saved_jobs':
        return Icons.bookmark_added_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _getReasonTag(String? matchType) {
    switch (matchType?.toLowerCase()) {
      case 'skills':
        return 'Kỹ năng tương thích';
      case 'trending':
        return 'Xu hướng tuần';
      case 'search_history':
      case 'history':
        return 'Tìm kiếm gần đây';
      case 'location':
        return 'Gần bạn';
      case 'saved_jobs':
        return 'Tương tự đã lưu';
      default:
        return 'Đề xuất AI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = recommendation.job;
    final scoreColor = _getScoreColor(recommendation.matchScore);
    final reasonTag = _getReasonTag(recommendation.matchType);
    final reasonIcon = _getReasonIcon(recommendation.matchType);

    final salaryText = FormatUtils.formatSalaryRange(
      min: job.salaryMin,
      max: job.salaryMax,
      isNegotiable: job.isSalaryNegotiable,
    );

    return PressableCard(
      onTap: onTap,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: job.isSaved
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
            width: job.isSaved ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Match Reason Pill + Match Score Gauge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reason Pill
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(reasonIcon, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              reasonTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Match Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: scoreColor),
                        const SizedBox(width: 2),
                        Text(
                          '${recommendation.matchScore}% Phù hợp',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Company Info & Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo / Avatar
                  _buildCompanyAvatar(job.companyName, job.companyLogo),
                  const SizedBox(width: 10),
                  // Company Name & Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                job.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bookmark Button
                  BookmarkButton(
                    isSaved: job.isSaved,
                    onToggle: isBookmarkLoading ? null : onBookmarkToggle,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Job Title
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),

              // Salary & Job Type
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    salaryText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    job.jobType.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recommendation Narrative Rationale Callout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        recommendation.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyAvatar(String companyName, String? logoUrl) {
    final initials = companyName.isNotEmpty
        ? companyName.trim().substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
