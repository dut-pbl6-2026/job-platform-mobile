import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Post / Edit Job Screen — Faithful implementation of Figma #2178:6364
/// ("SRS / iPhone 390 / Đăng / sửa tin tuyển dụng")
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController(text: 'UI/UX Designer');
  final _locationController = TextEditingController(text: 'Đà Nẵng · Hybrid');
  final _industryController = TextEditingController(
    text: 'Công nghệ thông tin · IT',
  );
  final _salaryController = TextEditingController(
    text: '15.000.000 – 25.000.000 ₫',
  );
  final _descController = TextEditingController(
    text: 'Thiết kế giao diện web/mobile; thành thạo Figma, Design System; phối hợp cùng đội ngũ kỹ sư.',
  );
  final _benefitsController = TextEditingController(
    text: 'Bảo hiểm đầy đủ, thưởng hiệu suất dự án, môi trường làm việc linh hoạt.',
  );

  String _employmentType = 'Toàn thời gian';
  String _experienceLevel = 'Junior';

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _industryController.dispose();
    _salaryController.dispose();
    _descController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng tin'),
        content: Text(
          'Tin tuyển dụng "${_titleController.text}" sẽ được gửi để kiểm duyệt và xuất bản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Return to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tin tuyển dụng đã được gửi duyệt thành công!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xuất bản'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Đăng / sửa tin tuyển dụng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: 'Tiêu đề vị trí',
                  controller: _titleController,
                  hint: 'Ví dụ: Senior UI/UX Designer',
                  validator: (v) => v?.trim().isEmpty == true
                      ? 'Vui lòng nhập tiêu đề'
                      : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Công ty & Địa điểm làm việc',
                  controller: _locationController,
                  hint: 'Ví dụ: Badoo Inc. · Đà Nẵng',
                  validator: (v) => v?.trim().isEmpty == true
                      ? 'Vui lòng nhập địa điểm'
                      : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loại hình làm việc',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _employmentType,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Toàn thời gian',
                                child: Text('Toàn thời gian'),
                              ),
                              DropdownMenuItem(
                                value: 'Bán thời gian',
                                child: Text('Bán thời gian'),
                              ),
                              DropdownMenuItem(
                                value: 'Thực tập',
                                child: Text('Thực tập'),
                              ),
                              DropdownMenuItem(
                                value: 'Từ xa',
                                child: Text('Từ xa'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _employmentType = v ?? _employmentType,
                            ),
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
                            'Cấp độ kinh nghiệm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _experienceLevel,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Intern',
                                child: Text('Intern'),
                              ),
                              DropdownMenuItem(
                                value: 'Junior',
                                child: Text('Junior'),
                              ),
                              DropdownMenuItem(
                                value: 'Middle',
                                child: Text('Middle'),
                              ),
                              DropdownMenuItem(
                                value: 'Senior',
                                child: Text('Senior'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _experienceLevel = v ?? _experienceLevel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Mức lương & Tiền tệ',
                  controller: _salaryController,
                  hint: 'Ví dụ: 15.000.000 – 25.000.000 · VND',
                  validator: (v) => v?.trim().isEmpty == true
                      ? 'Vui lòng nhập mức lương'
                      : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Mô tả công việc & Yêu cầu',
                  controller: _descController,
                  hint: 'Mô tả chi tiết trách nhiệm và kỹ năng cần có',
                  maxLines: 4,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Vui lòng nhập mô tả' : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Chế độ đãi ngộ & Phúc lợi',
                  controller: _benefitsController,
                  hint: 'Bảo hiểm, thưởng, ngày phép, đào tạo...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Primary CTA (Figma #2178:6386)
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xem trước & Xuất bản tin',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
