import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/models/job_model.dart';

/// Material 3 Job Card component displaying job post details (MOB-01-02)
class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkToggle;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final salaryText = FormatUtils.formatSalaryRange(
      min: job.salaryMin,
      max: job.salaryMax,
      isNegotiable: job.isSalaryNegotiable,
    );

    final timeAgoText = FormatUtils.timeAgo(job.postedAt);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: job.isSaved
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: job.isSaved ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Company Avatar + Title & Company + Bookmark button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Avatar / Initials
                  _buildCompanyLogo(context),
                  const SizedBox(width: 12),
                  // Title & Company Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.companyName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bookmark button
                  IconButton(
                    icon: Icon(
                      job.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: job.isSaved ? AppColors.primary : AppColors.textHint,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: job.isSaved ? 'Bỏ lưu tin' : 'Lưu tin tuyển dụng',
                    onPressed: onBookmarkToggle,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Middle Row: Salary Badge & Location
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Salary badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          salaryText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.location,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tags & Skills row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Job Type tag
                  _buildTag(
                    job.jobType.displayName,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    textColor: AppColors.secondary,
                  ),
                  // Experience Level tag
                  _buildTag(
                    job.experienceLevel.displayName,
                    backgroundColor: AppColors.surfaceVariant,
                    textColor: AppColors.textSecondary,
                  ),
                  // Skills chips (up to 2)
                  ...job.skills.take(2).map(
                        (skill) => _buildTag(
                          skill,
                          backgroundColor: Colors.transparent,
                          textColor: AppColors.textSecondary,
                          borderColor: AppColors.border,
                        ),
                      ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),

              // Bottom footer: Time ago and application count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgoText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  if (job.applicationCount > 0)
                    Text(
                      '${job.applicationCount} ứng viên đã nộp',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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

  Widget _buildCompanyLogo(BuildContext context) {
    final initial = job.companyName.isNotEmpty
        ? job.companyName[0].toUpperCase()
        : 'C';

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTag(
    String text, {
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
