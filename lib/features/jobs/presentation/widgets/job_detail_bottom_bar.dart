import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/job_model.dart';

/// Sticky Bottom Action Bar for Job Detail screen with dynamic RBAC support (MOB-01-03)
class JobDetailBottomBar extends StatelessWidget {
  final JobModel job;
  final VoidCallback onShare;
  final VoidCallback onPrimaryAction;

  const JobDetailBottomBar({
    super.key,
    required this.job,
    required this.onShare,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final role = AuthSession.instance.resolvedRole;
    final isRecruiter = role == UserRole.recruiter;
    final isAdmin = role == UserRole.admin;
    final isExternalDisabled =
        !isRecruiter && !isAdmin && job.isExternalCrawledJob;

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
          // 1. Share Button
          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.share_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 3. Dynamic Role-Based Primary Action CTA (Figma #55:3973)
          Expanded(
            child: ElevatedButton(
              onPressed: isExternalDisabled ? null : onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecruiter
                    ? AppColors.secondary
                    : isAdmin
                    ? AppColors.warning
                    : AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
                        : isExternalDisabled
                        ? Icons.public_rounded
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
                        : isExternalDisabled
                        ? 'Tin tổng hợp ngoài hệ thống'
                        : 'Ứng tuyển ngay',
                    style: const TextStyle(
                      fontSize: 14.5,
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
