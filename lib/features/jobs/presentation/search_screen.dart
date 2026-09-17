import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/hive_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_job_repository.dart';
import '../domain/models/job_filter_config.dart';
import '../domain/models/job_filter_params.dart';
import '../domain/models/job_model.dart';
import '../domain/repositories/job_repository.dart';
import 'widgets/job_card.dart';
import 'widgets/job_filter_bottom_sheet.dart';
import 'widgets/job_shimmer_loading.dart';

/// Commercial Search Screen with live suggestions, location selector, and full multi-facet filters
class SearchScreen extends StatefulWidget {
  final IJobRepository? jobRepository;
  final String? initialQuery;
  final String? initialLocation;

  const SearchScreen({
    super.key,
    this.jobRepository,
    this.initialQuery,
    this.initialLocation,
  });

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
  bool _showSuggestions = false;

  String _selectedLocation = '';
  List<String> _recentSearches = [];

  // Master suggestion pool for auto-complete suggestions
  final List<String> _suggestionPool = const [
    'Flutter Developer',
    'Senior Flutter Engineer',
    'ReactJS Developer',
    'Frontend Developer',
    'Backend Golang Engineer',
    'Java Software Engineer',
    'Node.js Developer',
    'Fullstack Developer',
    'UI/UX Designer',
    'Product Designer',
    'Tester / QA Engineer',
    'Automation Tester',
    'DevOps Engineer',
    'Data Analyst',
    'AI / Machine Learning Engineer',
    'Kế toán tổng hợp',
    'Kế toán thuế',
    'Marketing Executive',
    'Digital Marketing Specialist',
    'Nhân viên kinh doanh / Sales',
    'Business Development Executive',
    'Thực tập sinh IT (Internship)',
    'Thực tập sinh Marketing',
    'Trợ lý giám đốc',
  ];

  final List<String> _trendingSearches = const [
    'Flutter',
    'ReactJS',
    'Golang',
    'UI/UX Designer',
    'Node.js',
    'Tester QA',
    'Kế toán',
    'Làm việc từ xa (Remote)',
    'Thực tập sinh',
  ];

