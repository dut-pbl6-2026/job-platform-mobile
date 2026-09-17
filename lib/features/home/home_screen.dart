import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../auth/data/repositories/api_auth_repository.dart';
import '../auth/domain/models/user_model.dart';
import '../auth/domain/repositories/auth_repository.dart';
import '../jobs/data/repositories/mock_job_repository.dart';
import '../jobs/domain/models/job_filter_params.dart';
import '../jobs/domain/models/job_model.dart';
import '../jobs/domain/repositories/job_repository.dart';
import '../jobs/presentation/widgets/job_card.dart';
import '../jobs/presentation/widgets/job_filter_bottom_sheet.dart';

/// Commercial-grade Home Dashboard matching production mobile design (Figure 3)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.authRepository, this.jobRepository});

  final IAuthRepository? authRepository;
  final IJobRepository? jobRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final IAuthRepository _authRepository;
  late final IJobRepository _jobRepository;

  bool _isLoggingOut = false;
  bool _isLoadingJobs = true;
  List<JobModel> _featuredJobs = [];
  String _selectedPill = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? ApiAuthRepository();
    _jobRepository = widget.jobRepository ?? MockJobRepository();
    _loadFeaturedJobs();
  }

  Future<void> _loadFeaturedJobs() async {
    try {
      final result = await _jobRepository.getJobs(
        const JobFilterParams(pageSize: 5),
      );
      if (mounted) {
        setState(() {
          _featuredJobs = result.items;
          _isLoadingJobs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      setState(() => _isLoggingOut = true);
      await _authRepository.logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  void _openFilter() {
    JobFilterBottomSheet.show(
      context,
      currentParams: const JobFilterParams(),
      onApply: (params) {
        context.go(AppRoutes.jobs);
      },
    );
  }

  void _handlePillTap(String pill) {
    setState(() => _selectedPill = pill);
    context.go(AppRoutes.jobs);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final isRecruiter = user?.role == UserRole.recruiter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeaturedJobs,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top App Header Bar (Avatar + Name + Notification & Message icons)
                _buildTopHeader(user),

                // 2. Search Bar + Integrated Filter Trigger
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 14),

                // 3. Category & Filter Pills Bar (Figure 3)
                _buildFilterPills(),
                const SizedBox(height: 18),

                // 4. AI Skill Match Banner (90% Match Banner from Figure 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAiMatchBanner(),
                ),
                const SizedBox(height: 20),

                // 5. Quick Functional Shortcuts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickShortcuts(isRecruiter),
                ),
                const SizedBox(height: 22),

                // 6. Featured & Recommended Jobs Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Việc làm đề xuất',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go(AppRoutes.jobs),
                        child: const Row(
                          children: [
                            Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Job cards list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildJobsList(),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Modern Top Header (Figure 3) ---
  Widget _buildTopHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // User Avatar with Status indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name and greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.name ?? 'Ứng viên',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user?.role.displayName ?? 'Tìm kiếm cơ hội mới',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Header action buttons (Notification, Message, Logout)
          IconButton(
            icon: const Badge(
              smallSize: 8,
              backgroundColor: AppColors.error,
              child: Icon(Icons.notifications_none_rounded, size: 24),
            ),
            tooltip: 'Thông báo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Trung tâm thông báo (Phase 2 đang phát triển)',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.forum_outlined, size: 22),
            tooltip: 'AI Copilot',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tính năng AI Job Copilot (Phase 3 đang phát triển)',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
            tooltip: 'Đăng xuất',
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
    );
  }

  // --- 2. Search Bar with Filter Button ---
  Widget _buildSearchBar() {
    return InkWell(
      onTap: () => context.go(AppRoutes.jobs),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tìm kiếm công việc, công ty, kỹ năng...',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(height: 24, width: 1, color: AppColors.border),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Bộ lọc',
              onPressed: _openFilter,
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Filter / Category Pills Bar (Figure 3) ---
  Widget _buildFilterPills() {
    final pills = [
      'Tất cả',
      'Địa điểm',
      'Từ xa (Remote)',
      'Lương cao (30M+)',
      'IT / Phần mềm',
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pills.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pill = pills[index];
          final isSelected = _selectedPill == pill;

          return ChoiceChip(
            label: Text(
              pill,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
            onSelected: (_) => _handlePillTap(pill),
          );
        },
      ),
    );
  }

  // --- 4. 90% Skill Match AI Banner (Inspired by Figure 3) ---
  Widget _buildAiMatchBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '90% MATCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Cá nhân hóa cho bạn',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Hồ sơ của bạn phù hợp với các cơ hội hàng đầu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Navigation CTA icon
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            onPressed: () => context.go(AppRoutes.jobs),
          ),
        ],
      ),
    );
  }

  // --- 5. Quick Shortcuts ---
  Widget _buildQuickShortcuts(bool isRecruiter) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactCard(
            icon: isRecruiter
                ? Icons.add_business_rounded
                : Icons.note_add_outlined,
            title: isRecruiter ? 'Đăng tin' : 'Tạo CV',
            subtitle: isRecruiter ? 'Tuyển dụng mới' : 'Mẫu chuẩn ATS',
            color: AppColors.primary,
            onTap: () {
              if (isRecruiter) {
                context.go(AppRoutes.jobs);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tính năng Tạo CV (Đang phát triển trong Sprint tiếp theo)',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactCard(
            icon: Icons.person_outline_rounded,
            title: 'Hồ sơ',
            subtitle: 'CV & Kỹ năng',
            color: AppColors.secondary,
            onTap: () => context.go(AppRoutes.profile),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactCard(
            icon: Icons.history_edu_rounded,
            title: 'Ứng tuyển',
            subtitle: 'Theo dõi đơn',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go(AppRoutes.applications),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Jobs List ---
  Widget _buildJobsList() {
    if (_isLoadingJobs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_featuredJobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Chưa có việc làm đề xuất',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _featuredJobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = _featuredJobs[index];
        return JobCard(
          job: job,
          onTap: () => context.push('${AppRoutes.jobs}/${job.id}'),
          onBookmarkToggle: () async {
            await _jobRepository.toggleSaveJob(job.id);
            _loadFeaturedJobs();
          },
        );
      },
    );
  }
}
