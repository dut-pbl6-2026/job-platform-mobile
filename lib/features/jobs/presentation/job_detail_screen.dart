import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/models/user_model.dart';
import '../data/repositories/mock_job_repository.dart';
import '../domain/models/job_model.dart';
import '../domain/repositories/job_repository.dart';
import 'widgets/job_detail_bottom_bar.dart';
import 'widgets/job_detail_content.dart';
import 'widgets/job_detail_header.dart';
import 'widgets/job_detail_shimmer_loading.dart';

/// Job Detail Screen (MOB-01-03, JOB-01-05)
class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final IJobRepository? jobRepository;

  const JobDetailScreen({super.key, required this.jobId, this.jobRepository});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final IJobRepository _jobRepository;
  bool _isLoading = true;
  String? _errorMessage;
  JobModel? _job;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? MockJobRepository();
    _fetchJobDetail();
  }

  Future<void> _fetchJobDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      if (!mounted) return;

      if (job != null) {
        setState(() {
          _job = job;
          _isSaved = job.isSaved;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin tin tuyển dụng này.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBookmarkToggle() async {
    if (_job == null) return;
    final newStatus = await _jobRepository.toggleSaveJob(_job!.id);
    if (!mounted) return;

    setState(() {
      _isSaved = newStatus;
      _job = _job!.copyWith(isSaved: newStatus);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? 'Đã lưu tin tuyển dụng thành công!'
              : 'Đã bỏ lưu tin tuyển dụng',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare() {
    if (_job == null) return;
    final shareUrl = 'https://jobplatform.vn/jobs/${_job!.id}';
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép liên kết việc làm: $shareUrl',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePrimaryAction() {
    if (_job == null) return;

    final user = AuthSession.instance.currentUser;
    final isAuthenticated = AuthSession.instance.isAuthenticated;

    // 1. If Recruiter: Show application management preview
    if (user?.role == UserRole.recruiter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quản lý ${_job!.applicationCount} hồ sơ ứng tuyển (Chức năng Tuần 3)',
          ),
        ),
      );
      return;
    }

    // 2. If unauthenticated: prompt login
    if (!isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text(
            'Bạn cần đăng nhập tài khoản Ứng viên để nộp hồ sơ ứng tuyển.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.login);
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
      return;
    }

    // 3. If Candidate (UserRole.user): Navigate to application flow (MOB-01-04)
    _showApplyBottomSheet();
  }

  void _showApplyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ứng tuyển: ${_job!.title}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _job!.companyName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hồ sơ của bạn sẽ được gửi trực tiếp đến bộ phận tuyển dụng.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text(
                      'Đã nộp hồ sơ ứng tuyển vào ${_job!.companyName} thành công!',
                    ),
                  ),
                );
              },
              child: const Text('Xác nhận nộp hồ sơ'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết việc làm'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_job != null) ...[
            IconButton(
              icon: Icon(
                _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: _isSaved ? AppColors.primary : AppColors.textPrimary,
              ),
              tooltip: _isSaved ? 'Bỏ lưu' : 'Lưu tin',
              onPressed: _handleBookmarkToggle,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Chia sẻ',
              onPressed: _handleShare,
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: (_job != null && !_isLoading)
          ? JobDetailBottomBar(
              job: _job!,
              isSaved: _isSaved,
              onBookmarkToggle: _handleBookmarkToggle,
              onShare: _handleShare,
              onPrimaryAction: _handlePrimaryAction,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const JobDetailShimmerLoading();
    }

    if (_errorMessage != null || _job == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _fetchJobDetail,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailHeader(job: _job!),
            JobDetailContent(job: _job!),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Không tìm thấy việc làm',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tin tuyển dụng có thể đã hết hạn hoặc bị gỡ bởi nhà tuyển dụng.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Quay lại danh sách'),
            ),
          ],
        ),
      ),
    );
  }
}
