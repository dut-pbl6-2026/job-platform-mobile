import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/models/recruiter_models.dart';
import '../../domain/repositories/recruiter_repository.dart';
import 'mock_recruiter_repository.dart';

/// Remote API implementation of [IRecruiterRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1).
/// Direct microservice port access is prohibited.
class ApiRecruiterRepository implements IRecruiterRepository {
  final Dio _dio;
  final MockRecruiterRepository _fallbackMock = MockRecruiterRepository();
  bool _isMock = false;

  ApiRecruiterRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: DioProvider.instance.dio.options.baseUrl,
              connectTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  @override
  bool get isMock => _isMock;

  @override
  Future<List<CandidateApplication>> getCandidateApplications({
    String? jobId,
    String? status,
  }) async {
    try {
      if (jobId != null && jobId.isNotEmpty) {
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
      }
    } on DioException catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Gateway candidate applications offline: ${e.message}, falling back to mock.',
      );
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Unexpected error fetching candidate applications: $e',
      );
    }

    _isMock = true;
    return _fallbackMock.getCandidateApplications(jobId: jobId, status: status);
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
    } on DioException catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Gateway status update offline: ${e.message}, updating in mock.',
      );
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Unexpected error updating status: $e',
      );
    }

    _isMock = true;
    return _fallbackMock.updateCandidateStatus(applicationId, newStatus);
  }

  @override
  Future<List<RecruiterJob>> getMyJobs({String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty)
          'status': _mapJobStatusToBackend(status),
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
        '[ApiRecruiterRepository] Gateway recruiter jobs offline: ${e.message}, falling back to mock.',
      );
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Unexpected error fetching recruiter jobs: $e',
      );
    }

    _isMock = true;
    return _fallbackMock.getMyJobs(status: status);
  }

  @override
  Future<RecruiterStats> getDashboardStats() async {
    try {
      final jobs = await getMyJobs();
      if (!_isMock) {
        final active = jobs.where((j) => j.status == 'Đang mở').length;
        final totalApps = jobs.fold<int>(
          0,
          (sum, j) => sum + j.applicationsCount,
        );
        final totalViews = jobs.fold<int>(0, (sum, j) => sum + j.viewsCount);
        return RecruiterStats(
          activeJobsCount: active,
          newApplicationsCount: totalApps,
          viewsCount: totalViews,
          interviewsCount: (totalApps * 0.2).round(),
        );
      }
    } catch (e) {
      debugPrint(
        '[ApiRecruiterRepository] Error calculating dashboard stats: $e',
      );
    }

    _isMock = true;
    return _fallbackMock.getDashboardStats();
  }

  @override
  Future<String> postJob(PostJobParams params) async {
    try {
      // Obtain default company if companyId is missing
      String companyId = params.companyId ?? '';
      if (companyId.isEmpty) {
        try {
          final compRes = await _dio.get('/api/companies');
          if (compRes.statusCode == 200 && compRes.data != null) {
            final compData = compRes.data;
            final List items = compData is Map
                ? (compData['items'] as List? ?? [])
                : (compData as List);
            if (items.isNotEmpty) {
              companyId = items.first['id']?.toString() ?? '';
            }
          }
        } catch (_) {
          // ignore company list failure and proceed with fallback GUID
        }
        if (companyId.isEmpty) {
          companyId = '00000000-0000-0000-0000-000000000001';
        }
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
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        final message = data is Map
            ? (data['message'] ?? data['title'] ?? data['detail'])
            : null;
        if (message != null) {
          throw Exception(message.toString());
        }
      }
      debugPrint(
        '[ApiRecruiterRepository] Gateway post job offline: ${e.message}, submitting to mock.',
      );
    } catch (e) {
      if (e is Exception && !e.toString().contains('DioException')) {
        rethrow;
      }
      debugPrint('[ApiRecruiterRepository] Unexpected error posting job: $e');
    }

    _isMock = true;
    return _fallbackMock.postJob(params);
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

  String _mapJobStatusToBackend(String uiStatus) {
    switch (uiStatus.trim().toLowerCase()) {
      case 'đang mở':
        return 'Active';
      case 'chờ duyệt':
        return 'Draft';
      case 'đã đóng':
        return 'Closed';
      default:
        return uiStatus;
    }
  }

  String _mapEmploymentTypeToBackend(String type) {
    switch (type.trim().toLowerCase()) {
      case 'toàn thời gian':
        return 'FullTime';
      case 'bán thời gian':
        return 'PartTime';
      case 'thực tập':
        return 'Internship';
      case 'từ xa':
        return 'Remote';
      default:
        return 'FullTime';
    }
  }

  String _mapExperienceLevelToBackend(String level) {
    switch (level.trim().toLowerCase()) {
      case 'intern':
        return 'Intern';
      case 'junior':
        return 'Entry';
      case 'middle':
        return 'Mid';
      case 'senior':
        return 'Senior';
      default:
        return 'Entry';
    }
  }
}
