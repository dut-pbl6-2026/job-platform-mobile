import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/models/profile_model.dart';

/// Modal dialog for editing personal information (PROFILE-01-01)
class EditProfileDialog extends StatefulWidget {
  final ProfileModel profile;
  final ValueChanged<ProfileModel> onSave;

  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _summaryController;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _headlineController = TextEditingController(
      text: widget.profile.headline ?? '',
    );
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _addressController = TextEditingController(
      text: widget.profile.address ?? '',
    );
    _avatarUrlController = TextEditingController(
      text: widget.profile.avatarUrl ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.profile.summary ?? '',
    );
    _dateOfBirth = widget.profile.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _avatarUrlController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 22, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 15, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final updated = widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        headline: _headlineController.text.trim().isNotEmpty
            ? _headlineController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        avatarUrl: _avatarUrlController.text.trim().isNotEmpty
            ? _avatarUrlController.text.trim()
            : null,
        dateOfBirth: _dateOfBirth,
        summary: _summaryController.text.trim().isNotEmpty
            ? _summaryController.text.trim()
            : null,
      );

      widget.onSave(updated);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa thông tin cá nhân',
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
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Họ và tên *',
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập họ và tên'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _headlineController,
                          label: 'Chức danh / Tiêu đề nghề nghiệp',
                          hint: 'VD: Senior Flutter Developer',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Số điện thoại',
                          hint: 'VD: 0905 123 456',
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) return null;
                            final digits = raw.replaceAll(
                              RegExp(r'[\s\-\.]'),
                              '',
                            );
                            if (!RegExp(
                              r'^(\+?84|0)\d{8,10}$',
                            ).hasMatch(digits)) {
                              return 'Số điện thoại không đúng định dạng';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ngày sinh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDateOfBirth,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dateOfBirth != null
                                      ? FormatUtils.formatDate(_dateOfBirth!)
                                      : 'Chọn ngày sinh (dd/MM/yyyy)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dateOfBirth != null
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Địa chỉ nơi ở',
                          hint: 'VD: Hải Châu, Đà Nẵng',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _avatarUrlController,
                          label: 'Ảnh đại diện (URL HTTPS)',
                          hint: 'https://...',
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty) return null;
                            final uri = Uri.tryParse(trimmed);
                            if (uri == null ||
                                uri.scheme.toLowerCase() != 'https' ||
                                uri.host.isEmpty) {
                              return 'Vui lòng nhập liên kết ảnh https:// hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _summaryController,
                          label: 'Tóm tắt bản thân (Bio / Summary)',
                          hint:
                              'Mô tả ngắn gọn về kinh nghiệm, mục tiêu và định hướng nghề nghiệp...',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    child: const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