  @override
  void initState() {
    super.initState();
    _jobRepository = widget.jobRepository ?? ApiJobRepository();
    _selectedLocation = widget.initialLocation ?? '';

    _loadRecentSearches();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      _searchFocusNode.requestFocus();
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

  List<String> _getMatchingSuggestions(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    return _suggestionPool
        .where((item) => item.toLowerCase().contains(trimmed))
        .take(6)
        .toList();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _showSuggestions = false;
        _hasSearched = false;
        _results = [];
        _totalResults = 0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query, keepSuggestions: true);
    });
  }

  Future<void> _performSearch(
    String query, {
    bool keepSuggestions = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty && _selectedLocation.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      if (!keepSuggestions) {
        _showSuggestions = false;
      }
      _filterParams = _filterParams.copyWith(
        keyword: trimmed,
        clearKeyword: trimmed.isEmpty,
        location: _selectedLocation.isNotEmpty ? _selectedLocation : null,
        clearLocation: _selectedLocation.isEmpty,
        page: 0,
      );
    });

    // Save to recent searches if significant query
    if (trimmed.isNotEmpty) {
      await HiveCacheService.instance.saveRecentSearch(trimmed);
      _loadRecentSearches();
    }

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
    _searchFocusNode.unfocus();
    _performSearch(term, keepSuggestions: false);
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _showSuggestions = false;
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
            location: _selectedLocation.isNotEmpty ? _selectedLocation : null,
          );
        });
        _performSearch(_searchController.text.trim(), keepSuggestions: false);
      },
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredProvinces = JobFilterData.domesticLocations.where((
              p,
            ) {
              return p.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn địa điểm làm việc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Search input in sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setSheetState(() => searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Tìm tỉnh, thành phố...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.textHint,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Popular cities quick chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickLocationChip(
                              'Tất cả địa điểm',
                              '',
                              onSelect: (val) => Navigator.of(context).pop(val),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickLocationChip(
                              'TP Đà Nẵng',
                              'Đà Nẵng',
                              onSelect: (val) => Navigator.of(context).pop(val),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickLocationChip(
                              'TP Hồ Chí Minh',
                              'Hồ Chí Minh',
                              onSelect: (val) => Navigator.of(context).pop(val),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickLocationChip(
                              'TP Hà Nội',
                              'Hà Nội',
                              onSelect: (val) => Navigator.of(context).pop(val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20, color: AppColors.border),

                    // List of 34 merged provinces
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProvinces.length + 1,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedLocation.isEmpty;
                            return ListTile(
                              leading: const Icon(
                                Icons.public_rounded,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Tất cả địa điểm (Toàn quốc)',
                                style: TextStyle(fontSize: 14),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(''),
                            );
                          }

                          final province = filteredProvinces[index - 1];
                          final isSelected = _selectedLocation == province.name;
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              province.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              province.region,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(province.name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _selectedLocation = selected;
        });
        _performSearch(_searchController.text, keepSuggestions: false);
      }
    });
  }

  Widget _buildQuickLocationChip(
    String label,
    String value, {
    required Function(String) onSelect,
  }) {
    final isSelected = _selectedLocation == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => onSelect(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchingSuggestions = _getMatchingSuggestions(_searchController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildSearchAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content body
            _isLoading
                ? const JobShimmerLoading()
                : _errorMessage != null
                ? _buildErrorState()
                : _hasSearched
                ? _buildSearchResults()
                : _buildSearchDiscovery(),

            // Real-time suggestions overlay while typing
            if (_showSuggestions && matchingSuggestions.isNotEmpty)
              _buildSuggestionsOverlay(matchingSuggestions),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    final activeFiltersCount = _filterParams.activeFilterCount;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      automaticallyImplyLeading: false,
      toolbarHeight: 114,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Row 1: Back Button + Keyword Input Field + Filter Button
            Row(
              children: [
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
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (val) => _selectSearchTerm(val),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tên công việc, vị trí, công ty...',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Filter icon button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: activeFiltersCount > 0
                            ? AppColors.primary
                            : AppColors.textPrimary,
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
            const SizedBox(height: 8),

            // Row 2: Location Field right below the search bar
            InkWell(
              onTap: _showLocationPicker,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedLocation.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: _selectedLocation.isNotEmpty
                          ? AppColors.error
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation.isEmpty
                            ? 'Tất cả địa điểm (Toàn quốc)'
                            : 'Địa điểm: $_selectedLocation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedLocation.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedLocation.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedLocation.isNotEmpty)
                      InkWell(
                        onTap: () {
                          setState(() => _selectedLocation = '');
                          _performSearch(
                            _searchController.text,
                            keepSuggestions: false,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Real-time Suggestions Overlay while typing ---
  Widget _buildSuggestionsOverlay(List<String> suggestions) {
    return Material(
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            title: Text(
              suggestion,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.north_west_rounded,
              color: AppColors.textHint,
              size: 16,
            ),
            onTap: () => _selectSearchTerm(suggestion),
          );
        },
      ),
    );
  }

  // --- Discovery State (Recent Searches + Trending Suggestions) ---
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
          const SizedBox(height: 24),

          // 3. Popular Locations
          const Row(
            children: [
              Icon(
                Icons.location_city_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              SizedBox(width: 6),
              Text(
                'Địa điểm phổ biến',
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
            children: [
              _buildLocationActionChip('TP Đà Nẵng', 'Đà Nẵng'),
              _buildLocationActionChip('TP Hồ Chí Minh', 'Hồ Chí Minh'),
              _buildLocationActionChip('TP Hà Nội', 'Hà Nội'),
              _buildLocationActionChip('TP Cần Thơ', 'Cần Thơ'),
              _buildLocationActionChip('TP Hải Phòng', 'Hải Phòng'),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Tip Banner
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
                    'Mẹo tìm việc: Kết hợp từ khóa công việc với trường địa điểm phía trên hoặc áp dụng bộ lọc mức lương để tìm kiếm cơ hội nhanh nhất.',
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

  Widget _buildLocationActionChip(String label, String locationValue) {
    return ActionChip(
      avatar: const Icon(
        Icons.location_on_outlined,
        size: 14,
        color: AppColors.error,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onPressed: () {
        setState(() => _selectedLocation = locationValue);
        _performSearch(_searchController.text, keepSuggestions: false);
      },
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
                'Không có kết quả nào cho "${_searchController.text.trim()}"${_selectedLocation.isNotEmpty ? ' tại $_selectedLocation' : ''}. Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc.',
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
              Expanded(
                child: Text(
                  'Tìm thấy $_totalResults kết quả${_selectedLocation.isNotEmpty ? ' tại $_selectedLocation' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                      'Bộ lọc',
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
