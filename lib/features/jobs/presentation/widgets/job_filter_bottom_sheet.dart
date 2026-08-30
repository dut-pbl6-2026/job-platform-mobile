import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';

/// Modal bottom sheet for advanced job filtering (MOB-01-02, SEARCH-01)
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
      builder: (context) => JobFilterBottomSheet(
        currentParams: currentParams,
        onApply: onApply,
      ),
    );
  }

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  late String? _selectedLocation;
  late String? _selectedCategory;
  late JobType? _selectedJobType;
  late ExperienceLevel? _selectedExperience;
  late num? _selectedMinSalary;
  late num? _selectedMaxSalary;
  late bool _onlySaved;

  // Preset location options
  static const List<String> _locations = [
    'Tất cả',
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Cần Thơ',
    'Từ xa',
  ];

  // Preset categories
  static const List<String> _categories = [
    'Tất cả',
    'Công nghệ thông tin',
    'Tài chính - Ngân hàng',
    'Marketing',
    'Kinh doanh',
    'Y tế - Dược phẩm',
    'Giáo dục',
  ];

  // Preset salary brackets (min, max, label)
  static final List<(num?, num?, String)> _salaryRanges = [
    (null, null, 'Tất cả'),
    (null, 15000000, 'Dưới 15 triệu'),
    (15000000, 30000000, '15 - 30 triệu'),
    (30000000, 50000000, '30 - 50 triệu'),
    (50000000, null, 'Trên 50 triệu'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentParams.location;
    _selectedCategory = widget.currentParams.category;
    _selectedJobType = widget.currentParams.jobType;
    _selectedExperience = widget.currentParams.experienceLevel;
    _selectedMinSalary = widget.currentParams.salaryMin;
    _selectedMaxSalary = widget.currentParams.salaryMax;
    _onlySaved = widget.currentParams.onlySaved;
  }

  void _handleReset() {
    setState(() {
      _selectedLocation = null;
      _selectedCategory = null;
      _selectedJobType = null;
      _selectedExperience = null;
      _selectedMinSalary = null;
      _selectedMaxSalary = null;
      _onlySaved = false;
    });
  }

  void _handleApply() {
    final updated = widget.currentParams.copyWith(
      location: _selectedLocation == 'Tất cả' ? null : _selectedLocation,
      clearLocation: _selectedLocation == null || _selectedLocation == 'Tất cả',
      category: _selectedCategory == 'Tất cả' ? null : _selectedCategory,
      clearCategory: _selectedCategory == null || _selectedCategory == 'Tất cả',
      jobType: _selectedJobType,
      clearJobType: _selectedJobType == null,
      experienceLevel: _selectedExperience,
      clearExperienceLevel: _selectedExperience == null,
      salaryMin: _selectedMinSalary,
      clearSalaryMin: _selectedMinSalary == null,
      salaryMax: _selectedMaxSalary,
      clearSalaryMax: _selectedMaxSalary == null,
      onlySaved: _onlySaved,
      page: 0, // Reset to first page on filter change
    );

    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Title & Reset button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ lọc tìm kiếm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: _handleReset,
                  child: const Text('Đặt lại'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Sections
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Location filter
                  _buildSectionTitle('Địa điểm làm việc'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _locations.map((loc) {
                      final isSelected = (_selectedLocation == null && loc == 'Tất cả') ||
                          _selectedLocation == loc;
                      return _buildFilterChip(
                        label: loc,
                        isSelected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedLocation = loc == 'Tất cả' ? null : loc;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Job Category filter
                  _buildSectionTitle('Ngành nghề / Lĩnh vực'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = (_selectedCategory == null && cat == 'Tất cả') ||
                          _selectedCategory == cat;
                      return _buildFilterChip(
                        label: cat,
                        isSelected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat == 'Tất cả' ? null : cat;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Job Type (Hình thức làm việc)
                  _buildSectionTitle('Hình thức làm việc'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: _selectedJobType == null,
                        onSelected: (_) => setState(() => _selectedJobType = null),
                      ),
                      ...JobType.values.map(
                        (jt) => _buildFilterChip(
                          label: jt.displayName,
                          isSelected: _selectedJobType == jt,
                          onSelected: (_) => setState(() => _selectedJobType = jt),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Experience Level (Cấp bậc / Kinh nghiệm)
                  _buildSectionTitle('Kinh nghiệm / Cấp bậc'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: _selectedExperience == null,
                        onSelected: (_) => setState(() => _selectedExperience = null),
                      ),
                      ...ExperienceLevel.values.map(
                        (el) => _buildFilterChip(
                          label: el.displayName,
                          isSelected: _selectedExperience == el,
                          onSelected: (_) => setState(() => _selectedExperience = el),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. Salary Range filter
                  _buildSectionTitle('Mức lương hàng tháng'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _salaryRanges.map((range) {
                      final (min, max, label) = range;
                      final isSelected =
                          _selectedMinSalary == min && _selectedMaxSalary == max;
                      return _buildFilterChip(
                        label: label,
                        isSelected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedMinSalary = min;
                            _selectedMaxSalary = max;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 6. Only Saved Jobs switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bookmark_outline_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Chỉ xem việc làm đã lưu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _onlySaved,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _onlySaved = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
            child: ElevatedButton(
              onPressed: _handleApply,
              child: const Text('Áp dụng bộ lọc'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
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
        borderRadius: BorderRadius.circular(10),
      ),
      showCheckmark: false,
      onSelected: onSelected,
    );
  }
}
