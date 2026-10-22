import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Recruiter Job Postings Management Screen — Faithful implementation of Figma #2178:6337
/// ("SRS / iPhone 390 / Tin tuyển dụng của tôi")
class RecruiterJobsScreen extends StatefulWidget {
  const RecruiterJobsScreen({super.key});

  @override
  State<RecruiterJobsScreen> createState() => _RecruiterJobsScreenState();
}

class _RecruiterJobsScreenState extends State<RecruiterJobsScreen> {
  final List<Map<String, dynamic>> _jobs = [
    {
      'id': 'rec_job_1',
      'title': 'UI/UX Designer',
      'status': 'Đang mở',
      'applications': 18,
      'views': 240,
      'location': 'Đà Nẵng · Hybrid',
      'salary': '20 – 35 triệu',
      'postedDate': '05/10/2026',
    },
    {
      'id': 'rec_job_2',
      'title': 'Senior Flutter Engineer',
      'status': 'Đang mở',
      'applications': 12,
      'views': 185,
      'location': 'Từ xa · Remote',
      'salary': '30 – 50 triệu',
      'postedDate': '02/10/2026',
    },
    {
      'id': 'rec_job_3',
      'title': 'Product Manager',
      'status': 'Chờ duyệt',
      'applications': 0,
      'views': 0,
      'location': 'TP. Hồ Chí Minh',
      'salary': '35 – 55 triệu',
      'postedDate': '08/10/2026',
    },
    {
      'id': 'rec_job_4',
      'title': 'Backend Developer (.NET / C#)',
      'status': 'Đã đóng',
      'applications': 24,
      'views': 310,
      'location': 'Đà Nẵng · Onsite',
      'salary': '22 – 40 triệu',
      'postedDate': '15/09/2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final openCount = _jobs.where((j) => j['status'] == 'Đang mở').length;
    final pendingCount = _jobs.where((j) => j['status'] == 'Chờ duyệt').length;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                final isOpen = job['status'] == 'Đang mở';
                final isPending = job['status'] == 'Chờ duyệt';

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
                              job['title'] as String,
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
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : isPending
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.textHint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job['status'] as String,
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
                        '${job['location']} · ${job['salary']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${job['status']} · ${job['applications']} hồ sơ · ${job['views']} lượt xem',
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
                              onPressed: () =>
                                  context.push(AppRoutes.recruiterCandidates),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Xem ứng viên (${job['applications']})',
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
                                    'Đã cập nhật trạng thái tin: ${job['title']}',
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
