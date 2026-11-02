import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_recruiter_repository.dart';
import '../domain/models/recruiter_models.dart';
import '../domain/repositories/recruiter_repository.dart';

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
  late final IRecruiterRepository _repository;
  List<RecruiterJob> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMockMode = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiRecruiterRepository();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getMyJobs();
      if (mounted) {
        setState(() {
          _jobs = items;
          _isLoading = false;
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _isMockMode = widget.isMock ?? _repository.isMock;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _jobs.where((j) => j.status == 'Đang mở').length;
    final pendingCount = _jobs.where((j) => j.status == 'Chờ duyệt').length;

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
        onPressed: () => context.push(AppRoutes.recruiterPostJob),
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
                                  'Đang mở · Chờ duyệt · Đã đóng',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$openCount tin đang mở · $pendingCount tin chờ duyệt',
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

                    const SizedBox(height: 12),

                    ..._jobs.map((job) {
                      final isOpen = job.status == 'Đang mở';
                      final isPending = job.status == 'Chờ duyệt';

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
                                        : isPending
                                        ? AppColors.warning.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.textHint.withValues(
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
                                          : isPending
                                          ? AppColors.warning
                                          : AppColors.textSecondary,
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
                                      AppRoutes.recruiterCandidates,
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
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Chỉnh sửa tin',
                                  onPressed: () =>
                                      context.push(AppRoutes.recruiterPostJob),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Đóng / Xóa tin',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã cập nhật trạng thái tin: ${job.title}',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
