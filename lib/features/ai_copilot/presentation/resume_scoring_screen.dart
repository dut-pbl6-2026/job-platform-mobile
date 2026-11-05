import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/file_picker_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_content.dart';
import '../../jobs/data/repositories/api_job_repository.dart';
import '../../jobs/domain/models/job_filter_params.dart';
import '../../jobs/domain/models/job_model.dart';
import '../../jobs/domain/repositories/job_repository.dart';
import '../data/api_ai_repository.dart';
import '../domain/ai_repository.dart';

/// Commercial-grade Smart Resume Scoring Screen (SCORE-01, master-plan.md:312, PBL6-10)
/// Allows candidates to upload their CV (PDF/DOCX) and evaluate compatibility
/// against specific job requirements with match score, skill breakdown, and AI suggestions.
class ResumeScoringScreen extends StatefulWidget {
  const ResumeScoringScreen({
    super.key,
    this.jobId,
    this.targetJobTitle,
    this.repository,
    this.jobRepository,
    this.cvPickerService,
  });
  final String? jobId;
  final String? targetJobTitle;
  final IAiRepository? repository;
  final IJobRepository? jobRepository;
  final ICvPickerService? cvPickerService;

  @override
  State<ResumeScoringScreen> createState() => _ResumeScoringScreenState();
}

