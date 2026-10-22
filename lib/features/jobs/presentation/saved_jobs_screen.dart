import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/models/job_model.dart';
import 'widgets/job_card.dart';

/// Saved Jobs Screen — Faithful implementation of Figma #2178:5876
/// ("SRS / iPhone 390 / Việc làm đã lưu")
class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  final List<JobModel> _savedJobs = [
    JobModel(
      id: 'job-1',
      title: 'UI/UX Designer',
      companyName: 'Badoo Inc.',
      location: 'Đà Nẵng',
      salaryMin: 20000000,
      salaryMax: 35000000,
      category: 'Design',
      skills: const ['Figma', 'UI/UX', 'Mobile App'],
      experienceLevel: ExperienceLevel.junior,
      jobType: JobType.fullTime,
      isSaved: true,
      description: 'Thiết kế giao diện ứng dụng di động và web hiện đại.',
      requirements:
          'Thành thạo Figma, tối thiểu 2 năm kinh nghiệm thiết kế sản phẩm.',
      benefits: 'Thưởng dự án, bảo hiểm đầy đủ, laptop công ty.',
      postedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    JobModel(
      id: 'job-2',
      title: 'Senior Frontend Developer',
      companyName: 'FPT Software',
      location: 'Từ xa · Remote',
      salaryMin: 25000000,
      salaryMax: 40000000,
      category: 'Công nghệ thông tin',
      skills: const ['Flutter', 'Dart', 'Clean Architecture'],
      experienceLevel: ExperienceLevel.middle,
      jobType: JobType.fullTime,
      isSaved: true,
      description: 'Phát triển ứng dụng di động Flutter quy mô lớn.',
      requirements: 'Kinh nghiệm Flutter 2+ năm, hiểu biết State Management.',
      benefits: 'Làm việc từ xa, lương tháng 13, gói bảo hiểm FPT Care.',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobModel(
      id: 'job-3',
      title: 'Product Designer',
      companyName: 'Meta Inc.',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 30000000,
      salaryMax: 55000000,
      category: 'Design',
      skills: const ['Product Design', 'User Research', 'Design System'],
      experienceLevel: ExperienceLevel.senior,
      jobType: JobType.hybrid,
      isSaved: true,
      description: 'Xây dựng giải pháp trải nghiệm người dùng toàn diện.',
      requirements: 'Design System, User Testing, tư duy sản phẩm.',
      benefits: 'Cổ phiếu ESOP, môi trường làm việc toàn cầu.',
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _searchFilter.isEmpty
        ? _savedJobs
        : _savedJobs.where((j) {
            final q = _searchFilter.toLowerCase();
            return j.title.toLowerCase().contains(q) ||
                j.companyName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Việc làm đã lưu',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sync & Summary Card (Figma #2178:5883)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        Icons.bookmark_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_savedJobs.length} việc làm đã lưu',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Đồng bộ lần cuối: hôm nay, 09:41',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Search inside saved jobs (Figma #2178:5894)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchFilter = v.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Tìm trong việc làm đã lưu...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_searchFilter.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchFilter = '');
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Saved Job List
              if (filteredList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.bookmark_border_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Không tìm thấy việc làm đã lưu phù hợp',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredList.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: JobCard(
                      job: job,
                      onTap: () => context.push('/jobs/${job.id}'),
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
