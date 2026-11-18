import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_recruiter_repository.dart';
import '../domain/models/recruiter_models.dart';
import '../domain/repositories/recruiter_repository.dart';
import 'post_job_screen.dart';

/// Recruiter Job Postings Management Screen — Faithful implementation of Figma #2178:6337
/// ("SRS / iPhone 390 / Tin tuyển dụng của tôi")
class RecruiterJobsScreen extends StatefulWidget {
  final IRecruiterRepository? repository;
  final bool? isMock;

  const RecruiterJobsScreen({super.key, this.repository, this.isMock});

  @override
  State<RecruiterJobsScreen> createState() => _RecruiterJobsScreenState();
}

class _RecruiterJobsScreenState extends State<RecruiterJobsScreen> {
  static const int _pageSize = 20;

  late final IRecruiterRepository _repository;
  List<RecruiterJob> _jobs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _selectedStatus;
  String? _errorMessage;
  bool _isMockMode = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiRecruiterRepository();
    _fetchJobs();
  }

  Future<void> _fetchJobs({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    try {
      final items = await _repository.getMyJobs(
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          if (resetPage) {
            _jobs = items;
          } else {
            _jobs = [..._jobs, ...items];
          }
          _hasMore = items.length >= _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = failureMessage(
            e,
            fallback: 'Không tải được tin tuyển dụng. Vui lòng thử lại.',
          );
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage += 1;
    });
    await _fetchJobs(resetPage: false);
  }

  Future<void> _openCreateOrEdit({RecruiterJob? job}) async {
    bool? changed;
    if (GoRouter.maybeOf(context) != null) {
      changed = await context.push<bool>(
        AppRoutes.recruiterPostJob,
        extra: job,
      );
    } else {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              PostJobScreen(repository: _repository, initialJob: job),
        ),
      );
    }
    if (changed == true && mounted) {
      await _fetchJobs(resetPage: true);
    }
  }

  Future<void> _confirmAndDeleteJob(RecruiterJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa tin tuyển dụng'),
        content: Text(
          'Bạn có chắc chắn muốn đóng / xóa tin "${job.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa tin'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteJob(job.id);
      if (!mounted) return;
      setState(() {
        _jobs = _jobs.where((j) => j.id != job.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa tin tuyển dụng: ${job.title}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            raw.isNotEmpty && !raw.contains('DioException')
                ? raw
                : 'Không thể xóa tin tuyển dụng lúc này. Vui lòng thử lại.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _jobs.where((j) => j.isOpen).length;
    final closedCount = _jobs.where((j) => j.isClosed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tin tuyển dụng của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateOrEdit(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo tin mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchJobs,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Flag Banner
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
                                'Chế độ dữ liệu mẫu (Mock Flag): Đang hiển thị danh sách tin tuyển dụng mẫu cho nhà tuyển dụng.',
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

                    // 1. Status Overview Card (Figma #2178:6344)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active · Closed',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$openCount tin đang mở · $closedCount tin đã đóng',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Danh sách tin đăng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter
                              in const <({String label, String? status})>[
                                (label: 'Tất cả', status: null),
                                (label: 'Đang mở', status: 'Active'),
                                (label: 'Đã đóng', status: 'Closed'),
                              ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter.label),
                                selected: _selectedStatus == filter.status,
                                onSelected: (_) {
                                  setState(
                                    () => _selectedStatus = filter.status,
                                  );
                                  _fetchJobs(resetPage: true);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    ..._jobs.map((job) {
                      final isOpen = job.isOpen;
                      final isClosed = job.isClosed;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? AppColors.success.withValues(
                                            alpha: 0.1,
                                          )
                                        : isClosed
                                        ? AppColors.textHint.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.warning.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    job.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOpen
                                          ? AppColors.success
                                          : isClosed
                                          ? AppColors.textSecondary
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${job.location} · ${job.salary}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${job.status} · ${job.applicationsCount} hồ sơ · ${job.viewsCount} lượt xem',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Action buttons per Figma #2178:6350, #2178:6352, #2178:6354
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.push(
                                      '${AppRoutes.recruiterCandidates}?jobId=${job.id}',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      minimumSize: const Size(0, 38),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Xem ứng viên (${job.applicationsCount})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  key: Key('edit_recruiter_job_${job.id}'),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Chỉnh sửa tin',
                                  onPressed: () => _openCreateOrEdit(job: job),
                                ),
                                IconButton(
                                  key: Key('delete_recruiter_job_${job.id}'),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Đóng / Xóa tin',
                                  onPressed: () => _confirmAndDeleteJob(job),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_hasMore)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : OutlinedButton(
                                  onPressed: _loadMore,
                                  child: const Text('Tải thêm tin tuyển dụng'),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
