import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/hive_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_job_repository.dart';
import '../domain/models/job_filter_params.dart';
import '../domain/models/job_model.dart';
import '../domain/repositories/job_repository.dart';
import 'widgets/job_card.dart';
import 'widgets/job_filter_bottom_sheet.dart';
import 'widgets/job_shimmer_loading.dart';

/// Commercial Search Screen dedicated for real-time job search, recent queries, and suggestions (SEARCH-01, OFFLINE-01)
class SearchScreen extends StatefulWidget {
  final IJobRepository? jobRepository;
  final String? initialQuery;

  const SearchScreen({super.key, this.jobRepository, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final IJobRepository _jobRepository;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  JobFilterParams _filterParams = const JobFilterParams(pageSize: 20);

  bool _isLoading = false;
  String? _errorMessage;
  List<JobModel> _results = [];
  int _totalResults = 0;
  bool _hasSearched = false;

  List<String> _recentSearches = [];

  final List<String> _trendingSearches = const [
    'Flutter',
    'ReactJS',
    'Golang',
    'Node.js',
    'UI/UX Designer',
    'Thực tập sinh IT',
    'Tester QA',
    'Làm việc từ xa (Remote)',
    'Kế toán',
  ];

  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? ApiJobRepository();
    _loadRecentSearches();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final history = await HiveCacheService.instance.getRecentSearches();
    if (mounted) {
      setState(() => _recentSearches = history);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _results = [];
        _totalResults = 0;
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _filterParams = _filterParams.copyWith(keyword: trimmed, page: 0);
    });

    // Save to recent searches
    await HiveCacheService.instance.saveRecentSearch(trimmed);
    _loadRecentSearches();

    try {
      final result = await _jobRepository.getJobs(_filterParams);
      if (mounted) {
        setState(() {
          _results = result.items;
          _totalResults = result.total;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tìm kiếm lúc này. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _performSearch(term);
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _hasSearched = false;
      _results = [];
      _totalResults = 0;
      _isLoading = false;
    });
    _searchFocusNode.requestFocus();
  }

  void _openFilter() {
    JobFilterBottomSheet.show(
      context,
      currentParams: _filterParams,
      onApply: (newParams) {
        setState(() {
          _filterParams = newParams.copyWith(
            keyword: _searchController.text.trim(),
          );
        });
        if (_searchController.text.trim().isNotEmpty) {
          _performSearch(_searchController.text.trim());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildSearchAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const JobShimmerLoading()
            : _errorMessage != null
            ? _buildErrorState()
            : _hasSearched
            ? _buildSearchResults()
            : _buildSearchDiscovery(),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    final activeFiltersCount = _filterParams.activeFilterCount;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      title: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Quay lại',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),

          // Search text field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm công việc, công ty, kỹ năng...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Filter icon button
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Bộ lọc',
                onPressed: _openFilter,
              ),
              if (activeFiltersCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$activeFiltersCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Search Discovery State (Recent Searches + Trending Suggestions) ---
  Widget _buildSearchDiscovery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Recent Searches Section
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tìm kiếm gần đây',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await HiveCacheService.instance.clearRecentSearches();
                    setState(() => _recentSearches = []);
                  },
                  child: const Text(
                    'Xóa lịch sử',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((term) {
                return InputChip(
                  label: Text(
                    term,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => _selectSearchTerm(term),
                  onDeleted: () async {
                    await HiveCacheService.instance.removeRecentSearch(term);
                    _loadRecentSearches();
                  },
                  deleteIcon: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Trending / Suggested Searches
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Từ khóa tìm kiếm phổ biến',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingSearches.map((keyword) {
              return ActionChip(
                avatar: const Icon(
                  Icons.search_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  keyword,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: () => _selectSearchTerm(keyword),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 3. Tip Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mẹo tìm việc: Kết hợp tên vị trí (vd: Flutter) cùng địa điểm (Đà Nẵng, TP HCM) hoặc mức lương để tìm kiếm chính xác nhất.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E40AF),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Search Results State ---
  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy việc làm phù hợp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Không có kết quả nào cho "${_searchController.text.trim()}". Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openFilter,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Điều chỉnh bộ lọc'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Summary Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tìm thấy $_totalResults kết quả cho "${_searchController.text.trim()}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              InkWell(
                onTap: _openFilter,
                child: const Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lọc',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // List of Results
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = _results[index];
              return JobCard(
                job: job,
                onTap: () => context.push('${AppRoutes.jobs}/${job.id}'),
                onBookmarkToggle: () async {
                  await _jobRepository.toggleSaveJob(job.id);
                  if (mounted) {
                    setState(() {
                      _results[index] = job.copyWith(isSaved: !job.isSaved);
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
