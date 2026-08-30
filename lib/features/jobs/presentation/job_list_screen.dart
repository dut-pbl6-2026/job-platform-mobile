import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/mock_job_repository.dart';
import '../domain/models/job_filter_params.dart';
import '../domain/models/job_model.dart';
import '../domain/repositories/job_repository.dart';
import 'widgets/job_card.dart';
import 'widgets/job_filter_bottom_sheet.dart';
import 'widgets/job_search_bar.dart';
import 'widgets/job_shimmer_loading.dart';

/// Job List and Search Screen (MOB-01-02, JOB-01, SEARCH-01)
class JobListScreen extends StatefulWidget {
  final IJobRepository? jobRepository;

  const JobListScreen({
    super.key,
    this.jobRepository,
  });

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late final IJobRepository _jobRepository;
  final ScrollController _scrollController = ScrollController();

  JobFilterParams _filterParams = const JobFilterParams(
    pageSize: 10,
    page: 0,
  );

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<JobModel> _jobs = [];
  int _totalJobs = 0;
  int _currentPage = 0;
  bool _hasNextPage = false;

  // Selected quick filter chip
  String _selectedQuickChip = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? MockJobRepository();
    _scrollController.addListener(_onScroll);
    _fetchJobs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Load next page when reaching 80% scroll extent
    if (currentScroll >= (maxScroll - 250) &&
        _hasNextPage &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreJobs();
    }
  }

  Future<void> _fetchJobs({bool isResetPage = true}) async {
    if (isResetPage) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _filterParams = _filterParams.copyWith(page: 0);
      });
    }

    try {
      final result = await _jobRepository.getJobs(_filterParams);
      if (!mounted) return;

      setState(() {
        _jobs = result.items;
        _totalJobs = result.total;
        _currentPage = result.page;
        _hasNextPage = result.hasNextPage;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách việc làm. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || !_hasNextPage) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final nextParams = _filterParams.copyWith(page: nextPage);
      final result = await _jobRepository.getJobs(nextParams);

      if (!mounted) return;

      setState(() {
        _jobs.addAll(result.items);
        _currentPage = result.page;
        _hasNextPage = result.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchJobs(isResetPage: true);
  }

  void _handleSearch(String keyword) {
    _filterParams = _filterParams.copyWith(
      keyword: keyword,
      clearKeyword: keyword.trim().isEmpty,
      page: 0,
    );
    _fetchJobs(isResetPage: true);
  }

  void _handleOpenFilter() {
    JobFilterBottomSheet.show(
      context,
      currentParams: _filterParams,
      onApply: (updatedParams) {
        setState(() {
          _filterParams = updatedParams;
          _selectedQuickChip = 'Tùy chọn';
        });
        _fetchJobs(isResetPage: true);
      },
    );
  }

  void _handleQuickChipTap(String chip) {
    setState(() {
      _selectedQuickChip = chip;
    });

    switch (chip) {
      case 'Tất cả':
        _filterParams = _filterParams.clearAllFilters();
        break;
      case 'IT / Phần mềm':
        _filterParams = _filterParams.copyWith(
          category: 'Công nghệ thông tin',
          clearLocation: true,
          clearJobType: true,
          clearSalaryMin: true,
          onlySaved: false,
        );
        break;
      case 'Từ xa (Remote)':
        _filterParams = _filterParams.copyWith(
          jobType: JobType.remote,
          clearCategory: true,
          clearLocation: true,
          clearSalaryMin: true,
          onlySaved: false,
        );
        break;
      case 'Lương cao (30M+)':
        _filterParams = _filterParams.copyWith(
          salaryMin: 30000000,
          clearCategory: true,
          clearLocation: true,
          clearJobType: true,
          onlySaved: false,
        );
        break;
      case 'Đã lưu':
        _filterParams = _filterParams.copyWith(
          onlySaved: true,
          clearCategory: true,
          clearLocation: true,
          clearJobType: true,
          clearSalaryMin: true,
        );
        break;
    }

    _fetchJobs(isResetPage: true);
  }

  Future<void> _handleBookmarkToggle(JobModel job) async {
    final newStatus = await _jobRepository.toggleSaveJob(job.id);
    if (!mounted) return;

    setState(() {
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(isSaved: newStatus);
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? 'Đã lưu tin tuyển dụng: ${job.title}'
              : 'Đã bỏ lưu tin tuyển dụng',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDetail(JobModel job) {
    context.push('${AppRoutes.jobs}/${job.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tìm việc làm'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Bộ lọc',
            onPressed: _handleOpenFilter,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Search Bar + Quick Category Chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  JobSearchBar(
                    initialValue: _filterParams.keyword ?? '',
                    onChanged: _handleSearch,
                    onFilterTap: _handleOpenFilter,
                    activeFilterCount: _filterParams.activeFilterCount,
                  ),
                  const SizedBox(height: 12),
                  // Quick category pill list
                  _buildQuickCategoryChips(),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Main Content Area
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCategoryChips() {
    final chips = [
      'Tất cả',
      'IT / Phần mềm',
      'Từ xa (Remote)',
      'Lương cao (30M+)',
      'Đã lưu',
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedQuickChip == chip;

          return ChoiceChip(
            label: Text(
              chip,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceVariant,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
            onSelected: (_) => _handleQuickChipTap(chip),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading state
    if (_isLoading) {
      return const JobShimmerLoading(itemCount: 4);
    }

    // 2. Error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // 3. Empty state
    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }

    // 4. Success / Loaded State with Pull to Refresh & Infinite Scroll
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _jobs.length + (_hasNextPage ? 2 : 1),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Top header displaying result count
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy $_totalJobs cơ hội việc làm',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_filterParams.hasActiveFilters)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _filterParams = _filterParams.clearAllFilters();
                          _selectedQuickChip = 'Tất cả';
                        });
                        _fetchJobs(isResetPage: true);
                      },
                      child: const Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final jobIndex = index - 1;

          // Bottom loading spinner for pagination
          if (jobIndex == _jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final job = _jobs[jobIndex];
          return JobCard(
            job: job,
            onTap: () => _navigateToDetail(job),
            onBookmarkToggle: () => _handleBookmarkToggle(job),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Không tìm thấy việc làm phù hợp',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc điều chỉnh lại các tiêu chí trong bộ lọc.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Đặt lại tất cả bộ lọc'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _filterParams = _filterParams.clearAllFilters();
                  _selectedQuickChip = 'Tất cả';
                });
                _fetchJobs(isResetPage: true);
              },
            ),
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi kết nối',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _fetchJobs(isResetPage: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