class _ResumeScoringScreenState extends State<ResumeScoringScreen> {
  late final IAiRepository _repository;
  late final IJobRepository _jobRepository;
  late final ICvPickerService _picker;
  String? _jobId;
  String? _jobTitle;
  String? _company;
  SelectedCvFile? _file;
  ResumeFeedback? _feedback;
  String? _error;
  bool _loading = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiAiRepository();
    _jobRepository = widget.jobRepository ?? ApiJobRepository();
    _picker = widget.cvPickerService ?? const DeviceCvPickerService();
    _jobId = widget.jobId;
    _jobTitle = widget.targetJobTitle;
    if (_jobId != null && _jobTitle == null) {
      _loadTargetJob();
    }
  }

  Future<void> _loadTargetJob() async {
    try {
      final job = await _jobRepository.getJobById(_jobId!);
      if (job != null && mounted) {
        setState(() {
          _jobTitle ??= job.title;
          _company ??= job.companyName;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _repository.cancelCurrentRequest();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_loading || _picking) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickCvFile();
      if (!mounted || file == null) return;
      if (!['pdf', 'docx'].contains(file.extension) ||
          file.size <= 0 ||
          file.size > 5 * 1024 * 1024) {
        setState(
          () => _error = 'Vui lòng chọn CV PDF hoặc DOCX không quá 5 MB.',
        );
        return;
      }
      setState(() {
        _file = file;
        _feedback = null;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở file CV. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _chooseJob() async {
    if (_loading) return;
    final job = await showModalBottomSheet<JobModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ScoringJobPicker(repository: _jobRepository),
    );
    if (!mounted || job == null) return;
    setState(() {
      _jobId = job.id;
      _jobTitle = job.title;
      _company = job.companyName;
      _feedback = null;
      _error = null;
    });
  }

  Future<void> _score() async {
    if (_loading) return;
    final file = _file;
    if (file == null || _jobId == null || _jobId!.isEmpty) {
      setState(
        () => _error = 'Vui lòng chọn việc làm và tải CV trước khi chấm.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _feedback = null;
    });
    try {
      final feedback = await _repository.scoreResume(
        AiCvInput(
          name: file.name,
          size: file.size,
          bytes: file.bytes,
          path: file.path,
        ),
        jobId: _jobId!,
      );
      if (mounted) setState(() => _feedback = feedback);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AiFailure
              ? error.message
              : 'Không thể chấm CV. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFF2563EB);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getScoreLevelText(double score) {
    if (score >= 80) return 'Rất phù hợp';
    if (score >= 65) return 'Khá phù hợp';
    if (score >= 50) return 'Cần cải thiện kỹ năng';
    return 'Chưa phù hợp yêu cầu';
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mức độ phù hợp CV',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: AppContent(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SCORE-01 · AI Smart Resume Scoring Engine',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (feedback == null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Đối chiếu CV với việc làm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Chọn vị trí bạn quan tâm và tải lên CV để nhận đánh giá từ AI.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Vị trí việc làm đối chiếu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('scoring_choose_job'),
                          onPressed: _loading ? null : _chooseJob,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: _jobTitle != null
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFCBD5E1),
                            ),
                            backgroundColor: _jobTitle != null
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.work_outline_rounded,
                            size: 20,
                            color: _jobTitle != null
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                          label: Text(
                            _jobTitle != null
                                ? '$_jobTitle${_company != null ? ' · $_company' : ''}'
                                : 'Chọn việc làm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _jobTitle != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _jobTitle != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Hồ sơ CV của bạn',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('scoring_choose_cv'),
                          onPressed: _loading || _picking ? null : _pickFile,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: _file != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFCBD5E1),
                            ),
                            backgroundColor: _file != null
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            _file != null
                                ? Icons.check_circle_outline_rounded
                                : Icons.upload_file_rounded,
                            size: 20,
                            color: _file != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                          ),
                          label: Text(
                            _file == null
                                ? 'Tải CV · PDF/DOCX · Tối đa 5 MB'
                                : '${_file!.name} · ${_file!.formattedSize}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _file != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _file != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('scoring_submit'),
                    onPressed: _loading ? null : _score,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Đang chấm CV...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.auto_awesome_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Phân tích CV',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (feedback != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getScoreColor(feedback.score),
                            _getScoreColor(
                              feedback.score,
                            ).withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getScoreColor(
                              feedback.score,
                            ).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${feedback.score.toStringAsFixed(feedback.score % 1 == 0 ? 0 : 1)} / 100',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getScoreLevelText(feedback.score),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Mức độ phù hợp với ${_jobTitle ?? 'việc làm đã chọn'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSkillCategoryCard(
                      title: 'Kỹ năng phù hợp',
                      score: feedback.skillsScore,
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF10B981),
                      skills: feedback.matchingSkills,
                      emptyPlaceholder: 'Chưa có thông tin từ dịch vụ AI.',
                      chipBackgroundColor: const Color(0xFFECFDF5),
                      chipBorderColor: const Color(0xFFA7F3D0),
                      chipTextColor: const Color(0xFF065F46),
                    ),
                    const SizedBox(height: 14),
                    _buildSkillCategoryCard(
                      title: 'Cần bổ sung',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      skills: feedback.missingSkills,
                      emptyPlaceholder:
                          'Dịch vụ không đề xuất kỹ năng bổ sung.',
                      chipBackgroundColor: const Color(0xFFFFFBEB),
                      chipBorderColor: const Color(0xFFFDE68A),
                      chipTextColor: const Color(0xFF92400E),
                    ),
                    if (feedback.extraSkills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildSkillCategoryCard(
                        title: 'Kỹ năng bổ sung trong CV',
                        icon: Icons.add_circle_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        skills: feedback.extraSkills,
                        emptyPlaceholder: '',
                        chipBackgroundColor: const Color(0xFFEFF6FF),
                        chipBorderColor: const Color(0xFFBFDBFE),
                        chipTextColor: const Color(0xFF1E40AF),
                      ),
                    ],
                    if (feedback.experienceScore != null ||
                        feedback.experienceYears != null) ...[
                      const SizedBox(height: 14),
                      _buildExperienceCard(feedback),
                    ],
                    if (feedback.educationScore != null ||
                        feedback.educationDegree != null) ...[
                      const SizedBox(height: 14),
                      _buildEducationCard(feedback),
                    ],
                    if (feedback.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildSuggestionsCard(feedback.suggestions),
                    ],
                    const SizedBox(height: 14),
                    _card(
                      'Lưu ý',
                      'Điểm AI chỉ mang tính tham khảo, không phải quyết định tuyển dụng.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => context.push(
                        '/jobs/${Uri.encodeComponent(_jobId!)}/apply',
                        extra: {'title': _jobTitle, 'company': _company},
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Ứng tuyển ngay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _feedback = null;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Chấm điểm lại / Chọn file khác'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCategoryCard({
    required String title,
    double? score,
    required IconData icon,
    required Color iconColor,
    required List<String> skills,
    required String emptyPlaceholder,
    required Color chipBackgroundColor,
    required Color chipBorderColor,
    required Color chipTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (score != null)
                Text(
                  '${score.round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
            ],
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Text(
              emptyPlaceholder,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: chipBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: chipBorderColor),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: chipTextColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(ResumeFeedback feedback) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.work_history_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đánh giá Kinh nghiệm làm việc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (feedback.experienceScore != null)
                Text(
                  '${feedback.experienceScore!.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (feedback.experienceYears != null)
            Row(
              children: [
                const Text(
                  'Số năm kinh nghiệm trong CV:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  '${feedback.experienceYears} năm',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (feedback.requiredExperienceYears != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(Yêu cầu: ${feedback.requiredExperienceYears} năm)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          if (feedback.experienceRelevance != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Mức độ liên quan:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    feedback.experienceRelevance!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationCard(ResumeFeedback feedback) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trình độ Học vấn & Bằng cấp',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (feedback.educationScore != null)
                Text(
                  '${feedback.educationScore!.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (feedback.educationDegree != null)
            Row(
              children: [
                const Text(
                  'Bằng cấp trong CV:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  feedback.educationDegree!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (feedback.requiredEducationDegree != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(Yêu cầu: ${feedback.requiredEducationDegree})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          if (feedback.educationRelevance != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Độ khớp bằng cấp:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    feedback.educationRelevance!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(List<String> suggestions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Gợi ý cải thiện',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card(String title, String content) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    ),
  );
}

class _ScoringJobPicker extends StatefulWidget {
  const _ScoringJobPicker({required this.repository});
  final IJobRepository repository;
  @override
  State<_ScoringJobPicker> createState() => _ScoringJobPickerState();
}

class _ScoringJobPickerState extends State<_ScoringJobPicker> {
  final _search = TextEditingController();
  late Future<PaginatedJobs> _jobs;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _jobs = widget.repository.getJobs(
      JobFilterParams(
        keyword: _search.text.trim().isEmpty ? null : _search.text.trim(),
        pageSize: 20,
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Chọn việc làm',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => setState(_load),
                  decoration: InputDecoration(
                    hintText: 'Tìm vị trí hoặc công ty',
                    suffixIcon: IconButton(
                      tooltip: 'Tìm kiếm',
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<PaginatedJobs>(
              future: _jobs,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(_load),
                      child: const Text('Không thể tải việc làm. Thử lại'),
                    ),
                  );
                }
                final jobs = snapshot.data?.items ?? [];
                if (jobs.isEmpty) {
                  return const Center(child: Text('Không có kết quả.'));
                }
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(jobs[index].title),
                    subtitle: Text(
                      '${jobs[index].companyName} · ${jobs[index].location}',
                    ),
                    onTap: () => Navigator.of(context).pop(jobs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
