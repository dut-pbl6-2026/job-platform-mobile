import 'dart:async';
import '../../../../core/session/auth_session.dart';
import '../../domain/models/application_model.dart';
import '../../domain/repositories/application_repository.dart';

/// In-memory mock implementation of [IApplicationRepository]
/// Seeded with rich Vietnamese job applications across various stages (APP-01, MOB-01-06)
class MockApplicationRepository implements IApplicationRepository {
  // Singleton instance to share application state across screens during a session
  static final MockApplicationRepository _instance = MockApplicationRepository._internal();
  factory MockApplicationRepository() => _instance;
  MockApplicationRepository._internal() {
    _initSeedData();
  }

  final List<ApplicationModel> _applications = [];

  void _initSeedData() {
    if (_applications.isNotEmpty) return;

    final now = DateTime.now();

    _applications.addAll([
      ApplicationModel(
        id: 'app-001',
        jobId: 'job-1',
        jobTitle: 'Senior Flutter Developer (Cross-Platform)',
        companyName: 'FPT Software',
        companyLogo: 'https://picsum.photos/seed/fpt/200/200',
        applicantId: 'candidate-01',
        applicantName: 'Nguyễn Văn An',
        applicantEmail: 'an.nguyen@example.com',
        applicantPhone: '0905123456',
        coverLetter:
            'Kính gửi Bộ phận Tuyển dụng FPT Software,\n\nTôi có hơn 4 năm kinh nghiệm phát triển ứng dụng di động Flutter/Dart với kiến trúc Clean Architecture, Bloc và Riverpod. Tôi rất mong muốn được đóng góp cho các dự án quy mô lớn của quý công ty.',
        cvUrl: 'https://r2.jobplatform.vn/cvs/Nguyen_Van_An_CV_Flutter.pdf',
        cvFileName: 'Nguyen_Van_An_CV_Flutter.pdf',
        cvFileSize: 450 * 1024,
        status: ApplicationStatus.reviewed,
        recruiterNotes: 'Hồ sơ chuyên môn tốt. Đang sắp xếp lịch phỏng vấn kỹ thuật vòng 1.',
        score: 8.8,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
        statusHistory: [
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.pending,
            note: 'Hồ sơ đã được gửi thành công đến hệ thống.',
            changedAt: now.subtract(const Duration(days: 2, hours: 3)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.reviewed,
            note: 'Nhà tuyển dụng đã xem hồ sơ của bạn.',
            changedAt: now.subtract(const Duration(days: 1)),
            changedBy: 'HR Talent Acquisition',
          ),
        ],
      ),
      ApplicationModel(
        id: 'app-002',
        jobId: 'job-2',
        jobTitle: 'Backend Golang Engineer (High Throughput)',
        companyName: 'VNG Corporation',
        companyLogo: 'https://picsum.photos/seed/vng/200/200',
        applicantId: 'candidate-01',
        applicantName: 'Nguyễn Văn An',
        applicantEmail: 'an.nguyen@example.com',
        applicantPhone: '0905123456',
        coverLetter:
            'Chào quý công ty, tôi đã có kinh nghiệm làm việc với hệ thống phân tán, Kafka message streaming và cơ sở dữ liệu PostgreSQL. Rất mong có cơ hội phỏng vấn.',
        cvUrl: 'https://r2.jobplatform.vn/cvs/Nguyen_Van_An_Backend_Golang.pdf',
        cvFileName: 'Nguyen_Van_An_Backend_Golang.pdf',
        cvFileSize: 380 * 1024,
        status: ApplicationStatus.shortlisted,
        recruiterNotes: 'Kỹ năng Golang và Microservices phù hợp với team ZaloPay Core.',
        score: 9.2,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 2)),
        statusHistory: [
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.pending,
            note: 'Hồ sơ đã gửi.',
            changedAt: now.subtract(const Duration(days: 5)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.reviewed,
            note: 'HR đã tiếp nhận.',
            changedAt: now.subtract(const Duration(days: 4)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.shortlisted,
            note: 'Đạt yêu cầu sơ loại. Đã mời phỏng vấn trực tiếp.',
            changedAt: now.subtract(const Duration(days: 2)),
            changedBy: 'Lead Engineer',
          ),
        ],
      ),
      ApplicationModel(
        id: 'app-003',
        jobId: 'job-3',
        jobTitle: 'Mobile Squad Lead (iOS / Android / Flutter)',
        companyName: 'Viettel Solutions',
        companyLogo: 'https://picsum.photos/seed/viettel/200/200',
        applicantId: 'candidate-01',
        applicantName: 'Nguyễn Văn An',
        applicantEmail: 'an.nguyen@example.com',
        applicantPhone: '0905123456',
        coverLetter:
            'Tôi có kinh nghiệm quản lý đội ngũ 6 kỹ sư mobile, thiết lập quy trình CI/CD và đảm bảo chất lượng phát hành ứng dụng.',
        cvUrl: 'https://r2.jobplatform.vn/cvs/Nguyen_Van_An_Lead_Resume.pdf',
        cvFileName: 'Nguyen_Van_An_Lead_Resume.pdf',
        cvFileSize: 520 * 1024,
        status: ApplicationStatus.accepted,
        recruiterNotes: 'Đã hoàn tất phỏng vấn văn hóa và chuyên môn. Đã gửi Offer Letter.',
        score: 9.5,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 1)),
        statusHistory: [
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.pending,
            note: 'Hồ sơ đã gửi.',
            changedAt: now.subtract(const Duration(days: 12)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.reviewed,
            note: 'Đã xem xét kinh nghiệm quản lý.',
            changedAt: now.subtract(const Duration(days: 10)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.shortlisted,
            note: 'Vượt qua vòng phỏng vấn kỹ thuật.',
            changedAt: now.subtract(const Duration(days: 6)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.accepted,
            note: 'Chúc mừng bạn đã trúng tuyển! Kiểm tra email để nhận Thư mời nhận việc.',
            changedAt: now.subtract(const Duration(days: 1)),
            changedBy: 'Giám đốc Nhân sự',
          ),
        ],
      ),
      ApplicationModel(
        id: 'app-004',
        jobId: 'job-4',
        jobTitle: 'AI Research Scientist (Computer Vision & LLM)',
        companyName: 'VinAI Research',
        companyLogo: 'https://picsum.photos/seed/vinai/200/200',
        applicantId: 'candidate-01',
        applicantName: 'Nguyễn Văn An',
        applicantEmail: 'an.nguyen@example.com',
        applicantPhone: '0905123456',
        coverLetter:
            'Ứng tuyển vị trí AI Scientist với định hướng nghiên cứu mô hình ngôn ngữ lớn (LLM).',
        cvUrl: 'https://r2.jobplatform.vn/cvs/Nguyen_Van_An_AI_CV.pdf',
        cvFileName: 'Nguyen_Van_An_AI_CV.pdf',
        cvFileSize: 610 * 1024,
        status: ApplicationStatus.rejected,
        recruiterNotes: 'Vị trí hiện tại ưu tiên ứng viên có bằng Tiến sĩ chuyên ngành AI.',
        score: 7.0,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 15)),
        statusHistory: [
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.pending,
            note: 'Hồ sơ đã gửi.',
            changedAt: now.subtract(const Duration(days: 20)),
          ),
          ApplicationStatusHistoryItem(
            status: ApplicationStatus.rejected,
            note: 'Hồ sơ chưa đạt tiêu chuẩn yêu cầu học vị của vị trí này.',
            changedAt: now.subtract(const Duration(days: 15)),
            changedBy: 'Hội đồng Tuyển dụng VinAI',
          ),
        ],
      ),
    ]);
  }

  @override
  Future<ApplicationModel> applyJob(ApplyJobParams params) async {
    // Artificial delay to mimic network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Duplicate prevention check (APP-01-02)
    final alreadyApplied = _applications.any((app) => app.jobId == params.jobId);
    if (alreadyApplied) {
      throw Exception('Bạn đã nộp hồ sơ cho vị trí này rồi. Vui lòng kiểm tra lịch sử ứng tuyển.');
    }

    final currentUser = AuthSession.instance.currentUser;
    final now = DateTime.now();

    final newApp = ApplicationModel(
      id: 'app-${now.millisecondsSinceEpoch}',
      jobId: params.jobId,
      jobTitle: params.jobTitle,
      companyName: params.companyName,
      companyLogo: params.companyLogo,
      applicantId: currentUser?.id ?? 'user-current',
      applicantName: currentUser?.name ?? 'Ứng viên',
      applicantEmail: currentUser?.email ?? 'candidate@example.com',
      applicantPhone: '0905123456',
      coverLetter: params.coverLetter,
      cvUrl: 'https://r2.jobplatform.vn/cvs/${params.cvFileName}',
      cvFileName: params.cvFileName,
      cvFileSize: params.cvFileSize ?? (350 * 1024),
      status: ApplicationStatus.pending,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        ApplicationStatusHistoryItem(
          status: ApplicationStatus.pending,
          note: 'Hồ sơ đã nộp thành công và đang chờ nhà tuyển dụng xem xét.',
          changedAt: now,
        ),
      ],
    );

    // Prepend to top of list
    _applications.insert(0, newApp);
    return newApp;
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({
    ApplicationStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = _applications;
    if (status != null) {
      filtered = _applications.where((app) => app.status == status).toList();
    }

    // Pagination
    final start = page * size;
    if (start >= filtered.length) {
      return [];
    }
    final end = (start + size < filtered.length) ? start + size : filtered.length;
    return filtered.sublist(start, end);
  }

  @override
  Future<ApplicationModel?> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _applications.firstWhere((app) => app.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasApplied(String jobId) async {
    return _applications.any((app) => app.jobId == jobId);
  }

  /// Helper for tests to reset state
  void clear() {
    _applications.clear();
    _initSeedData();
  }
}
