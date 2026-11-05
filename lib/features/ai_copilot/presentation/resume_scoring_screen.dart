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

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppContent(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Quay lại'),
                    ),
                  ),
                  const Text(
                    'Mức độ phù hợp CV',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  if (feedback == null) ...[
                    _card(
                      'Đối chiếu CV với việc làm',
                      'Chọn vị trí bạn quan tâm và CV để nhận đánh giá từ AI.',
                    ),
                    const SizedBox(height: 14),
                  ],
                  OutlinedButton.icon(
                    key: const Key('scoring_choose_job'),
                    onPressed: _loading ? null : _chooseJob,
                    icon: const Icon(Icons.work_outline),
                    label: Text(_jobTitle ?? 'Chọn việc làm'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('scoring_choose_cv'),
                    onPressed: _loading || _picking ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _file == null
                          ? 'Tải CV · PDF/DOCX · Tối đa 5 MB'
                          : '${_file!.name} · ${_file!.formattedSize}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const Key('scoring_submit'),
                    onPressed: _loading ? null : _score,
                    child: _loading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Đang chấm CV...'),
                            ],
                          )
                        : const Text('Phân tích CV'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  if (feedback != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${feedback.score.toStringAsFixed(feedback.score % 1 == 0 ? 0 : 1)} / 100',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mức độ phù hợp với ${_jobTitle ?? 'việc làm đã chọn'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _card(
                      'Kỹ năng phù hợp',
                      feedback.matchingSkills.isEmpty
                          ? 'Chưa có thông tin từ dịch vụ AI.'
                          : feedback.matchingSkills.join(' · '),
                    ),
                    const SizedBox(height: 14),
                    _card(
                      'Cần bổ sung',
                      feedback.missingSkills.isEmpty
                          ? 'Dịch vụ không đề xuất kỹ năng bổ sung.'
                          : feedback.missingSkills.join(' · '),
                    ),
                    if (feedback.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _card('Gợi ý cải thiện', feedback.suggestions.join('\n')),
                    ],
                    const SizedBox(height: 14),
                    _card(
                      'Lưu ý',
                      'Điểm AI chỉ mang tính tham khảo, không phải quyết định tuyển dụng.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => context.push(
                        '/jobs/${Uri.encodeComponent(_jobId!)}/apply',
                        extra: {'title': _jobTitle, 'company': _company},
                      ),
                      child: const Text('Ứng tuyển ngay'),
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

  Widget _card(String title, String content) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
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
