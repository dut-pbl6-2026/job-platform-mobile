import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/design_asset.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/data/repositories/api_auth_repository.dart';
import '../auth/domain/models/user_model.dart';
import '../auth/domain/repositories/auth_repository.dart';
import '../jobs/data/repositories/api_job_repository.dart';
import '../jobs/domain/models/job_filter_params.dart';
import '../jobs/domain/models/job_model.dart';
import '../jobs/domain/repositories/job_repository.dart';
import '../jobs/presentation/widgets/job_filter_bottom_sheet.dart';
import '../jobs/presentation/widgets/job_shimmer_loading.dart';
import '../jobs/presentation/widgets/compact_job_card.dart';
import '../notifications/data/repositories/api_notification_repository.dart';
import '../notifications/domain/repositories/notification_repository.dart';

/// Commercial-grade Home Dashboard with fully integrated real-time job search & filtering
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authRepository,
    this.jobRepository,
    this.notificationRepository,
  });

  final IAuthRepository? authRepository;
  final IJobRepository? jobRepository;
  final INotificationRepository? notificationRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final IAuthRepository _authRepository;
  late final IJobRepository _jobRepository;
  late final INotificationRepository _notificationRepository;

  bool _isLoggingOut = false;
  bool _isLoadingJobs = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _unreadNotificationsCount = 0;
  StreamSubscription<dynamic>? _notifSub;

  List<JobModel> _jobs = [];
  final Set<String> _savingIds = {};
  int _totalJobs = 0;
  int _currentPage = 0;
  bool _hasNextPage = false;

  JobFilterParams _filterParams = const JobFilterParams(pageSize: 10, page: 0);
  String _selectedPill = 'Tất cả';

  bool get _isFilterActive =>
      _filterParams.activeFilterCount > 0 ||
      (_selectedPill != 'Tất cả' && _selectedPill != 'Việc làm');

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? ApiAuthRepository();
    _jobRepository = widget.jobRepository ?? ApiJobRepository();
    _notificationRepository =
        widget.notificationRepository ?? ApiNotificationRepository();
    _fetchJobs();
    _loadUnreadCount();

    _notifSub = PushNotificationService.instance.onNotificationReceived.listen((
      _,
    ) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotificationsCount = count);
      }
    } catch (_) {}
  }

  Future<void> _fetchJobs({bool isResetPage = true}) async {
    if (isResetPage) {
      if (mounted) {
        setState(() {
          _isLoadingJobs = true;
          _errorMessage = null;
          _filterParams = _filterParams.copyWith(page: 0);
        });
      }
    }

    try {
      final result = await _jobRepository.getJobs(_filterParams);
      if (mounted) {
        setState(() {
          _jobs = result.items;
          _totalJobs = result.total;
          _currentPage = result.page;
          _hasNextPage = result.hasNextPage;
          _isLoadingJobs = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingJobs = false;
          _errorMessage = 'Không thể tải danh sách việc làm. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || !_hasNextPage) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final nextParams = _filterParams.copyWith(page: nextPage);
      final result = await _jobRepository.getJobs(nextParams);

      if (mounted) {
        setState(() {
          _jobs.addAll(result.items);
          _currentPage = result.page;
          _hasNextPage = result.hasNextPage;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
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
      await PushNotificationService.instance.unregisterTokenOnLogout();
      await _authRepository.logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  void _openFilter() {
    JobFilterBottomSheet.show(
      context,
      currentParams: _filterParams,
      onApply: (params) {
        setState(() {
          _filterParams = params.copyWith(page: 0);
          _selectedPill = 'Tùy chọn';
        });
        _fetchJobs(isResetPage: true);
      },
    );
  }

  void _handlePillTap(String pill) {
    setState(() => _selectedPill = pill);
    switch (pill) {
      case 'Tất cả':
        _filterParams = const JobFilterParams(pageSize: 10, page: 0);
        break;
      case 'IT / Phần mềm':
        _filterParams = _filterParams.copyWith(
          category: 'Công nghệ thông tin',
          clearCategory: false,
          page: 0,
        );
        break;
      case 'Lương':
        _filterParams = _filterParams.copyWith(
          salaryMin: 30000000,
          clearSalaryMin: false,
          page: 0,
        );
        break;
      case 'Từ xa':
        _filterParams = _filterParams.copyWith(
          workplaceType: 'remote',
          clearWorkplaceType: false,
          page: 0,
        );
        break;
      case 'Địa điểm':
        _openFilter();
        return;
    }
    _fetchJobs(isResetPage: true);
  }

  void _resetFilters() {
    setState(() {
      _selectedPill = 'Tất cả';
      _filterParams = const JobFilterParams(pageSize: 10, page: 0);
    });
    _fetchJobs(isResetPage: true);
  }

  Future<void> _toggleBookmark(JobModel job) async {
    if (_savingIds.contains(job.id)) return;
    setState(() => _savingIds.add(job.id));
    try {
      final saved = await _jobRepository.toggleSaveJob(job.id);
      if (!mounted) return;
      setState(() {
        _jobs = _jobs
            .map(
              (item) =>
                  item.id == job.id ? item.copyWith(isSaved: saved) : item,
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu việc làm. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingIds.remove(job.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final isRecruiter = user?.role == UserRole.recruiter;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _fetchJobs(isResetPage: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(user),
                  _buildSearchBar(),
                  const SizedBox(height: 9),
                  _buildFilterPills(),
                  _buildAiMatchBanner(),
                  const SizedBox(height: 10),
                  _buildQuickShortcuts(isRecruiter),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isFilterActive
                                  ? 'Kết quả tìm kiếm'
                                  : 'Việc làm đề xuất',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isFilterActive
                                  ? 'Tìm thấy $_totalJobs cơ hội việc làm'
                                  : 'Khám phá cơ hội phù hợp với bạn',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isFilterActive)
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Đặt lại'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildJobsList(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(UserModel? user) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 7),
    child: Row(
      children: [
        UserAvatar(name: user?.name, imageUrl: user?.avatarUrl),
        const SizedBox(width: 17),
        Expanded(
          child: Text(
            user?.name ?? 'Ứng viên',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          key: const Key('home_notification_button'),
          tooltip: 'Thông báo',
          icon: Badge(
            isLabelVisible: _unreadNotificationsCount > 0,
            label: Text('$_unreadNotificationsCount'),
            child: const DesignAsset('home-notification'),
          ),
          onPressed: () async {
            await context.push(AppRoutes.notifications);
            if (mounted) _loadUnreadCount();
          },
        ),
        IconButton(
          key: const Key('home_ai_copilot_button'),
          tooltip: 'AI Copilot',
          icon: const DesignAsset('home-chat'),
          onPressed: () => context.push(AppRoutes.aiCopilot),
        ),
        IconButton(
          tooltip: 'Menu tài khoản',
          icon: _isLoggingOut
              ? const SizedBox.square(
                  dimension: 25,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const DesignAsset('home-menu'),
          onPressed: _isLoggingOut ? null : _openAccountMenu,
        ),
      ],
    ),
  );

  void _openAccountMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Hồ sơ'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Việc làm đã lưu'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.savedJobs);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Material(
    color: AppColors.searchSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(47),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(47),
      onTap: () => context.push(AppRoutes.search),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.searchHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              const DesignAsset('home-search'),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tìm việc, công ty, kỹ năng...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0x99000000)),
                ),
              ),
              IconButton(
                tooltip: 'Bộ lọc',
                icon: const DesignAsset('home-tune'),
                onPressed: () => context.push(AppRoutes.search),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildFilterPills() => Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final pill in ['Tất cả', 'Địa điểm', 'Từ xa', 'Lương'])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Semantics(
                    selected: _selectedPill == pill,
                    child: TextButton(
                      onPressed: () => _handlePillTap(pill),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedPill == pill
                            ? Colors.white
                            : AppColors.darkSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        minimumSize: const Size(0, 48),
                        shape: const StadiumBorder(),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _selectedPill == pill
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _selectedPill == pill ? 20 : 5,
                            vertical: 6,
                          ),
                          child: Text(
                            pill,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: 'Tất cả bộ lọc',
        onPressed: _openFilter,
        icon: const DesignAsset('home-filters'),
      ),
    ],
  );

  Widget _buildAiMatchBanner() => Material(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: () => context.push(AppRoutes.resumeScoring),
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.bannerHeight,
          minWidth: double.infinity,
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✦  AI MATCH  ·  Cá nhân hóa cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Khám phá mức độ phù hợp của hồ sơ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildQuickShortcuts(bool isRecruiter) => Row(
    children: [
      Expanded(
        child: _shortcut(
          isRecruiter ? '+' : '▣',
          isRecruiter ? 'Đăng tin' : 'Tạo CV',
          () => context.go(
            isRecruiter ? AppRoutes.recruiterPostJob : AppRoutes.createCv,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _shortcut('◉', 'Hồ sơ', () => context.go(AppRoutes.profile)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _shortcut(
          '✓',
          'Ứng tuyển',
          () => context.go(AppRoutes.applications),
        ),
      ),
    ],
  );

  Widget _shortcut(String glyph, String title, VoidCallback onTap) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.shortcutHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  glyph,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _buildJobsList() {
    if (_isLoadingJobs) {
      return const JobShimmerLoading();
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _fetchJobs(isResetPage: true),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tìm thấy việc làm phù hợp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc để có kết quả tốt hơn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Xóa bộ lọc & Đặt lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _jobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final job = _jobs[index];
            return CompactJobCard(
              job: job,
              onTap: () => context.push('${AppRoutes.jobs}/${job.id}'),
              onBookmarkToggle: _savingIds.contains(job.id)
                  ? null
                  : () => _toggleBookmark(job),
            );
          },
        ),
        if (_hasNextPage) ...[
          const SizedBox(height: 16),
          Center(
            child: _isLoadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loadMoreJobs,
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    label: const Text('Xem thêm việc làm'),
                  ),
          ),
        ],
      ],
    );
  }
}
