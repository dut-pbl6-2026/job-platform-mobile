import 'package:flutter/material.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/job_model.dart';

/// Sticky Bottom Action Bar for Job Detail screen with dynamic RBAC support (MOB-01-03)
class JobDetailBottomBar extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final VoidCallback onPrimaryAction;

  const JobDetailBottomBar({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final isRecruiter = user?.role == UserRole.recruiter;
    final isAdmin = user?.role == UserRole.admin;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Bookmark / Save Button
          InkWell(
            onTap: onBookmarkToggle,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSaved
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSaved ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. Share Button
          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.share_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 3. Dynamic Role-Based Primary Action CTA
          Expanded(
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecruiter
                    ? AppColors.secondary
                    : isAdmin
                    ? AppColors.warning
                    : AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRecruiter
                        ? Icons.people_outline_rounded
                        : isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRecruiter
                        ? 'Xem ứng viên (${job.applicationCount})'
                        : isAdmin
                        ? 'Kiểm duyệt tin'
                        : 'Ứng tuyển ngay',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
