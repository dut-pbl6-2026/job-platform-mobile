import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_application_repository.dart';
import '../domain/models/application_model.dart';
import '../domain/repositories/application_repository.dart';

/// Screen for applying to a job with CV upload and cover letter (MOB-01-04, APP-01-01)
class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final IApplicationRepository? applicationRepository;
  final ICvPickerService? cvPickerService;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    this.applicationRepository,
    this.cvPickerService,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  late final IApplicationRepository _repository;
  late final ICvPickerService _cvPicker;

  final TextEditingController _coverLetterController = TextEditingController();
  SelectedCvFile? _selectedFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _quickSuggestions = [
    'Tôi có 4+ năm kinh nghiệm Flutter',
    'Thành thạo Clean Architecture & Riverpod',
    'Sẵn sàng nhận việc ngay',
    'Khả năng đọc hiểu tài liệu tiếng Anh tốt',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.applicationRepository ?? ApiApplicationRepository();
    _cvPicker = widget.cvPickerService ?? MockCvPickerService();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _handlePickCv() async {
    try {
      final file = await _cvPicker.pickCvFile();
      if (file != null && mounted) {
        setState(() {
          _selectedFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi khi chọn file: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Vui lòng tải lên file CV (PDF, DOC, DOCX) của bạn.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final params = ApplyJobParams(
        jobId: widget.jobId,
        jobTitle: widget.jobTitle,
        companyName: widget.companyName,
        companyLogo: widget.companyLogo,
        coverLetter: _coverLetterController.text.trim(),
        cvFileName: _selectedFile!.name,
        cvFilePath: _selectedFile!.path,
        cvFileSize: _selectedFile!.size,
        cvBytes: _selectedFile!.bytes,
      );

      await _repository.applyJob(params);

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Show Success Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ứng tuyển thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hồ sơ của bạn đã được gửi đến nhà tuyển dụng ${widget.companyName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Navigate to application history
                  context.push(AppRoutes.applications);
                },
                child: const Text('Xem lịch sử ứng tuyển'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Quay lại việc làm'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      setState(() {
        _errorMessage = errorStr.contains('Exception: ')
            ? errorStr.replaceAll('Exception: ', '')
            : 'Đã có lỗi xảy ra khi nộp hồ sơ. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _addSuggestion(String text) {
    final currentText = _coverLetterController.text;
    if (currentText.isEmpty) {
      _coverLetterController.text = text;
    } else {
      _coverLetterController.text = '$currentText. $text';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ứng tuyển việc làm'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Brief Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.companyName.isNotEmpty
                              ? widget.companyName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.jobTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact Info Section
              const Text(
                'Thông tin liên hệ ứng viên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildContactRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Họ và tên',
                      value: user?.name ?? 'Nguyễn Văn An',
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildContactRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? 'candidate@example.com',
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildContactRow(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      value: '0905 123 456',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CV Upload Section (MOB-01-04)
              const Text(
                'Tải lên hồ sơ CV *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hỗ trợ định dạng PDF, DOC, DOCX (Dung lượng tối đa 10MB)',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 10),

              if (_selectedFile == null) ...[
                InkWell(
                  onTap: _handlePickCv,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chọn file CV từ thiết bị',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nhấn để tải lên file CV của bạn',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Selected CV Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.success,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedFile!.formattedSize,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Đổi file khác',
                        onPressed: _handlePickCv,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                        tooltip: 'Xóa file',
                        onPressed: () {
                          setState(() => _selectedFile = null);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Cover Letter Section
              const Text(
                'Thư giới thiệu (Cover letter)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nêu rõ lý do bạn là ứng viên sáng giá cho vị trí này',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _coverLetterController,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Xin chào, tôi quan tâm đến vị trí này vì...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Quick Suggestions Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSuggestions.map((suggestion) {
                  return ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _addSuggestion(suggestion),
                  );
                }).toList(),
              ),

              // Error message banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Nộp hồ sơ ứng tuyển',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
