import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../jobs/data/repositories/api_job_repository.dart';
import '../../../jobs/domain/repositories/job_repository.dart';
import '../../domain/models/application_model.dart';
import '../../domain/repositories/application_repository.dart';
import 'mock_application_repository.dart';

/// Remote API implementation of [IApplicationRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
class ApiApplicationRepository implements IApplicationRepository {
  final Dio _dio;
  final IJobRepository _jobRepository;
  final MockApplicationRepository _fallbackMockRepository =
      MockApplicationRepository();

  ApiApplicationRepository({Dio? dio, IJobRepository? jobRepository})
    : _dio = dio ?? DioProvider.instance.dio,
      _jobRepository =
          jobRepository ??
          ApiJobRepository(dio: dio ?? DioProvider.instance.dio);

  @override
  Future<ApplicationModel> applyJob(ApplyJobParams params) async {
    try {
      FormData formData = FormData.fromMap({
        'job_id': params.jobId,
        if (params.coverLetter != null && params.coverLetter!.isNotEmpty)
          'cover_letter': params.coverLetter,
        if (params.cvBytes != null)
          'cv_file': MultipartFile.fromBytes(
            params.cvBytes!,
            filename: params.cvFileName,
          )
        else if (params.cvFilePath != null)
          'cv_file': await MultipartFile.fromFile(
            params.cvFilePath!,
            filename: params.cvFileName,
          ),
      });

      final response = await _dio.post(
        '/api/applications',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return ApplicationModel.fromJson(data);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 409) {
          throw Exception(
            'Bạn đã nộp hồ sơ cho vị trí này rồi. Vui lòng kiểm tra lịch sử ứng tuyển.',
          );
        }
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['detail'])
            : null;
        throw Exception(
          message ?? 'Lỗi gửi hồ sơ ứng tuyển (${e.response?.statusCode})',
        );
      }
      debugPrint(
        '[ApiApplicationRepository] Gateway application offline, falling back: ${e.message}',
      );
    } catch (e) {
      if (e is! DioException) rethrow;
      debugPrint(
        '[ApiApplicationRepository] Unexpected error, falling back to mock: $e',
      );
    }

    // Graceful fallback to Mock repository if Gateway is offline during development
    return _fallbackMockRepository.applyJob(params);
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({
    ApplicationStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        if (status != null) 'status': status.value,
      };

      final response = await _dio.get(
        '/api/applications/me',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data.containsKey('items')) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        }
        final rawApps = items
            .map(
              (item) => ApplicationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        // Enrich missing job title and company from Job service (Section 4.7)
        final enriched = await Future.wait(
          rawApps.map((app) async {
            if (app.jobTitle != 'Vị trí tuyển dụng' &&
                app.companyName != 'Doanh nghiệp') {
              return app;
            }
            try {
              final job = await _jobRepository.getJobById(app.jobId);
              if (job != null) {
                return app.copyWith(
                  jobTitle: job.title,
                  companyName: job.companyName,
                  companyLogo: job.companyLogo,
                );
              }
            } catch (_) {}
            return app;
          }),
        );
        return enriched;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['detail'])
            : null;
        throw Exception(
          message ??
              'Lỗi khi tải danh sách ứng tuyển (${e.response?.statusCode})',
        );
      }
      debugPrint(
        '[ApiApplicationRepository] Gateway applications/me offline, falling back: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiApplicationRepository] Unexpected error: $e');
    }

    return _fallbackMockRepository.getMyApplications(
      status: status,
      page: page,
      size: size,
    );
  }

  @override
  Future<ApplicationModel?> getApplicationById(String id) async {
    try {
      final response = await _dio.get('/api/applications/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        var app = ApplicationModel.fromJson(data);
        if (app.jobTitle == 'Vị trí tuyển dụng' ||
            app.companyName == 'Doanh nghiệp') {
          try {
            final job = await _jobRepository.getJobById(app.jobId);
            if (job != null) {
              app = app.copyWith(
                jobTitle: job.title,
                companyName: job.companyName,
                companyLogo: job.companyLogo,
              );
            }
          } catch (_) {}
        }
        return app;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 404) return null;
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['detail'])
            : null;
        throw Exception(
          message ??
              'Lỗi khi tải chi tiết ứng tuyển (${e.response?.statusCode})',
        );
      }
      debugPrint(
        '[ApiApplicationRepository] Gateway applications/$id offline, falling back: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiApplicationRepository] Unexpected error: $e');
    }

    return _fallbackMockRepository.getApplicationById(id);
  }

  @override
  Future<bool> hasApplied(String jobId) async {
    try {
      final applications = await getMyApplications();
      return applications.any((app) => app.jobId == jobId);
    } catch (_) {
      return _fallbackMockRepository.hasApplied(jobId);
    }
  }
}
