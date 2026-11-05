import 'package:flutter/material.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ai_copilot/data/api_ai_repository.dart';
import '../../../ai_copilot/domain/ai_repository.dart';
import '../../domain/models/job_model.dart';

/// Inline AI Smart Resume Scoring Card for Job Detail Screen (SCORE-01, PBL6-10)
/// Allows candidates to upload their CV, evaluate compatibility via AI,
/// and review score breakdown & suggestions directly in-place without navigating away.
class JobDetailAiScoringCard extends StatefulWidget {
  final JobModel job;
  final IAiRepository? aiRepository;
  final ICvPickerService? cvPickerService;
  final VoidCallback? onApplyPressed;

  const JobDetailAiScoringCard({
    super.key,
    required this.job,
    this.aiRepository,
    this.cvPickerService,
    this.onApplyPressed,
  });

  @override
  State<JobDetailAiScoringCard> createState() => _JobDetailAiScoringCardState();
}

enum _ScoringCardStatus { idle, picking, scoring, success, error }

class _JobDetailAiScoringCardState extends State<JobDetailAiScoringCard> {
  late final IAiRepository _aiRepository;
  late final ICvPickerService _cvPickerService;

  _ScoringCardStatus _status = _ScoringCardStatus.idle;
  SelectedCvFile? _file;
  ResumeFeedback? _feedback;
  String? _errorMessage;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _aiRepository = widget.aiRepository ?? ApiAiRepository();
    _cvPickerService = widget.cvPickerService ?? const DeviceCvPickerService();
  }

  @override
  void dispose() {
    _aiRepository.cancelCurrentRequest();
    super.dispose();
  }

  Future<void> _pickAndScoreCv() async {
    if (_status == _ScoringCardStatus.scoring ||
        _status == _ScoringCardStatus.picking) {
      return;
    }

    setState(() {
      _status = _ScoringCardStatus.picking;
      _errorMessage = null;
    });

    try {
      final file = await _cvPickerService.pickCvFile();
      if (!mounted) return;

      if (file == null) {
        // User dismissed file picker without selecting
        setState(() {
          _status = _feedback != null
              ? _ScoringCardStatus.success
              : _ScoringCardStatus.idle;
        });
        return;
      }

      // Validate format and size (<= 5 MB)
      if (!file.isValidCvFormat ||
          file.size <= 0 ||
          file.size > 5 * 1024 * 1024) {
        setState(() {
          _status = _ScoringCardStatus.error;
          _errorMessage =
              'Vui lòng chọn CV định dạng PDF hoặc DOCX (dung lượng tối đa 5 MB).';
        });
        return;
      }

      setState(() {
        _file = file;
        _status = _ScoringCardStatus.scoring;
        _errorMessage = null;
      });

      final feedback = await _aiRepository.scoreResume(
        AiCvInput(
          name: file.name,
          size: file.size,
          bytes: file.bytes,
          path: file.path,
        ),
        jobId: widget.job.id,
      );

      if (!mounted) return;

      setState(() {
        _feedback = feedback;
        _status = _ScoringCardStatus.success;
        _isExpanded = true;
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ScoringCardStatus.error;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _ScoringCardStatus.error;
        _errorMessage =
            'Không thể phân tích CV lúc này. Vui lòng kiểm tra lại kết nối và thử lại.';
      });
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
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: switch (_status) {
        _ScoringCardStatus.idle => _buildIdleBanner(context),
        _ScoringCardStatus.picking ||
        _ScoringCardStatus.scoring => _buildScoringProgress(context),
        _ScoringCardStatus.success => _buildScoringResult(context),
        _ScoringCardStatus.error => _buildErrorCard(context),
      },
    );
  }

  /// Initial idle state matching the design banner in Job Detail
  Widget _buildIdleBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('job_detail_ai_scoring_banner'),
          borderRadius: BorderRadius.circular(16),
          onTap: _pickAndScoreCv,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF0085FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Chấm điểm CV với vị trí này',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Phân tích kỹ năng, kinh nghiệm & gợi ý tối ưu CV',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('job_detail_score_resume_button'),
                    onPressed: _pickAndScoreCv,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text(
                      'Tải CV & Chấm điểm ngay',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// In-place loading and AI analysis indicator
  Widget _buildScoringProgress(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI đang chấm điểm hồ sơ của bạn...',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_file!.name} (${_file!.formattedSize})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFEFF6FF),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            minHeight: 4,
          ),
          const SizedBox(height: 10),
          Text(
            'Đang đối chiếu kỹ năng & kinh nghiệm với vị trí ${widget.job.title}...',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Full inline results breakdown
  Widget _buildScoringResult(BuildContext context) {
    final feedback = _feedback!;
    final scoreColor = _getScoreColor(feedback.score);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Result Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kết quả chấm điểm AI',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF2563EB),
                  ),
                  label: Text(
                    _isExpanded ? 'Thu gọn' : 'Chi tiết',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Active File Info Pill
          if (_file != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_file!.name} · ${_file!.formattedSize}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // 3. Highlight Score Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scoreColor, scoreColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${feedback.score.toStringAsFixed(feedback.score % 1 == 0 ? 0 : 1)} / 100',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getScoreLevelText(feedback.score),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Độ tương thích với vị trí ${widget.job.title}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // 4. Expanded Breakdown Sections
          if (_isExpanded) ...[
            const SizedBox(height: 14),

            // Matching Skills Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSkillBadgeCard(
                title: 'Kỹ năng phù hợp',
                count: feedback.matchingSkills.length,
                skills: feedback.matchingSkills,
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
                emptyText: 'Chưa tìm thấy kỹ năng khớp trực tiếp trong CV.',
                chipBg: const Color(0xFFECFDF5),
                chipBorder: const Color(0xFFA7F3D0),
                chipText: const Color(0xFF065F46),
              ),
            ),

            const SizedBox(height: 12),

            // Missing Skills Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSkillBadgeCard(
                title: 'Kỹ năng cần bổ sung',
                count: feedback.missingSkills.length,
                skills: feedback.missingSkills,
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFF59E0B),
                emptyText: 'Bạn đã đáp ứng đủ các kỹ năng cốt lõi yêu cầu.',
                chipBg: const Color(0xFFFFFBEB),
                chipBorder: const Color(0xFFFDE68A),
                chipText: const Color(0xFF92400E),
              ),
            ),

            // Extra Skills (if any)
            if (feedback.extraSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSkillBadgeCard(
                  title: 'Kỹ năng bổ sung trong CV',
                  count: feedback.extraSkills.length,
                  skills: feedback.extraSkills,
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: const Color(0xFF2563EB),
                  emptyText: '',
                  chipBg: const Color(0xFFEFF6FF),
                  chipBorder: const Color(0xFFBFDBFE),
                  chipText: const Color(0xFF1E40AF),
                ),
              ),
            ],

            // Experience & Education Cards
            if (feedback.experienceYears != null ||
                feedback.experienceScore != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildExperienceSummary(feedback),
              ),
            ],

            if (feedback.educationDegree != null ||
                feedback.educationScore != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEducationSummary(feedback),
              ),
            ],

            // Suggestions from AI
            if (feedback.suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSuggestionsSummary(feedback.suggestions),
              ),
            ],
          ],

          const SizedBox(height: 14),

          // 5. Action Buttons (Rescore & Apply)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final rescoreBtn = OutlinedButton.icon(
                  key: const Key('job_detail_rescore_button'),
                  onPressed: _pickAndScoreCv,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Chấm lại CV khác',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );

                final applyBtn = widget.onApplyPressed != null
                    ? FilledButton.icon(
                        key: const Key('job_detail_apply_after_scoring_button'),
                        onPressed: widget.onApplyPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text(
                          'Ứng tuyển ngay',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : null;

                if (isNarrow && applyBtn != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [applyBtn, const SizedBox(height: 8), rescoreBtn],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: rescoreBtn),
                    if (applyBtn != null) ...[
                      const SizedBox(width: 8),
                      Expanded(child: applyBtn),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Skill chip group component
  Widget _buildSkillBadgeCard({
    required String title,
    required int count,
    required List<String> skills,
    required IconData icon,
    required Color iconColor,
    required String emptyText,
    required Color chipBg,
    required Color chipBorder,
    required Color chipText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: chipBorder),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: chipText,
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

  /// Experience summary card
  Widget _buildExperienceSummary(ResumeFeedback feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.work_history_rounded,
            color: Color(0xFF2563EB),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kinh nghiệm làm việc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CV: ${feedback.experienceYears ?? 0} năm '
                  '${feedback.requiredExperienceYears != null ? '· Yêu cầu: ${feedback.requiredExperienceYears} năm' : ''}'
                  '${feedback.experienceRelevance != null ? ' (${feedback.experienceRelevance})' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          if (feedback.experienceScore != null) ...[
            const SizedBox(width: 8),
            Text(
              '${feedback.experienceScore!.round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Education summary card
  Widget _buildEducationSummary(ResumeFeedback feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Học vấn & Bằng cấp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CV: ${feedback.educationDegree ?? 'Không rõ'} '
                  '${feedback.requiredEducationDegree != null ? '· Yêu cầu: ${feedback.requiredEducationDegree}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          if (feedback.educationScore != null) ...[
            const SizedBox(width: 8),
            Text(
              '${feedback.educationScore!.round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Suggestions summary
  Widget _buildSuggestionsSummary(List<String> suggestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Gợi ý tối ưu từ AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error card with retry
  Widget _buildErrorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Không thể hoàn tất chấm điểm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ??
                'Đã xảy ra lỗi trong quá trình xử lý CV. Vui lòng thử lại.',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFFB91C1C),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                key: const Key('job_detail_retry_scoring_button'),
                onPressed: _pickAndScoreCv,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _status = _ScoringCardStatus.idle;
                    _errorMessage = null;
                  });
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Đóng', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
