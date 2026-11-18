import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/session/auth_session.dart';
import '../../../applications/data/repositories/api_application_repository.dart';
import '../../domain/models/recruiter_models.dart';
import '../../domain/repositories/recruiter_repository.dart';
import 'mock_recruiter_repository.dart';

/// Remote API implementation of [IRecruiterRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1).
/// Direct microservice port access is prohibited.
///
/// Mock data is only reachable when the build enables it
/// (`--dart-define=ENABLE_MOCKS=true`) and the failure is a transport failure or
/// a 5xx. A revoked token or a stale company id (401/403) surfaces as an error
/// instead of invented jobs, candidates and statistics.
class ApiRecruiterRepository implements IRecruiterRepository {
  final Dio _dio;
  final MockRecruiterRepository _fallbackMock = MockRecruiterRepository();
  final bool _enableMocks;
  bool _isMock = false;

  ApiRecruiterRepository({Dio? dio, bool? enableMockFallback})
    : _dio = dio ?? DioProvider.instance.dio,
      _enableMocks = enableMockFallback ?? kEnableMocks;

  @override
  bool get isMock => _isMock;

  @override
  Future<List<CandidateApplication>> getCandidateApplications({
    String? jobId,
    String? status,
  }) async {
    try {
      if (jobId != null && jobId.isNotEmpty) {
        return await _fetchApplicationsForJob(jobId, status: status);
      } else {
        // When no jobId is specified (e.g. from Recruiter Dashboard),
        // fetch applications across all jobs posted by this recruiter.
        final jobs = await getMyJobs();
        final allCandidates = <CandidateApplication>[];
        for (final job in jobs) {
          if (job.id.isNotEmpty) {
            try {
              final apps = await _fetchApplicationsForJob(
                job.id,
                status: status,
              );
              allCandidates.addAll(apps);
            } catch (e) {
              debugPrint(
                '[ApiRecruiterRepository] Error fetching applications for job ${job.id}: $e',
              );
            }
          }
        }
        if (allCandidates.isNotEmpty || !_isMock) {
          _isMock = false;
          return allCandidates;
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Candidate applications failed: '
        '${e.response?.statusCode ?? e.type}.',
      );
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        rethrow;
      }
    }

    _isMock = true;
    return _fallbackMock.getCandidateApplications(jobId: jobId, status: status);
  }

  Future<List<CandidateApplication>> _fetchApplicationsForJob(
    String jobId, {
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null && status.isNotEmpty)
        'status': _mapStatusToBackend(status),
    };

