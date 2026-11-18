import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../constants/account_menu_strings.dart';
import '../router/app_router.dart';
import '../session/auth_session.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// Account menu shown from the home header avatar.
///
/// Profile is available to every role; Applications and Company are filtered by
/// the resolved role. There is no admin screen yet, so no Admin entry is shown.
class AccountMenuSheet extends StatelessWidget {
  const AccountMenuSheet({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSignOut,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AccountMenuSheet(onSignOut: onSignOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final role = AuthSession.instance.resolvedRole;
    final router = GoRouter.of(context);

    void open(String route) {
      Navigator.of(context).pop();
      router.push(route);
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AccountHeader(user: user, role: role),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              key: const Key('account_menu_profile'),
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text(AccountMenuStrings.profile),
              onTap: () => open(AppRoutes.profile),
            ),
            if (role == UserRole.user) ...[
              ListTile(
                key: const Key('account_menu_applications'),
                leading: const Icon(Icons.history_edu_outlined),
                title: const Text(AccountMenuStrings.applications),
                onTap: () => open(AppRoutes.applications),
              ),
              ListTile(
                key: const Key('account_menu_join_request'),
                leading: const Icon(Icons.domain_add_outlined),
                title: const Text(AccountMenuStrings.joinRequest),
                onTap: () => open(AppRoutes.myJoinRequest),
              ),
            ],
            if (role == UserRole.recruiter) ...[
              ListTile(
                key: const Key('account_menu_recruiter_dashboard'),
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text(AccountMenuStrings.recruiterDashboard),
                onTap: () => open(AppRoutes.recruiterDashboard),
              ),
              ListTile(
                key: const Key('account_menu_recruiter_jobs'),
                leading: const Icon(Icons.work_outline_rounded),
                title: const Text(AccountMenuStrings.recruiterJobs),
                onTap: () => open(AppRoutes.recruiterJobs),
              ),
              ListTile(
                key: const Key('account_menu_company'),
                leading: const Icon(Icons.apartment_outlined),
                title: const Text(AccountMenuStrings.company),
                onTap: () => open(AppRoutes.companyProfile),
              ),
            ],
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              key: const Key('account_menu_sign_out'),
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                AccountMenuStrings.signOut,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onSignOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user, required this.role});

  final UserModel? user;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    final email = user?.email.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: [
          UserAvatar(name: user?.name, imageUrl: user?.avatarUrl, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name.isNotEmpty == true
                      ? user!.name
                      : AccountMenuStrings.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : AccountMenuStrings.noEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (role != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role!.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
