import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/models/user_model.dart';
import '../data/repositories/api_job_repository.dart';
import '../domain/models/job_model.dart';
import '../domain/repositories/job_repository.dart';
import 'widgets/job_detail_bottom_bar.dart';
import 'widgets/job_detail_content.dart';
import 'widgets/job_detail_header.dart';
import 'widgets/job_detail_shimmer_loading.dart';
import '../../applications/presentation/apply_job_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? ApiJobRepository();
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

    final role = AuthSession.instance.resolvedRole;
    final isAuthenticated = AuthSession.instance.isAuthenticated;

    // 1. If Recruiter: Navigate directly to candidate applications for this job (APP-01-05)
    if (role == UserRole.recruiter) {
      context.push(
        Uri(
          path: AppRoutes.recruiterCandidates,
          queryParameters: {'jobId': _job!.id},
        ).toString(),
      );
      return;
    }

    // 2. If Admin: Read-only notice on mobile (moderation is managed via Web Admin portal)
    if (role == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chức năng kiểm duyệt tin tuyển dụng thuộc cổng Quản trị Web.',
          ),
        ),
      );
      return;
    }

    // 3. If unauthenticated: prompt login
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
    if (role == UserRole.user) {
      _showApplyBottomSheet();
    }
  }

  void _showApplyBottomSheet() {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        '/jobs/${_job!.id}/apply',
        extra: {
          'title': _job!.title,
          'company': _job!.companyName,
          'logo': _job!.companyLogo,
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ApplyJobScreen(
            jobId: _job!.id,
            jobTitle: _job!.title,
            companyName: _job!.companyName,
            companyLogo: _job!.companyLogo,
          ),
        ),
      );
    }
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
