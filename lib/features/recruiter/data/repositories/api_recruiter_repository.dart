import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/session/auth_session.dart';
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
      final errorMsg =
          _extractErrorMessageFromData(response.data) ??
          'Cập nhật trạng thái thất bại (${response.statusCode})';
      throw Exception(errorMsg);
    } on DioException catch (e) {
      final message =
          _extractErrorMessage(e) ??
          'Không thể cập nhật trạng thái ứng viên. Vui lòng thử lại.';
      debugPrint('[ApiRecruiterRepository] Status update failed: ${e.message}');
      throw Exception(message);
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Unexpected error updating status: $e',
      );
      rethrow;
    }
  }

  @override
  Future<List<RecruiterJob>> getMyJobs({String? status}) async {
    try {
      // A UI status without a job-svc equivalent is omitted, not guessed.
      final backendStatus = status == null
          ? null
          : _mapJobStatusToBackend(status);
      final queryParams = <String, dynamic>{'status': ?backendStatus};

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

  @override
  Future<String> postJob(PostJobParams params) async {
    try {
      // Resolve recruiter's own companyId (never take random public company)
      String companyId = params.companyId ?? '';
      if (companyId.isEmpty) {
        companyId = AuthSession.instance.currentUser?.companyId ?? '';
      }
      if (companyId.isEmpty) {
        final jwtCompId = AuthSession.instance.companyId;
        if (jwtCompId != null && jwtCompId.isNotEmpty) {
          companyId = jwtCompId;
        }
      }
      if (companyId.isEmpty) {
        // Try fetching user profile from /api/profiles/me
        try {
          final profileRes = await _dio.get('/api/profiles/me');
          if (profileRes.statusCode == 200 && profileRes.data is Map) {
            final pData = profileRes.data as Map;
            companyId =
                pData['companyId']?.toString() ??
                pData['company_id']?.toString() ??
                '';
          }
        } catch (_) {
          // Profile fetch error
        }
      }

      if (companyId.isEmpty) {
        throw Exception(
          'Không tìm thấy thông tin doanh nghiệp của nhà tuyển dụng. Vui lòng cập nhật hồ sơ doanh nghiệp trước khi đăng tin.',
        );
      }

      final payload = {
        'title': params.title,
        'description': params.description,
        'companyId': companyId,
        'location': params.location,
        if (params.salaryMin != null) 'salaryMin': params.salaryMin,
        if (params.salaryMax != null) 'salaryMax': params.salaryMax,
        'salaryCurrency': params.salaryCurrency,
        if (params.categoryId != null) 'categoryId': params.categoryId,
        if (params.requirements != null && params.requirements!.isNotEmpty)
          'requirements': params.requirements,
        if (params.benefits != null && params.benefits!.isNotEmpty)
          'benefits': params.benefits,
        'employmentType': _mapEmploymentTypeToBackend(params.employmentType),
        'experienceLevel': _mapExperienceLevelToBackend(params.experienceLevel),
      };

      final response = await _dio.post('/api/jobs', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        _isMock = false;
        if (data is Map && data['id'] != null) {
          return data['id'].toString();
        }
        return 'job_created';
      }

      final errorMsg =
          _extractErrorMessageFromData(response.data) ??
          'Đăng tin tuyển dụng thất bại (${response.statusCode})';
      throw Exception(errorMsg);
    } on DioException catch (e) {
      final message =
          _extractErrorMessage(e) ??
          'Không thể kết nối máy chủ để đăng tin. Vui lòng kiểm tra mạng và thử lại.';
      debugPrint('[ApiRecruiterRepository] Error posting job: ${e.message}');
      throw Exception(message);
    } catch (e) {
      debugPrint('[ApiRecruiterRepository] Unexpected error posting job: $e');
      rethrow;
    }
  }

  String? _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      return _extractErrorMessageFromData(e.response!.data);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Hết thời gian kết nối tới máy chủ.',
      DioExceptionType.sendTimeout => 'Hết thời gian gửi dữ liệu tới máy chủ.',
      DioExceptionType.receiveTimeout =>
        'Hết thời gian chờ phản hồi từ máy chủ.',
      DioExceptionType.connectionError =>
        'Không thể kết nối tới máy chủ (Gateway offline).',
      _ => null,
    };
  }

  String? _extractErrorMessageFromData(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['title']?.toString() ??
          data['detail']?.toString();
    }
    return null;
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

  /// Maps a UI job status to a job-svc `JobStatus` (Pending, Active, Closed,
  /// Rejected, Deleted). Returns null when job-svc has no equivalent.
  String? _mapJobStatusToBackend(String uiStatus) {
    switch (uiStatus.trim().toLowerCase()) {
      case 'đang mở':
        return 'Active';
      case 'chờ duyệt':
        // job-svc "Pending": awaiting admin approval.
        return 'Pending';
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
        return 'FullTime';
      case 'bán thời gian':
        return 'PartTime';
      case 'thực tập':
        return 'Internship';
    }
    throw Exception('Hình thức làm việc không hợp lệ: $type');
  }

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
