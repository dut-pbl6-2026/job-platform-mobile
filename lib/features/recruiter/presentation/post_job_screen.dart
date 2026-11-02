import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_recruiter_repository.dart';
import '../domain/models/recruiter_models.dart';
import '../domain/repositories/recruiter_repository.dart';

/// Post / Edit Job Screen — Faithful implementation of Figma #2178:6364
/// ("SRS / iPhone 390 / Đăng / sửa tin tuyển dụng")
class PostJobScreen extends StatefulWidget {
  final IRecruiterRepository? repository;
  final bool isPrototypeMode;

  const PostJobScreen({
    super.key,
    this.repository,
    this.isPrototypeMode = true,
  });

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late final IRecruiterRepository _repository;

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _industryController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descController = TextEditingController();
  final _benefitsController = TextEditingController();

  String _employmentType = 'Toàn thời gian';
  String _experienceLevel = 'Junior';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiRecruiterRepository();
  }

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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận đăng tin'),
        content: Text(
          'Tin tuyển dụng "${_titleController.text}" sẽ được gửi đến job-svc để kiểm duyệt và xuất bản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await _submitJob();
            },
            child: const Text('Xuất bản'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitJob() async {
    setState(() => _isSubmitting = true);

    try {
      final params = PostJobParams(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        employmentType: _employmentType,
        experienceLevel: _experienceLevel,
        salaryText: _salaryController.text.trim(),
        description: _descController.text.trim(),
        requirements: _industryController.text.trim().isNotEmpty
            ? _industryController.text.trim()
            : null,
        benefits: _benefitsController.text.trim().isNotEmpty
            ? _benefitsController.text.trim()
            : null,
      );

      await _repository.postJob(params);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tin tuyển dụng đã được gửi duyệt thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi tin tuyển dụng: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                // Prototype / API Gateway indicator banner
                if (widget.isPrototypeMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFEA580C),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bản thử nghiệm (Beta): Tin tuyển dụng được gửi trực tiếp đến dịch vụ tuyển dụng (job-svc) qua YARP API Gateway.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC2410C),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                  hint: 'Ví dụ: Badoo Inc. · Đà Nẵng · Hybrid',
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
                  hint: 'Ví dụ: 15.000.000 – 25.000.000 ₫',
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
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
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
