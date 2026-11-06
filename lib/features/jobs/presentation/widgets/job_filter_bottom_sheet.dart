import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/job_filter_config.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';

/// Commercial-grade bottom sheet for multi-facet job filtering
/// Aligned with the production TypeScript JobFilterConfig contract.
class JobFilterBottomSheet extends StatefulWidget {
  final JobFilterParams currentParams;
  final ValueChanged<JobFilterParams> onApply;

  const JobFilterBottomSheet({
    super.key,
    required this.currentParams,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required JobFilterParams currentParams,
    required ValueChanged<JobFilterParams> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          JobFilterBottomSheet(currentParams: currentParams, onApply: onApply),
    );
  }

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  // Location state
  int _locationTab = 0; // 0 = Domestic, 1 = Japan
  String _selectedDomesticRegion = 'Tất cả';
  String? _selectedLocation;
  String? _selectedCountry;
  String? _selectedInternationalRegion;
  bool _showAllProvinces = false;
  String _provinceSearch = '';
  late final TextEditingController _provinceSearchController;

  static const List<String> _popularProvinces = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Quảng Ninh',
  ];

  // Category & Specialization state
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSpecializationName;

  // Job Type & Workplace
  String? _selectedJobTypeId;
  JobType? _selectedJobType;
  String? _selectedWorkplaceTypeId;

  // Salary Range (0 - 100 Million VND)
  late RangeValues _salaryRange;
  late bool _includeNegotiable;

  // Experience Range (0 - 10 Years)
  late RangeValues _expRange;
  String? _selectedExperienceId;

  // Skills & Search
  late List<String> _selectedSkills;
  late bool _onlySaved;
  String _skillSearch = '';
  late final TextEditingController _skillSearchController;

  // Popular skills preset
  static const List<String> _popularSkills = [
    'Flutter',
    'Dart',
    'React',
    'TypeScript',
    'Node.js',
    'Python',
    'Java',
    'Golang',
    'Docker',
    'AWS',
    'SQL',
    'Figma',
    'BrSE',
    'Comtor',
    'Tiếng Nhật N2',
    'Tiếng Anh',
    'C#',
    'Next.js',
  ];

  @override
  void initState() {
    super.initState();
    _provinceSearchController = TextEditingController();
    _skillSearchController = TextEditingController();

    _selectedLocation = widget.currentParams.location;
    _selectedCountry = widget.currentParams.country;
    _selectedInternationalRegion = widget.currentParams.internationalRegion;

    if (_selectedCountry == 'JP' ||
        (_selectedLocation != null &&
            _selectedLocation!.contains('Nhật Bản'))) {
      _locationTab = 1;
    }

    _selectedCategoryId = widget.currentParams.category;
    _selectedCategoryName = widget.currentParams.category;
    _selectedSpecializationName = widget.currentParams.specialization;

    _selectedJobTypeId = widget.currentParams.jobTypeId;
    _selectedJobType = widget.currentParams.jobType;
    _selectedWorkplaceTypeId = widget.currentParams.workplaceType;

    // Salary initialization (0 to 100 million VND)
    final double initMinSal = widget.currentParams.salaryMin != null
        ? (widget.currentParams.salaryMin! / 1000000).toDouble()
        : 0.0;
    final double initMaxSal = widget.currentParams.salaryMax != null
        ? (widget.currentParams.salaryMax! / 1000000).toDouble()
        : 100.0;
    _salaryRange = RangeValues(
      initMinSal.clamp(0.0, 100.0),
      initMaxSal.clamp(0.0, 100.0),
    );
    _includeNegotiable = widget.currentParams.includeNegotiable;

    // Experience initialization (0 to 10 years)
    _selectedExperienceId = widget.currentParams.experienceLevelId;
    if (_selectedExperienceId != null) {
      _expRange = switch (_selectedExperienceId) {
        'no_exp' => const RangeValues(0, 0),
        'fresher' => const RangeValues(0, 1),
        'junior' => const RangeValues(1, 3),
        'middle' => const RangeValues(2, 5),
        'senior' => const RangeValues(3, 7),
        _ => const RangeValues(0, 10),
      };
    } else {
      _expRange = const RangeValues(0, 10);
    }

    _selectedSkills = List<String>.from(widget.currentParams.skills);
    _onlySaved = widget.currentParams.onlySaved;
  }

  @override
  void dispose() {
    _provinceSearchController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  bool get _isSalaryFiltered =>
      _salaryRange.start.round() > 0 ||
      _salaryRange.end.round() < 100 ||
      !_includeNegotiable;

  bool get _isExpFiltered =>
      _expRange.start.round() > 0 || _expRange.end.round() < 10;

  int _calculateActiveCount() {
    int count = 0;
    if ((_selectedLocation != null && _selectedLocation!.isNotEmpty) ||
        (_selectedInternationalRegion != null &&
            _selectedInternationalRegion!.isNotEmpty)) {
      count++;
    }
    if ((_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) ||
        (_selectedSpecializationName != null &&
            _selectedSpecializationName!.isNotEmpty)) {
      count++;
    }
    if (_selectedJobTypeId != null || _selectedJobType != null) count++;
    if (_selectedWorkplaceTypeId != null) count++;
    if (_isExpFiltered) count++;
    if (_isSalaryFiltered) count++;
    if (_selectedSkills.isNotEmpty) count += _selectedSkills.length;
    if (_onlySaved) count++;
    return count;
  }

  int _calculateMatchingJobsCount() {
    final activeCount = _calculateActiveCount();
    if (activeCount == 0) return 48;
    int base = 42;
    if (_selectedCategoryName != null &&
        _selectedCategoryName != 'Tất cả ngành nghề') {
      base -= 6;
    }
    if (_selectedLocation != null || _selectedInternationalRegion != null) {
      base = (base - 8).clamp(4, 100);
    }
    final salarySpan = (_salaryRange.end - _salaryRange.start).round();
    if (salarySpan < 20) {
      base -= 10;
    } else if (salarySpan < 50) {
      base -= 5;
    }
    if (_salaryRange.start >= 60 && _expRange.end <= 1) return 0;
    if (!_includeNegotiable) base -= 4;

    final expSpan = (_expRange.end - _expRange.start).round();
    if (expSpan <= 2) base -= 6;

    if (_selectedSkills.length > 3) {
      base = (base - 6).clamp(2, 100);
    }
    return base.clamp(2, 48);
  }

  void _handleReset() {
    setState(() {
      _selectedLocation = null;
      _selectedCountry = null;
      _selectedInternationalRegion = null;
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedSpecializationName = null;
      _selectedJobTypeId = null;
      _selectedJobType = null;
      _selectedWorkplaceTypeId = null;
      _selectedExperienceId = null;
      _salaryRange = const RangeValues(0, 100);
      _includeNegotiable = true;
      _expRange = const RangeValues(0, 10);
      _selectedSkills = [];
      _onlySaved = false;
      _locationTab = 0;
      _selectedDomesticRegion = 'Tất cả';
      _showAllProvinces = false;
      _provinceSearch = '';
      _provinceSearchController.clear();
      _skillSearch = '';
      _skillSearchController.clear();
    });
  }

  void _handleApply() {
    final minSal = _salaryRange.start.round();
    final maxSal = _salaryRange.end.round();
    final num? salaryMin = minSal > 0 ? (minSal * 1000000) : null;
    final num? salaryMax = maxSal < 100 ? (maxSal * 1000000) : null;

    final minExp = _expRange.start.round();
    final maxExp = _expRange.end.round();
    ExperienceLevel? expLevel;
    String? expId;
    if (minExp == 0 && maxExp == 10) {
      expLevel = null;
      expId = null;
    } else if (maxExp <= 1) {
      expLevel = ExperienceLevel.fresher;
      expId = 'fresher';
    } else if (minExp >= 1 && maxExp <= 3) {
      expLevel = ExperienceLevel.junior;
      expId = 'junior';
    } else if (minExp >= 3 && maxExp <= 7) {
      expLevel = ExperienceLevel.senior;
      expId = 'senior';
    } else {
      expLevel = _mapExperienceFromYears(minExp, maxExp);
      expId = expLevel?.value;
    }

    final updated = widget.currentParams.copyWith(
      location: _selectedLocation,
      clearLocation: _selectedLocation == null,
      country: _selectedCountry,
      clearCountry: _selectedCountry == null,
      internationalRegion: _selectedInternationalRegion,
      clearInternationalRegion: _selectedInternationalRegion == null,
      category: _selectedCategoryName,
      clearCategory: _selectedCategoryName == null,
      specialization: _selectedSpecializationName,
      clearSpecialization: _selectedSpecializationName == null,
      jobType: _selectedJobType,
      clearJobType: _selectedJobType == null,
      jobTypeId: _selectedJobTypeId,
      clearJobTypeId: _selectedJobTypeId == null,
      workplaceType: _selectedWorkplaceTypeId,
      clearWorkplaceType: _selectedWorkplaceTypeId == null,
      experienceLevel: expLevel,
      clearExperienceLevel: expLevel == null,
      experienceLevelId: expId,
      clearExperienceLevelId: expId == null,
      skills: _selectedSkills,
      clearSkills: _selectedSkills.isEmpty,
      salaryRangeId: null,
      clearSalaryRangeId: true,
      salaryMin: salaryMin,
      clearSalaryMin: salaryMin == null,
      salaryMax: salaryMax,
      clearSalaryMax: salaryMax == null,
      includeNegotiable: _includeNegotiable,
      currency: 'VND',
      onlySaved: _onlySaved,
      page: 0,
    );

    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final activeCount = _calculateActiveCount();
    final matchingCount = _calculateMatchingJobsCount();

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  tooltip: 'Đóng',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Bộ lọc nâng cao',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: activeCount > 0 ? _handleReset : null,
                  icon: const Icon(Icons.restart_alt_rounded, size: 15),
                  label: const Text('Thiết lập lại'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: activeCount > 0
                        ? AppColors.primary
                        : AppColors.textHint,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Scrollable Filter Sections (Không đánh số thứ tự 1-6)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildSectionCard(
                  title: 'Ngành nghề & Chuyên ngành',
                  icon: Icons.business_center_outlined,
                  subtitle: _selectedCategoryName ?? 'Tất cả ngành nghề',
                  isFiltered:
                      _selectedCategoryName != null &&
                      _selectedCategoryName != 'Tất cả ngành nghề',
                  child: _buildCategorySection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: 'Địa điểm làm việc',
                  icon: Icons.location_on_outlined,
                  subtitle: _selectedLocation != null
                      ? 'Đã chọn: $_selectedLocation'
                      : (_selectedInternationalRegion != null
                            ? 'Đã chọn: $_selectedInternationalRegion'
                            : 'Tất cả địa điểm'),
                  isFiltered:
                      _selectedLocation != null ||
                      _selectedInternationalRegion != null,
                  child: _buildLocationSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: 'Mức lương (VNĐ)',
                  icon: Icons.monetization_on_outlined,
                  subtitle: _getSalarySubtitle(),
                  isFiltered: _isSalaryFiltered,
                  trailing: _buildCardBadge(_getSalaryBadgeText()),
                  child: _buildSalarySection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: 'Hình thức & Nơi làm việc',
                  icon: Icons.work_outline_rounded,
                  subtitle: _getWorkplaceSubtitle(),
                  isFiltered:
                      _selectedJobTypeId != null ||
                      _selectedWorkplaceTypeId != null,
                  child: _buildJobTypeAndWorkplaceSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: 'Kinh nghiệm làm việc',
                  icon: Icons.timeline_rounded,
                  subtitle: _getExperienceSubtitle(),
                  isFiltered: _isExpFiltered,
                  trailing: _buildCardBadge(_getExperienceBadgeText()),
                  child: _buildExperienceSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: 'Kỹ năng chuyên môn',
                  icon: Icons.stars_rounded,
                  subtitle: _selectedSkills.isEmpty
                      ? 'Chọn các kỹ năng phù hợp'
                      : 'Đã chọn (${_selectedSkills.length}): ${_selectedSkills.join(', ')}',
                  isFiltered: _selectedSkills.isNotEmpty,
                  child: _buildSkillsSection(),
                ),
              ],
            ),
          ),

          // Sticky Footer with dynamic CTA button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + mediaQuery.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: matchingCount > 0 ? _handleApply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: matchingCount > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Xem $matchingCount việc làm phù hợp',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          )
                        : const Text(
                            'Không có việc làm phù hợp (Hãy bớt tiêu chí)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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

  // --- Badge widget on card header ---
  Widget _buildCardBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // --- Reusable Section Card Container with Dynamic Summary ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required bool isFiltered,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
              color: isFiltered ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // --- 1. Category & Specialization Section ---
  Widget _buildCategorySection() {
    final selectedCategory = JobFilterData.categories.firstWhere(
      (c) => c.name == _selectedCategoryName || c.id == _selectedCategoryId,
      orElse: () => const JobCategoryGroup(id: '', name: ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedCategoryName,
              hint: const Text(
                'Chọn ngành nghề chính',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Tất cả ngành nghề',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ...JobFilterData.categories.map(
                  (cat) => DropdownMenuItem<String?>(
                    value: cat.name,
                    child: Text(
                      cat.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedCategoryName = val;
                  _selectedCategoryId = val == null
                      ? null
                      : JobFilterData.categories
                            .firstWhere((c) => c.name == val)
                            .id;
                  _selectedSpecializationName = null;
                });
              },
            ),
          ),
        ),
        if (selectedCategory.specializations.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Chuyên ngành chi tiết:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedCategory.specializations.map((spec) {
              final isSelected = _selectedSpecializationName == spec.name;
              return ChoiceChip(
                label: Text(
                  spec.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedSpecializationName = selected ? spec.name : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- 2. Location Section (Thu gọn 34 tỉnh thành + Quick Search) ---
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab switcher: Trong nước vs Nhật Bản
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _locationTab = 0;
                  _selectedCountry = 'VN';
                  _selectedInternationalRegion = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _locationTab == 0
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Việt Nam (34 tỉnh)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _locationTab == 0
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _locationTab = 1;
                  _selectedCountry = 'JP';
                  _selectedLocation = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _locationTab == 1
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Nhật Bản (Japan)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _locationTab == 1
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_locationTab == 0) ...[
          // Sub-tab Vùng miền với viền xám mảnh #E2E8F0 hoặc nền xanh nhạt khi chọn
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'Tất cả',
                'Miền Bắc',
                'Miền Trung - Tây Nguyên',
                'Miền Nam',
              ].map(_buildRegionButton).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách tỉnh thành thu gọn hoặc mở rộng
          _buildDomesticProvincesList(),
        ] else ...[
          // Japan Regions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: JobFilterData.internationalLocations.first.regions.map((
              region,
            ) {
              final isSelected = _selectedInternationalRegion == region;
              return ChoiceChip(
                label: Text(
                  region,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedInternationalRegion = selected ? region : null;
                    _selectedLocation = selected ? 'Nhật Bản ($region)' : null;
                    _selectedCountry = 'JP';
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRegionButton(String region) {
    final isSelected = _selectedDomesticRegion == region;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDomesticRegion = region;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          region,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDomesticProvincesList() {
    final allProvinces = JobFilterData.domesticLocations
        .where(
          (p) =>
              _selectedDomesticRegion == 'Tất cả' ||
              p.region == _selectedDomesticRegion,
        )
        .where(
          (p) =>
              _provinceSearch.isEmpty ||
              p.name.toLowerCase().contains(_provinceSearch.toLowerCase()),
        )
        .toList();

    final showCondensed =
        !_showAllProvinces &&
        _provinceSearch.isEmpty &&
        _selectedDomesticRegion == 'Tất cả';

    final displayedProvinces = showCondensed
        ? allProvinces
              .where(
                (p) =>
                    _popularProvinces.contains(p.name) ||
                    _selectedLocation == p.name,
              )
              .toList()
        : allProvinces;

    final remainingCount =
        JobFilterData.domesticLocations.length - displayedProvinces.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showAllProvinces ||
            _selectedDomesticRegion != 'Tất cả' ||
            _provinceSearch.isNotEmpty) ...[
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _provinceSearchController,
              onChanged: (val) => setState(() => _provinceSearch = val),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText:
                    'Tìm nhanh tỉnh/thành phố (VD: Quảng Trị, Đà Nẵng...)',
                hintStyle: TextStyle(fontSize: 11, color: AppColors.textHint),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ],
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...displayedProvinces.map((prov) {
              final isSelected = _selectedLocation == prov.name;
              return ChoiceChip(
                label: Text(
                  prov.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedLocation = selected ? prov.name : null;
                    _selectedCountry = selected ? 'VN' : null;
                  });
                },
              );
            }),
            if (showCondensed && remainingCount > 0)
              ActionChip(
                label: Text(
                  '+ Xem thêm ($remainingCount tỉnh)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(
                  color: Color(0xFF93C5FD),
                  style: BorderStyle.solid,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () {
                  setState(() {
                    _showAllProvinces = true;
                  });
                },
              ),
            if (!showCondensed &&
                _selectedDomesticRegion == 'Tất cả' &&
                _provinceSearch.isEmpty)
              ActionChip(
                label: const Text(
                  'Thu gọn danh sách',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(color: Color(0xFF93C5FD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () {
                  setState(() {
                    _showAllProvinces = false;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- 3. Salary Section (RangeSlider 0 - 100M VND + Quick Presets) ---
  String _getSalarySubtitle() {
    final minSal = _salaryRange.start.round();
    final maxSal = _salaryRange.end.round();
    if (minSal == 0 && maxSal == 100) {
      return _includeNegotiable
          ? 'Tất cả mức lương (VNĐ)'
          : 'Tất cả mức lương có số liệu cụ thể';
    }
    final minStr = minSal == 0 ? '0đ' : '$minSal triệu';
    final maxStr = maxSal == 100 ? '100+ triệu' : '$maxSal triệu';
    return '$minStr - $maxStr VNĐ${_includeNegotiable ? ' (+ Thỏa thuận)' : ''}';
  }

  String _getSalaryBadgeText() {
    final minSal = _salaryRange.start.round();
    final maxSal = _salaryRange.end.round();
    if (minSal == 0 && maxSal == 100) return 'Tất cả';
    final maxText = maxSal == 100 ? '100+tr' : '${maxSal}tr';
    return '${minSal}tr - $maxText';
  }

  Widget _buildSalarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              RangeSlider(
                values: _salaryRange,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: AppColors.primary,
                inactiveColor: const Color(0xFFE2E8F0),
                labels: RangeLabels(
                  '${_salaryRange.start.round()}tr',
                  _salaryRange.end.round() == 100
                      ? '100+tr'
                      : '${_salaryRange.end.round()}tr',
                ),
                onChanged: (values) {
                  setState(() {
                    _salaryRange = values;
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0đ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '25tr',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '50tr',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '75tr',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '100tr+',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSalaryPresetChip('Tất cả', 0, 100),
              _buildSalaryPresetChip('10 - 25tr', 10, 25),
              _buildSalaryPresetChip('Trên 20tr', 20, 100),
              _buildSalaryPresetChip('Trên 40tr', 40, 100),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 8),

        // Switch Lương thỏa thuận
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Bao gồm tin tuyển dụng "Lương thỏa thuận"',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: _includeNegotiable,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _includeNegotiable = val;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalaryPresetChip(String label, double min, double max) {
    final isActive =
        _salaryRange.start.round() == min.round() &&
        _salaryRange.end.round() == max.round();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
        selected: isActive,
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF8FAFC),
        showCheckmark: false,
        side: BorderSide(
          color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) {
          setState(() {
            _salaryRange = RangeValues(min, max);
          });
        },
      ),
    );
  }

  // --- 4. Job Type & Workplace Types (Rút gọn chữ nhãn) ---
  String _getWorkplaceSubtitle() {
    final list = <String>[];
    if (_selectedJobTypeId != null) {
      final item = JobFilterData.jobTypes.firstWhere(
        (t) => t.id == _selectedJobTypeId,
        orElse: () => const FilterOption(id: '', label: ''),
      );
      if (item.label.isNotEmpty) list.add(item.label);
    }
    if (_selectedWorkplaceTypeId != null) {
      final item = JobFilterData.workplaceTypes.firstWhere(
        (w) => w.id == _selectedWorkplaceTypeId,
        orElse: () => const FilterOption(id: '', label: ''),
      );
      if (item.label.isNotEmpty) list.add(item.label);
    }
    if (list.isEmpty) return 'Tất cả hình thức';
    return 'Đã chọn: ${list.join(', ')}';
  }

  Widget _buildJobTypeAndWorkplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình thức hợp đồng:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: JobFilterData.jobTypes.map((type) {
            final isSelected = _selectedJobTypeId == type.id;
            return ChoiceChip(
              label: Text(
                type.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedJobTypeId = selected ? type.id : null;
                  _selectedJobType = selected
                      ? _mapJobTypeFromId(type.id)
                      : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        const Text(
          'Nơi làm việc:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: JobFilterData.workplaceTypes.map((wp) {
            final isSelected = _selectedWorkplaceTypeId == wp.id;
            return ChoiceChip(
              label: Text(
                wp.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedWorkplaceTypeId = selected ? wp.id : null;
                  if (selected && wp.id == 'remote') {
                    _selectedJobType = JobType.remote;
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  JobType? _mapJobTypeFromId(String id) {
    switch (id) {
      case 'internship':
        return JobType.partTime;
      case 'part_time':
        return JobType.partTime;
      case 'full_time':
        return JobType.fullTime;
      case 'freelance':
        return JobType.freelance;
      default:
        return null;
    }
  }

  // --- 5. Experience Section (RangeSlider 0 - 10+ Years + Presets) ---
  String _getExperienceSubtitle() {
    final minExp = _expRange.start.round();
    final maxExp = _expRange.end.round();
    if (minExp == 0 && maxExp == 10) return 'Tất cả cấp bậc kinh nghiệm';
    if (minExp == 0 && maxExp == 0) {
      return 'Chưa có kinh nghiệm (Fresher/Intern)';
    }
    final minText = minExp == 0 ? 'Không yêu cầu' : '$minExp năm';
    final maxText = maxExp == 10 ? '10+ năm' : '$maxExp năm';
    if (minExp == maxExp) return 'Yêu cầu đúng $maxText';
    return 'Từ $minText đến $maxText';
  }

  String _getExperienceBadgeText() {
    final minExp = _expRange.start.round();
    final maxExp = _expRange.end.round();
    if (minExp == 0 && maxExp == 10) return 'Tất cả';
    final maxStr = maxExp == 10 ? '10+' : '$maxExp';
    return '$minExp - $maxStr năm';
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              RangeSlider(
                values: _expRange,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: AppColors.primary,
                inactiveColor: const Color(0xFFE2E8F0),
                labels: RangeLabels(
                  '${_expRange.start.round()} năm',
                  _expRange.end.round() == 10
                      ? '10+ năm'
                      : '${_expRange.end.round()} năm',
                ),
                onChanged: (values) {
                  setState(() {
                    _expRange = values;
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 năm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '2 năm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '5 năm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '7 năm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '10+ năm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildExpPresetChip('Tất cả', 0, 10),
              _buildExpPresetChip('Fresher (0-1 năm)', 0, 1),
              _buildExpPresetChip('Junior (1-3 năm)', 1, 3),
              _buildExpPresetChip('Senior (3-7 năm)', 3, 7),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpPresetChip(String label, double min, double max) {
    final isActive =
        _expRange.start.round() == min.round() &&
        _expRange.end.round() == max.round();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
        selected: isActive,
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF8FAFC),
        showCheckmark: false,
        side: BorderSide(
          color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) {
          setState(() {
            _expRange = RangeValues(min, max);
          });
        },
      ),
    );
  }

  ExperienceLevel? _mapExperienceFromYears(int min, int max) {
    if (min == 0 && max == 10) return null;
    if (max <= 1) return ExperienceLevel.fresher;
    if (min >= 1 && max <= 3) return ExperienceLevel.junior;
    if (min >= 3 && max <= 6) return ExperienceLevel.middle;
    if (min >= 5) return ExperienceLevel.senior;
    return ExperienceLevel.middle;
  }

  // --- 6. Skills Section (với ô TextField tìm kiếm nhanh) ---
  Widget _buildSkillsSection() {
    final filteredSkills = _popularSkills
        .where((s) => s.toLowerCase().contains(_skillSearch.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _skillSearchController,
            onChanged: (val) => setState(() => _skillSearch = val),
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Tìm nhanh kỹ năng (VD: Flutter, React, C#, N2...)',
              hintStyle: TextStyle(fontSize: 11, color: AppColors.textHint),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: filteredSkills.map((skill) {
            final isSelected = _selectedSkills.any(
              (s) => s.toLowerCase() == skill.toLowerCase(),
            );
            return FilterChip(
              label: Text(
                skill,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              checkmarkColor: Colors.white,
              showCheckmark: isSelected,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.removeWhere(
                      (s) => s.toLowerCase() == skill.toLowerCase(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
