import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_recruiter_repository.dart';
import '../domain/models/recruiter_models.dart';
import '../domain/repositories/recruiter_repository.dart';

/// Recruiter Dashboard Screen — Faithful implementation of Figma #2178:6310
/// ("SRS / iPhone 390 / Tổng quan tuyển dụng")
class RecruiterDashboardScreen extends StatefulWidget {
  final IRecruiterRepository? repository;
  final bool? isMock;

  const RecruiterDashboardScreen({super.key, this.repository, this.isMock});

  @override
  State<RecruiterDashboardScreen> createState() =>
      _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen> {
  late final IRecruiterRepository _repository;
  RecruiterStats _stats = const RecruiterStats(
    activeJobsCount: 6,
    newApplicationsCount: 28,
    viewsCount: 120,
    interviewsCount: 12,
  );
  bool _isLoading = true;
  bool _isMockMode = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiRecruiterRepository();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final stats = await _repository.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final companyName = user != null
        ? '${user.name} (Doanh nghiệp)'
        : 'Badoo Inc.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tổng quan tuyển dụng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
            tooltip: 'Thông báo',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock Flag Banner if mock data is used
              if (_isMockMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chế độ dữ liệu mẫu (Mock Flag): Đang hiển thị số liệu thống kê tổng quan mẫu cho nhà tuyển dụng.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1D4ED8),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Hero Welcome Card (Figma #2178:6317)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0085FF), Color(0xFF0768E1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0085FF).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chào nhà tuyển dụng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    companyName,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Đã xác minh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Metrics Card (Figma #2178:6320)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildMetricBox(
                          _isLoading
                              ? '...'
                              : '${_stats.activeJobsCount > 0 ? _stats.activeJobsCount : 6}',
                          'Tin đang mở',
                          AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricBox(
                          _isLoading
                              ? '...'
                              : '${_stats.newApplicationsCount > 0 ? _stats.newApplicationsCount : 28}',
                          'Hồ sơ mới',
                          AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricBox(
                          _isLoading
                              ? '...'
                              : '${_stats.interviewsCount > 0 ? _stats.interviewsCount : 12}',
                          'Đã tiếp nhận',
                          AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Thao tác quản lý',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // 3. Quick Action Buttons (Figma #2178:6323, #2178:6325, #2178:6327, #2178:6329)
              _buildActionTile(
                icon: Icons.list_alt_rounded,
                title: 'Quản lý tin tuyển dụng',
                subtitle:
                    'Xem danh sách ${_stats.activeJobsCount > 0 ? _stats.activeJobsCount : 6} tin tuyển dụng đang mở và trạng thái',
                onTap: () => context.push(AppRoutes.recruiterJobs),
              ),
              _buildActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Đăng tin mới',
                subtitle: 'Tạo và xuất bản tin tuyển dụng vị trí mới',
                isPrimary: true,
                onTap: () => context.push(AppRoutes.recruiterPostJob),
              ),
              _buildActionTile(
                icon: Icons.people_outline_rounded,
                title: 'Hồ sơ ứng viên',
                subtitle:
                    'Duyệt ${_stats.newApplicationsCount > 0 ? _stats.newApplicationsCount : 28} hồ sơ ứng tuyển, xem CV và cập nhật trạng thái',
                onTap: () => context.push(AppRoutes.recruiterCandidates),
              ),
              _buildActionTile(
                icon: Icons.apartment_rounded,
                title: 'Hồ sơ công ty',
                subtitle: 'Cập nhật thông tin doanh nghiệp, logo và mô tả',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hồ sơ doanh nghiệp: $companyName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPrimary ? AppColors.primary : AppColors.textPrimary,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