    final response = await _dio.get(
      '/api/applications/job/$jobId',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final List items = data is Map
          ? (data['items'] as List? ?? [])
          : (data as List);
      _isMock = false;
      return items
          .map(
            (item) => CandidateApplication.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<bool> updateCandidateStatus(
    String applicationId,
    String newStatus,
  ) async {
    try {
      final backendStatus = _mapStatusToBackend(newStatus);
      final response = await _dio.put(
        '/api/applications/$applicationId/status',
        data: {
          'status': backendStatus,
          'note': 'Cập nhật trạng thái bởi nhà tuyển dụng',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _isMock = false;
        return true;
      }
      throw Exception('Cập nhật trạng thái thất bại. Vui lòng thử lại.');
    } on DioException catch (e) {
      final message = _extractSafeErrorMessage(
        e,
        fallback: 'Không thể cập nhật trạng thái ứng viên. Vui lòng thử lại.',
      );
      if (kDebugMode) {
        debugPrint(
          '[ApiRecruiterRepository] Status update failed: ${e.message}',
        );
      }
      throw Exception(message);
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Unexpected error updating status: $e',
      );
      rethrow;
    }
  }

  @override
  Future<List<JobCategoryItem>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final List items = raw is List
            ? raw
            : (raw is Map ? (raw['items'] as List? ?? const []) : const []);
        return items
            .whereType<Map>()
            .map(
              (e) => JobCategoryItem.fromJson(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
              ),
            )
            .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      if (shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        return _fallbackMock.getCategories();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<RecruiterJob>> getMyJobs({
    String? status,
    int? page,
    int? pageSize,
  }) async {
    try {
      // A UI status without a job-svc equivalent is omitted, not guessed.
      final backendStatus = status == null
          ? null
          : _mapJobStatusToBackend(status);
      final queryParams = <String, dynamic>{
        'status': ?backendStatus,
        'page': ?page,
        'size': ?pageSize,
      };

      final response = await _dio.get(
        '/api/jobs/recruiter',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List items = data is Map
            ? (data['items'] as List? ?? [])
            : (data as List);
        _isMock = false;
        return items
            .map(
              (item) =>
                  RecruiterJob.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
    } on DioException catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Recruiter jobs failed: '
        '${e.response?.statusCode ?? e.type}.',
      );
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        rethrow;
      }
    }

    _isMock = true;
    return _fallbackMock.getMyJobs(status: status);
  }

  @override
  Future<RecruiterStats> getDashboardStats() async {
    // getMyJobs throws when the gateway answered and mocks are off; that error
    // must reach the screen instead of becoming invented statistics.
    final jobs = await getMyJobs();
    if (!_isMock) {
      final active = jobs.where((j) => j.isOpen).length;
      final totalApps = jobs.fold<int>(
        0,
        (sum, j) => sum + j.applicationsCount,
      );
      final totalViews = jobs.fold<int>(0, (sum, j) => sum + j.viewsCount);

      // Compute actual new (pending) and interviewed/shortlisted applications
      int newApps = totalApps;
      int shortlistedCount = 0;
      try {
        final candidates = await getCandidateApplications();
        if (candidates.isNotEmpty) {
          newApps = candidates.where((c) => c.isPending).length;
          shortlistedCount = candidates
              .where(
                (c) =>
                    c.isShortlisted ||
                    c.status == 'Được nhận' ||
                    c.status.toLowerCase() == 'accepted',
              )
              .length;
        }
      } catch (_) {
        // If candidates fetch fails, keep totalApps
      }

      return RecruiterStats(
        activeJobsCount: active,
        newApplicationsCount: newApps,
        viewsCount: totalViews,
        interviewsCount: shortlistedCount,
      );
    }

    // getMyJobs already fell back to mock data, so the statistics match it.
    return _fallbackMock.getDashboardStats();
  }

  Future<String> _resolveCompanyId(String? explicit) async {
    final trimmed = explicit?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;

    final fromUser = AuthSession.instance.currentUser?.companyId?.trim() ?? '';
    if (fromUser.isNotEmpty) return fromUser;

    final fromJwt = AuthSession.instance.companyId?.trim() ?? '';
    if (fromJwt.isNotEmpty) return fromJwt;

    try {
      final res = await _dio.get('/api/companies/mine');
      if (res.statusCode == 200 && res.data is Map) {
        final companyId = (res.data as Map)['id']?.toString().trim() ?? '';
        if (companyId.isNotEmpty) return companyId;
      }
    } catch (_) {
      // Handled by empty-companyId error below.
    }

    throw Exception(
      'Không tìm thấy thông tin doanh nghiệp của nhà tuyển dụng. Vui lòng cập nhật hồ sơ doanh nghiệp trước khi đăng tin.',
    );
  }

  @override
  Future<String> postJob(PostJobParams params) async {
    try {
      // Resolve recruiter's own companyId via explicit param, JWT/session, or /api/companies/mine.
      final companyId = await _resolveCompanyId(params.companyId);

      final payload = _buildJobPayload(params, companyId: companyId);

      final response = await _dio.post('/api/jobs', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        _isMock = false;
        if (data is Map && data['id'] != null) {
          return data['id'].toString();
        }
        return 'job_created';
      }

      throw Exception('Đăng tin tuyển dụng thất bại. Vui lòng thử lại.');
    } on DioException catch (e) {
      final message = _extractSafeErrorMessage(
        e,
        fallback:
            'Không thể kết nối máy chủ để đăng tin. Vui lòng kiểm tra mạng và thử lại.',
      );
      if (kDebugMode) {
        debugPrint('[ApiRecruiterRepository] Error posting job: ${e.message}');
      }
      throw Exception(message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiRecruiterRepository] Unexpected error posting job: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateJob(String jobId, PostJobParams params) async {
    try {
      final companyId = await _resolveCompanyId(params.companyId);
      final payload = _buildJobPayload(params, companyId: companyId);
      final response = await _dio.put('/api/jobs/$jobId', data: payload);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _isMock = false;
        return;
      }
      throw Exception('Cập nhật tin tuyển dụng thất bại. Vui lòng thử lại.');
    } on DioException catch (e) {
      final message = _extractSafeErrorMessage(
        e,
        fallback: 'Không thể cập nhật tin tuyển dụng. Vui lòng thử lại.',
      );
      if (kDebugMode) {
        debugPrint('[ApiRecruiterRepository] Error updating job: ${e.message}');
      }
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    try {
      final response = await _dio.delete('/api/jobs/$jobId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _isMock = false;
        return;
      }
      throw Exception('Không thể xóa tin tuyển dụng. Vui lòng thử lại.');
    } on DioException catch (e) {
      final message = _extractSafeErrorMessage(
        e,
        fallback: 'Không thể xóa tin tuyển dụng lúc này. Vui lòng thử lại.',
      );
      if (kDebugMode) {
        debugPrint('[ApiRecruiterRepository] Error deleting job: ${e.message}');
      }
      throw Exception(message);
    }
  }

  Map<String, dynamic> _buildJobPayload(
    PostJobParams params, {
    String? companyId,
  }) {
    return {
      'title': params.title,
      'description': params.description,
      if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
      'location': params.location,
      if (params.salaryMin != null) 'salaryMin': params.salaryMin,
      if (params.salaryMax != null) 'salaryMax': params.salaryMax,
      'salaryCurrency': params.salaryCurrency,
      if (params.categoryId != null && params.categoryId!.isNotEmpty)
        'categoryId': params.categoryId,
      if (params.requirements != null && params.requirements!.isNotEmpty)
        'requirements': params.requirements,
      if (params.benefits != null && params.benefits!.isNotEmpty)
        'benefits': params.benefits,
      'employmentType': _mapEmploymentTypeToBackend(params.employmentType),
      'experienceLevel': _mapExperienceLevelToBackend(params.experienceLevel),
    };
  }

  String _extractSafeErrorMessage(DioException e, {required String fallback}) {
    final code = e.response?.statusCode;
    if (code == 400 || code == 422) {
      return 'Thông tin tin tuyển dụng chưa hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (code == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (code == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (code == 404) {
      return 'Không tìm thấy tin tuyển dụng hoặc hồ sơ yêu cầu.';
    }
    if (code == 429) {
      return 'Bạn đã gửi yêu cầu quá nhiều lần. Vui lòng thử lại sau.';
    }
    if (code != null && code >= 500) {
      return 'Hệ thống tạm thời gián đoạn. Vui lòng thử lại sau.';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Hết thời gian kết nối tới máy chủ.',
      DioExceptionType.sendTimeout => 'Hết thời gian gửi dữ liệu tới máy chủ.',
      DioExceptionType.receiveTimeout =>
        'Hết thời gian chờ phản hồi từ máy chủ.',
      DioExceptionType.connectionError =>
        'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng.',
      _ => fallback,
    };
  }

  String _mapStatusToBackend(String uiStatus) {
    switch (uiStatus.trim().toLowerCase()) {
      case 'chờ xem':
      case 'pending':
        return 'pending';
      case 'đã xem':
      case 'reviewed':
        return 'reviewed';
      case 'phù hợp':
      case 'shortlisted':
        return 'shortlisted';
      case 'được nhận':
      case 'accepted':
        return 'accepted';
      case 'từ chối':
      case 'rejected':
        return 'rejected';
      default:
        return 'pending';
    }
  }

  /// Maps a UI job status to a job-svc `JobStatus`. Companies publish
  /// immediately, so legacy "pending"/"draft" values filter as Active.
  String? _mapJobStatusToBackend(String uiStatus) {
    switch (uiStatus.trim().toLowerCase()) {
      case 'active':
      case 'đang mở':
      case 'chờ duyệt':
      case 'pending':
      case 'draft':
        return 'Active';
      case 'closed':
      case 'đã đóng':
        return 'Closed';
      default:
        return null;
    }
  }

  /// Maps the form's employment label to the canonical job-svc value
  /// (api-conventions §6). Unknown input throws instead of defaulting.
  String _mapEmploymentTypeToBackend(String type) {
    switch (type.trim().toLowerCase()) {
      case 'toàn thời gian':
      case 'fulltime':
      case 'full-time':
        return 'FullTime';
      case 'bán thời gian':
      case 'parttime':
      case 'part-time':
        return 'PartTime';
      case 'hợp đồng':
      case 'contract':
        return 'Contract';
      case 'thực tập':
      case 'internship':
        return 'Internship';
    }
    throw Exception('Hình thức làm việc không hợp lệ: $type');
  }

  @override
  Future<Uint8List> downloadCvBytes(String cvUrl) =>
      ApiApplicationRepository.downloadCvWithDio(_dio, cvUrl);

  /// Accepts only the canonical job-svc experience levels. Null or unknown
  /// input throws; the form requires a choice, and no level is guessed.
  String _mapExperienceLevelToBackend(String? level) {
    final value = level?.trim();
    for (final canonical in const ['Entry', 'Mid', 'Senior', 'Lead']) {
      if (value == canonical) return canonical;
    }
    throw Exception('Cấp độ kinh nghiệm không hợp lệ: ${level ?? 'chưa chọn'}');
  }
}
