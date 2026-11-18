import 'package:flutter/material.dart';

import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_recruiter_repository.dart';
import '../domain/models/recruiter_models.dart';
import '../domain/repositories/recruiter_repository.dart';

/// Post / Edit Job Screen — Faithful implementation of Figma #2178:6364
/// ("SRS / iPhone 390 / Đăng / sửa tin tuyển dụng")
class PostJobScreen extends StatefulWidget {
  final IRecruiterRepository? repository;
  final bool isPrototypeMode;
  final RecruiterJob? initialJob;

  const PostJobScreen({
    super.key,
    this.repository,
    this.isPrototypeMode = false,
    this.initialJob,
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
  // No default: the backend has no "Junior" level, so the user must pick one.
  String? _experienceLevel;
  List<JobCategoryItem> _categories = const [];
  JobCategoryItem? _selectedCategory;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.initialJob != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiRecruiterRepository();
    final job = widget.initialJob;
    if (job != null) {
      _titleController.text = job.title;
      _locationController.text = job.location;
      _salaryController.text = job.salary;
      _descController.text = job.description ?? '';
      _industryController.text = job.requirements ?? '';
      _benefitsController.text = job.benefits ?? '';
      _employmentType = _normalizeEmploymentUi(job.employmentType);
      _experienceLevel = _normalizeExperienceUi(job.experienceLevel);
    }
    _loadCategories();
  }

  static String _normalizeEmploymentUi(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'parttime':
      case 'part-time':
      case 'bán thời gian':
        return 'Bán thời gian';
      case 'contract':
      case 'hợp đồng':
        return 'Hợp đồng';
      case 'internship':
      case 'thực tập':
        return 'Thực tập';
      default:
        return 'Toàn thời gian';
    }
  }

  static String? _normalizeExperienceUi(String? raw) {
    for (final level in const ['Entry', 'Mid', 'Senior', 'Lead']) {
      if (raw?.trim().toLowerCase() == level.toLowerCase()) return level;
    }
    return null;
  }

  Future<void> _loadCategories() async {
    final cats = await _repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      final initialCategoryId = widget.initialJob?.categoryId;
      if (initialCategoryId != null && initialCategoryId.isNotEmpty) {
        for (final cat in cats) {
          if (cat.id == initialCategoryId) {
            _selectedCategory = cat;
            break;
          }
        }
      }
    });
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
        title: Text(
          _isEditMode ? 'Xác nhận cập nhật tin' : 'Xác nhận đăng tin',
        ),
        content: Text(
          _isEditMode
              ? 'Cập nhật tin tuyển dụng "${_titleController.text}" ngay bây giờ?'
              : 'Tin tuyển dụng "${_titleController.text}" sẽ được xuất bản ngay sau khi xác nhận.',
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
            child: Text(_isEditMode ? 'Lưu thay đổi' : 'Xuất bản'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitJob() async {
    setState(() => _isSubmitting = true);

    try {
      final salaryText = _salaryController.text.trim();
      final parsedSalary = PostJobParams.parseSalaryInput(salaryText);
      final params = PostJobParams(
        title: _titleController.text.trim(),
        companyId:
            AuthSession.instance.currentUser?.companyId ??
            AuthSession.instance.companyId,
        categoryId: _selectedCategory?.id ?? widget.initialJob?.categoryId,
        location: _locationController.text.trim(),
        employmentType: _employmentType,
        experienceLevel: _experienceLevel,
        salaryText: salaryText,
        salaryMin: parsedSalary.min,
        salaryMax: parsedSalary.max,
        salaryCurrency: parsedSalary.currency,
        description: _descController.text.trim(),
        requirements: _industryController.text.trim().isNotEmpty
            ? _industryController.text.trim()
            : null,
        benefits: _benefitsController.text.trim().isNotEmpty
            ? _benefitsController.text.trim()
            : null,
      );

      if (_isEditMode) {
        await _repository.updateJob(widget.initialJob!.id, params);
      } else {
        await _repository.postJob(params);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Đã cập nhật tin tuyển dụng thành công!'
                : 'Tin tuyển dụng đã được đăng thành công!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop(true);
    } catch (e) {
      if (!mounted) return;
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      final safeMsg = rawMsg.isNotEmpty && !rawMsg.contains('DioException')
          ? rawMsg
          : 'Không thể gửi tin tuyển dụng lúc này. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(safeMsg),
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
                  hint: 'Ví dụ: Đà Nẵng · Hybrid',
                  validator: (v) => v?.trim().isEmpty == true
                      ? 'Vui lòng nhập địa điểm'
                      : null,
                ),
                const SizedBox(height: 14),

                if (_categories.isNotEmpty) ...[
                  const Text(
                    'Ngành nghề tuyển dụng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<JobCategoryItem>(
                    key: const Key('post_job_category_dropdown'),
                    // ignore: deprecated_member_use
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      hintText: 'Chọn danh mục ngành nghề',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem<JobCategoryItem>(
                            value: cat,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 14),
                ],

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
                            // ignore: deprecated_member_use
                            value: _employmentType,
                            isExpanded: true,
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
                                value: 'Hợp đồng',
                                child: Text('Hợp đồng'),
                              ),
                              DropdownMenuItem(
                                value: 'Thực tập',
                                child: Text('Thực tập'),
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
                            // ignore: deprecated_member_use
                            value: _experienceLevel,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) =>
                                v == null ? 'Vui lòng chọn cấp độ' : null,
                            items: const [
                              DropdownMenuItem(
                                value: 'Entry',
                                child: Text('Mới ra trường (Entry)'),
                              ),
                              DropdownMenuItem(
                                value: 'Mid',
                                child: Text('Trung cấp (Mid)'),
                              ),
                              DropdownMenuItem(
                                value: 'Senior',
                                child: Text('Cao cấp (Senior)'),
                              ),
                              DropdownMenuItem(
                                value: 'Lead',
                                child: Text('Trưởng nhóm (Lead)'),
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
                  hint: 'Ví dụ: 15.000.000 – 25.000.000 ₫ hoặc Thỏa thuận',
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Vui lòng nhập mức lương';
                    }
                    final parsed = PostJobParams.parseSalaryInput(trimmed);
                    if (parsed.isInvalidRange) {
                      return 'Mức lương tối đa phải lớn hơn hoặc bằng mức lương tối thiểu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Mô tả công việc',
                  controller: _descController,
                  hint: 'Mô tả chi tiết trách nhiệm công việc hằng ngày',
                  maxLines: 4,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Vui lòng nhập mô tả' : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  label: 'Yêu cầu ứng viên',
                  controller: _industryController,
                  hint: 'Kỹ năng chuyên môn, công cụ, kinh nghiệm yêu cầu...',
                  maxLines: 3,
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
