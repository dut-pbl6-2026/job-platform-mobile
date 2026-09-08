import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/profile_model.dart';

/// Modal dialog for adding work experience (PROFILE-01-03)
class AddExperienceDialog extends StatefulWidget {
  final ValueChanged<WorkExperienceModel> onAdd;

  const AddExperienceDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddExperienceDialog> createState() => _AddExperienceDialogState();
}

class _AddExperienceDialogState extends State<AddExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime? _endDate;
  bool _isCurrent = true;

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final experience = WorkExperienceModel(
        id: '',
        company: _companyController.text.trim(),
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );
      widget.onAdd(experience);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
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
                          'Thêm kinh nghiệm làm việc',
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

                  // Company
                  const Text('Tên công ty *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      hintText: 'VD: FPT Software, VNG Corporation...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tên công ty' : null,
                  ),

                  const SizedBox(height: 12),

                  // Title / Position
                  const Text('Chức danh / Vị trí *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'VD: Senior Flutter Developer',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập chức danh' : null,
                  ),

                  const SizedBox(height: 12),

                  // Is Current Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Tôi đang làm việc tại đây',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    value: _isCurrent,
                    activeThumbImage: null,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isCurrent = val;
                        if (val) _endDate = null;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // Start Year Picker / selector
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Năm bắt đầu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<int>(
                              initialValue: _startDate.year,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: List.generate(20, (index) {
                                final year = DateTime.now().year - index;
                                return DropdownMenuItem(value: year, child: Text(year.toString()));
                              }),
                              onChanged: (y) {
                                if (y != null) {
                                  setState(() => _startDate = DateTime(y, _startDate.month));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      if (!_isCurrent) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Năm kết thúc', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                initialValue: _endDate?.year ?? DateTime.now().year,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: List.generate(20, (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                                }),
                                onChanged: (y) {
                                  if (y != null) {
                                    setState(() => _endDate = DateTime(y, 12));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Description
                  const Text('Mô tả công việc & Thành tựu nổi bật', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nêu ngắn gọn trách nhiệm và kết quả đạt được...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          minimumSize: const Size(140, 44),
                        ),
                        onPressed: _handleSave,
                        child: const Text('Lưu kinh nghiệm'),
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
