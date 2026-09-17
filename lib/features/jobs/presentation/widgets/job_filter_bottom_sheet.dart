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

  // Category & Specialization state
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSpecializationName;

  // Job Type & Workplace
  String? _selectedJobTypeId;
  JobType? _selectedJobType;
  String? _selectedWorkplaceTypeId;

  // Experience
  String? _selectedExperienceId;
  ExperienceLevel? _selectedExperience;

  // Salary
  int _salaryCurrencyTab = 0; // 0 = VND, 1 = JPY
  String? _selectedSalaryRangeId;
  num? _selectedMinSalary;
  num? _selectedMaxSalary;

  // Skills & Saved
  late List<String> _selectedSkills;
  late bool _onlySaved;

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
  ];

  @override
  void initState() {
    super.initState();
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

    _selectedExperienceId = widget.currentParams.experienceLevelId;
    _selectedExperience = widget.currentParams.experienceLevel;

    _selectedSalaryRangeId = widget.currentParams.salaryRangeId;
    _selectedMinSalary = widget.currentParams.salaryMin;
    _selectedMaxSalary = widget.currentParams.salaryMax;
    if (widget.currentParams.currency == 'JPY' ||
        (_selectedSalaryRangeId != null &&
            _selectedSalaryRangeId!.startsWith('jp_'))) {
      _salaryCurrencyTab = 1;
    }

    _selectedSkills = List<String>.from(widget.currentParams.skills);
    _onlySaved = widget.currentParams.onlySaved;
  }

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
    if (_selectedExperienceId != null || _selectedExperience != null) count++;
    if (_selectedSkills.isNotEmpty) count++;
    if (_selectedSalaryRangeId != null ||
        _selectedMinSalary != null ||
        _selectedMaxSalary != null) {
      count++;
    }
    if (_onlySaved) count++;
    return count;
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
      _selectedExperience = null;
      _selectedSalaryRangeId = null;
      _selectedMinSalary = null;
      _selectedMaxSalary = null;
      _selectedSkills = [];
      _onlySaved = false;
      _locationTab = 0;
      _salaryCurrencyTab = 0;
      _selectedDomesticRegion = 'Tất cả';
    });
  }

  void _handleApply() {
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
      experienceLevel: _selectedExperience,
      clearExperienceLevel: _selectedExperience == null,
      experienceLevelId: _selectedExperienceId,
      clearExperienceLevelId: _selectedExperienceId == null,
      skills: _selectedSkills,
      clearSkills: _selectedSkills.isEmpty,
      salaryRangeId: _selectedSalaryRangeId,
      clearSalaryRangeId: _selectedSalaryRangeId == null,
      salaryMin: _selectedMinSalary,
      clearSalaryMin: _selectedMinSalary == null,
      salaryMax: _selectedMaxSalary,
      clearSalaryMax: _selectedMaxSalary == null,
      currency: _salaryCurrencyTab == 1 ? 'JPY' : 'VND',
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

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.90),
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
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bộ lọc nâng cao',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
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
                const Spacer(),
                TextButton.icon(
                  onPressed: activeCount > 0 ? _handleReset : null,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Thiết lập lại'),
                  style: TextButton.styleFrom(
                    foregroundColor: activeCount > 0
                        ? AppColors.primary
                        : AppColors.textHint,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildSectionCard(
                  title: '1. Ngành nghề & Chuyên ngành',
                  icon: Icons.business_center_outlined,
                  subtitle: _selectedCategoryName ?? 'Tất cả ngành nghề',
                  child: _buildCategorySection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: '2. Địa điểm làm việc',
                  icon: Icons.location_on_outlined,
                  subtitle:
                      _selectedLocation ??
                      _selectedInternationalRegion ??
                      'Tất cả địa điểm',
                  child: _buildLocationSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: '3. Mức lương',
                  icon: Icons.monetization_on_outlined,
                  subtitle: _getSalarySubtitle(),
                  child: _buildSalarySection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: '4. Hình thức & Nơi làm việc',
                  icon: Icons.work_outline_rounded,
                  subtitle: 'Thời gian & Môi trường làm việc',
                  child: _buildJobTypeAndWorkplaceSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: '5. Kinh nghiệm làm việc',
                  icon: Icons.timeline_rounded,
                  subtitle: _getExperienceSubtitle(),
                  child: _buildExperienceSection(),
                ),
                const SizedBox(height: 14),

                _buildSectionCard(
                  title: '6. Kỹ năng chuyên môn',
                  icon: Icons.stars_rounded,
                  subtitle: _selectedSkills.isEmpty
                      ? 'Chọn các kỹ năng phù hợp'
                      : '${_selectedSkills.length} kỹ năng đã chọn',
                  child: _buildSkillsSection(),
                ),
              ],
            ),
          ),

          // Sticky Footer
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
                    onPressed: _handleApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      activeCount > 0
                          ? 'Áp dụng bộ lọc ($activeCount tiêu chí)'
                          : 'Xem tất cả việc làm',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  // --- Reusable Section Card Container ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String subtitle,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
        // Category dropdown
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

        // If a category is selected, show its sub-specializations
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
                    if (selected) {
                      _selectedSpecializationName = spec.name;
                    } else {
                      _selectedSpecializationName = null;
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- 2. Location Section ---
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
          // Region Filter Row (Miền Bắc, Miền Trung, Miền Nam)
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    'Tất cả',
                    'Miền Bắc',
                    'Miền Trung - Tây Nguyên',
                    'Miền Nam',
                  ].map((r) {
                    final isSelected = _selectedDomesticRegion == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(r),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.8),
                        backgroundColor: AppColors.surfaceVariant,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) =>
                            setState(() => _selectedDomesticRegion = r),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Provinces list
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: JobFilterData.domesticLocations
                .where(
                  (p) =>
                      _selectedDomesticRegion == 'Tất cả' ||
                      p.region == _selectedDomesticRegion,
                )
                .map((prov) {
                  final isSelected = _selectedLocation == prov.name;
                  return ChoiceChip(
                    label: Text(
                      prov.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
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
                        _selectedLocation = selected ? prov.name : null;
                        _selectedCountry = selected ? 'VN' : null;
                      });
                    },
                  );
                })
                .toList(),
          ),
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
                  color: isSelected ? AppColors.primary : AppColors.border,
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

  // --- 3. Salary Section ---
  String _getSalarySubtitle() {
    if (_selectedSalaryRangeId == null &&
        _selectedMinSalary == null &&
        _selectedMaxSalary == null) {
      return 'Tất cả mức lương';
    }
    final range = JobFilterData.salaryRanges.firstWhere(
      (r) => r.id == _selectedSalaryRangeId,
      orElse: () =>
          const SalaryRangeConfig(id: '', label: 'Tùy chọn', currency: 'VND'),
    );
    return range.label;
  }

  Widget _buildSalarySection() {
    final activeCurrency = _salaryCurrencyTab == 0 ? 'VND' : 'JPY';
    final availableRanges = JobFilterData.salaryRanges
        .where((r) => r.currency == activeCurrency)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Currency Toggle
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _salaryCurrencyTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _salaryCurrencyTab == 0
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VNĐ (Việt Nam)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _salaryCurrencyTab == 0
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _salaryCurrencyTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _salaryCurrencyTab == 1
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Yên Nhật (JPY)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _salaryCurrencyTab == 1
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Salary Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: availableRanges.map((range) {
            final isSelected = _selectedSalaryRangeId == range.id;
            return ChoiceChip(
              label: Text(
                range.label,
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
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSalaryRangeId = range.id;
                    _selectedMinSalary = range.min;
                    _selectedMaxSalary = range.max;
                  } else {
                    _selectedSalaryRangeId = null;
                    _selectedMinSalary = null;
                    _selectedMaxSalary = null;
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 4. Job Type & Workplace Types ---
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
                color: isSelected ? AppColors.primary : AppColors.border,
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
                color: isSelected ? AppColors.primary : AppColors.border,
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

  // --- 5. Experience Section ---
  String _getExperienceSubtitle() {
    if (_selectedExperienceId == null) return 'Tất cả các cấp bậc';
    final opt = JobFilterData.experienceLevels.firstWhere(
      (e) => e.id == _selectedExperienceId,
      orElse: () => const FilterOption(id: '', label: ''),
    );
    return opt.label;
  }

  Widget _buildExperienceSection() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: JobFilterData.experienceLevels.map((exp) {
        final isSelected = _selectedExperienceId == exp.id;
        return ChoiceChip(
          label: Text(
            exp.label,
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
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (selected) {
            setState(() {
              _selectedExperienceId = selected ? exp.id : null;
              _selectedExperience = selected
                  ? _mapExperienceFromId(exp.id)
                  : null;
            });
          },
        );
      }).toList(),
    );
  }

  ExperienceLevel? _mapExperienceFromId(String id) {
    switch (id) {
      case 'no_exp':
        return ExperienceLevel.intern;
      case 'fresher':
        return ExperienceLevel.fresher;
      case 'junior':
        return ExperienceLevel.junior;
      case 'middle':
        return ExperienceLevel.middle;
      case 'senior':
        return ExperienceLevel.senior;
      default:
        return null;
    }
  }

  // --- 6. Skills Section ---
  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _popularSkills.map((skill) {
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
              showCheckmark: true,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
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
