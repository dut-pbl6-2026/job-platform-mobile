import '../../domain/models/recruiter_models.dart';
import '../../domain/repositories/recruiter_repository.dart';

/// Mock implementation of [IRecruiterRepository] with in-memory state.
/// Used for prototype previews, offline fallback, and widget testing.
class MockRecruiterRepository implements IRecruiterRepository {
  final Duration delay;

  MockRecruiterRepository({this.delay = Duration.zero});

  @override
  bool get isMock => true;

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }

  final List<CandidateApplication> _candidates = [
    const CandidateApplication(
      id: 'cand_1',
      jobId: 'rec_job_1',
      name: 'Khoa Phạm',
      title: 'UI/UX Designer',
      experience: '2 năm kinh nghiệm',
      status: 'Chờ xem',
      cvName: 'CV_KhoaPham_UIUX.pdf',
      appliedDate: '08/10/2026',
      skills: ['Figma', 'UI Design', 'Prototyping'],
      matchScore: 92,
    ),
    const CandidateApplication(
      id: 'cand_2',
      jobId: 'rec_job_1',
      name: 'Nguyễn Minh Anh',
      title: 'Product Designer',
      experience: '3 năm kinh nghiệm',
      status: 'Đã xem',
      cvName: 'MinhAnh_Resume_2026.pdf',
      appliedDate: '07/10/2026',
      skills: ['Design System', 'User Testing', 'Figma'],
      matchScore: 88,
    ),
    const CandidateApplication(
      id: 'cand_3',
      jobId: 'rec_job_1',
      name: 'Trần Văn Hùng',
      title: 'Senior UI/UX Specialist',
      experience: '5 năm kinh nghiệm',
      status: 'Được nhận',
      cvName: 'TranHung_SeniorDesigner.pdf',
      appliedDate: '05/10/2026',
      skills: ['Figma', 'Mobile & Web', 'Team Lead'],
      matchScore: 95,
    ),
    const CandidateApplication(
      id: 'cand_4',
      jobId: 'rec_job_2',
      name: 'Lê Thu Trang',
      title: 'Junior UI Designer',
      experience: '1 năm kinh nghiệm',
      status: 'Từ chối',
      cvName: 'ThuTrang_JuniorUI.pdf',
      appliedDate: '02/10/2026',
      skills: ['Photoshop', 'Illustrator'],
      matchScore: 68,
    ),
  ];

  final List<RecruiterJob> _jobs = [
    const RecruiterJob(
      id: 'rec_job_1',
      title: 'UI/UX Designer',
      status: 'Đang mở',
      applicationsCount: 18,
      viewsCount: 240,
      location: 'Đà Nẵng · Hybrid',
      salary: '20 – 35 triệu',
      postedDate: '05/10/2026',
    ),
    const RecruiterJob(
      id: 'rec_job_2',
      title: 'Senior Flutter Engineer',
      status: 'Đang mở',
      applicationsCount: 12,
      viewsCount: 185,
      location: 'Từ xa · Remote',
      salary: '30 – 50 triệu',
      postedDate: '02/10/2026',
    ),
    const RecruiterJob(
      id: 'rec_job_3',
      title: 'Product Manager',
      status: 'Chờ duyệt',
      applicationsCount: 0,
      viewsCount: 0,
      location: 'TP. Hồ Chí Minh',
      salary: '35 – 55 triệu',
      postedDate: '08/10/2026',
    ),
    const RecruiterJob(
      id: 'rec_job_4',
      title: 'Backend Developer (.NET / C#)',
      status: 'Đã đóng',
      applicationsCount: 24,
      viewsCount: 310,
      location: 'Đà Nẵng · Onsite',
      salary: '22 – 40 triệu',
      postedDate: '15/09/2026',
    ),
  ];

  @override
  Future<List<CandidateApplication>> getCandidateApplications({
    String? jobId,
    String? status,
  }) async {
    await _simulateDelay();
    var result = List<CandidateApplication>.from(_candidates);
    if (jobId != null && jobId.isNotEmpty) {
      final filtered = result.where((c) => c.jobId == jobId).toList();
      if (filtered.isNotEmpty) {
        result = filtered;
      }
    }
    if (status != null && status.isNotEmpty) {
      result = result.where((c) => c.status == status).toList();
    }
    return result;
  }

  @override
  Future<bool> updateCandidateStatus(
    String applicationId,
    String newStatus,
  ) async {
    await _simulateDelay();
    final index = _candidates.indexWhere((c) => c.id == applicationId);
    if (index != -1) {
      _candidates[index] = _candidates[index].copyWith(status: newStatus);
      return true;
    }
    return false;
  }

  @override
  Future<List<RecruiterJob>> getMyJobs({String? status}) async {
    await _simulateDelay();
    var result = List<RecruiterJob>.from(_jobs);
    if (status != null && status.isNotEmpty) {
      result = result.where((j) => j.status == status).toList();
    }
    return result;
  }

  @override
  Future<RecruiterStats> getDashboardStats() async {
    await _simulateDelay();
    final active = _jobs.where((j) => j.status == 'Đang mở').length;
    final totalApps = _candidates.length;
    final totalViews = _jobs.fold<int>(0, (sum, j) => sum + j.viewsCount);
    return RecruiterStats(
      activeJobsCount: active,
      newApplicationsCount: totalApps > 0 ? 54 : 0,
      viewsCount: totalViews > 0 ? totalViews : 1200,
      interviewsCount: 12,
    );
  }

  @override
  Future<String> postJob(PostJobParams params) async {
    await _simulateDelay();
    final newId = 'job_${DateTime.now().millisecondsSinceEpoch}';
    final newJob = RecruiterJob(
      id: newId,
      title: params.title,
      status: 'Chờ duyệt',
      applicationsCount: 0,
      viewsCount: 0,
      location: params.location,
      salary: params.salaryText.isNotEmpty ? params.salaryText : 'Thoả thuận',
      postedDate: DateTime.now().toString().split(' ').first,
    );
    _jobs.insert(0, newJob);
    return newId;
  }
}
