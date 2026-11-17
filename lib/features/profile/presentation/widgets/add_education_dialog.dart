import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/profile_model.dart';

/// Modal dialog for adding education background (PROFILE-01-04)
class AddEducationDialog extends StatefulWidget {
  final ValueChanged<EducationModel> onAdd;
  final EducationModel? initialEducation;

  const AddEducationDialog({
    super.key,
    required this.onAdd,
    this.initialEducation,
  });

  @override
  State<AddEducationDialog> createState() => _AddEducationDialogState();
}

class _AddEducationDialogState extends State<AddEducationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController(text: 'Kỹ sư');
  final _fieldController = TextEditingController(text: 'Công nghệ Thông tin');
  final _gradeController = TextEditingController(text: 'Giỏi');

  int _startYear = 2018;
  int _endYear = 2022;
  String? _yearError;

  final List<String> _commonDegrees = [
    'Kỹ sư',
    'Cử nhân',
    'Thạc sĩ',
    'Tiến sĩ',
    'Cao đẳng',
    'Chứng chỉ nghề',
  ];

  @override
  void initState() {
    super.initState();
    final edu = widget.initialEducation;
    if (edu != null) {
      _institutionController.text = edu.institution;
      _degreeController.text = _commonDegrees.contains(edu.degree)
          ? edu.degree
          : 'Kỹ sư';
      _fieldController.text = edu.field;
      _gradeController.text = edu.grade ?? '';
      _startYear = edu.startDate.year;
      _endYear = edu.endDate?.year ?? (_startYear + 4);
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_endYear < _startYear) {
      setState(() {
        _yearError = 'Năm tốt nghiệp phải lớn hơn hoặc bằng năm bắt đầu';
      });
      return;
    }
    setState(() => _yearError = null);
    final education = EducationModel(
      id: widget.initialEducation?.id ?? '',
      institution: _institutionController.text.trim(),
      degree: _degreeController.text.trim(),
      field: _fieldController.text.trim(),
      startDate: DateTime(_startYear, 9, 1),
      endDate: DateTime(_endYear, 6, 30),
      grade: _gradeController.text.trim().isNotEmpty
          ? _gradeController.text.trim()
          : null,
    );
    widget.onAdd(education);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Thêm học vấn & Bằng cấp',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Institution
                  const Text(
                    'Trường đào tạo / Viện nghiên cứu *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _institutionController,
                    decoration: InputDecoration(
                      hintText: 'VD: Đại học Bách Khoa - ĐH Đà Nẵng',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.trim().isEmpty == true
                        ? 'Vui lòng nhập trường đào tạo'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Degree dropdown / text
                  const Text(
                    'Bằng cấp *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _degreeController.text,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _commonDegrees
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _degreeController.text = v;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Field of Study
                  const Text(
                    'Chuyên ngành *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _fieldController,
                    decoration: InputDecoration(
                      hintText: 'VD: Kỹ thuật Phần mềm, Khoa học Máy tính',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.trim().isEmpty == true
                        ? 'Vui lòng nhập chuyên ngành'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Years
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Năm bắt đầu',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<int>(
                              // ignore: deprecated_member_use
                              value: _startYear,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: List.generate(20, (index) {
                                final year = DateTime.now().year - index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (y) {
                                if (y != null) setState(() => _startYear = y);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Năm tốt nghiệp',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<int>(
                              // ignore: deprecated_member_use
                              value: _endYear,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: List.generate(20, (index) {
                                final year = DateTime.now().year + 5 - index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (y) {
                                if (y != null) setState(() => _endYear = y);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_yearError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _yearError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Grade
                  const Text(
                    'Xếp loại tốt nghiệp / GPA',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _gradeController,
                    decoration: InputDecoration(
                      hintText: 'VD: Xuất sắc, Giỏi (GPA 3.5/4.0)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 44),
                        ),
                        onPressed: _handleSave,
                        child: const Text('Lưu học vấn'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
