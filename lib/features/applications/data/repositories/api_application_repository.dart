import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../jobs/data/repositories/api_job_repository.dart';
import '../../../jobs/domain/models/job_model.dart';
import '../../../jobs/domain/repositories/job_repository.dart';
import '../../domain/models/application_model.dart';
import '../../domain/repositories/application_repository.dart';
import 'mock_application_repository.dart';

/// Remote API implementation of [IApplicationRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
///
/// Mock data is gated behind `--dart-define=ENABLE_MOCKS=true` (`kEnableMocks`) so
/// release builds never fabricate application records when offline (Audit C2).
class ApiApplicationRepository implements IApplicationRepository {
  final Dio _dio;
  final IJobRepository _jobRepository;
  final MockApplicationRepository _fallbackMockRepository =
      MockApplicationRepository();
  final bool _enableMocks;
  final Map<String, JobModel> _jobLookupCache = {};

  ApiApplicationRepository({
    Dio? dio,
    IJobRepository? jobRepository,
    bool? enableMockFallback,
  }) : _dio = dio ?? DioProvider.instance.dio,
       _jobRepository =
           jobRepository ??
           ApiJobRepository(dio: dio ?? DioProvider.instance.dio),
       _enableMocks = enableMockFallback ?? kEnableMocks;

  static const Duration _cvUploadTimeout = Duration(seconds: 45);

  @override
  Future<ApplicationModel> applyJob(ApplyJobParams params) async {
    try {
      final formData = FormData.fromMap({
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
        onSendProgress: params.onUploadProgress,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: _cvUploadTimeout,
          receiveTimeout: _cvUploadTimeout,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return ApplicationModel.fromCreatedJson(data, params: params);
      }
      throw const ApplicationRepositoryException(
        'Không thể gửi hồ sơ ứng tuyển lúc này. Vui lòng thử lại.',
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw const ApplicationRepositoryException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
        );
      }
      final code = response.statusCode;
      if (code == 409) {
        throw const ApplicationRepositoryException(
          'Bạn đã nộp hồ sơ cho vị trí này rồi. Vui lòng kiểm tra lịch sử ứng tuyển.',
        );
      }
      if (code == 413) {
        throw const ApplicationRepositoryException(
          'File CV vượt quá dung lượng tối đa 5MB.',
        );
      }
      if (code == 400 || code == 422) {
        throw const ApplicationRepositoryException(
          'Thông tin hoặc định dạng file CV chưa hợp lệ (hỗ trợ PDF, DOC, DOCX tối đa 5MB).',
        );
      }
      if (code == 429) {
        throw const ApplicationRepositoryException(
          'Bạn đã gửi yêu cầu quá nhanh. Vui lòng thử lại sau ít phút.',
        );
      }
      throw const ApplicationRepositoryException(
        'Hệ thống tạm thời gián đoạn khi gửi hồ sơ. Vui lòng thử lại sau.',
      );
    }
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({
    ApplicationStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        // The API pages are 1-based; the repository interface is 0-based.
        'page': page + 1,
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
        if (data is Map && data.containsKey('items') && data['items'] is List) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        }
        final rawApps = items
            .whereType<Map>()
            .map(
              (item) => ApplicationModel.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        // Deduplicate missing job lookups to avoid N+1 waterfall (BUG-16)
        final missingJobIds = rawApps
            .where(
              (app) =>
                  (app.jobTitle == 'Vị trí tuyển dụng' ||
                      app.companyName == 'Doanh nghiệp') &&
                  app.jobId.isNotEmpty &&
                  !_jobLookupCache.containsKey(app.jobId),
            )
            .map((app) => app.jobId)
            .toSet();

        if (missingJobIds.isNotEmpty) {
          await Future.wait(
            missingJobIds.map((jobId) async {
              try {
                final job = await _jobRepository.getJobById(jobId);
                if (job != null) {
                  _jobLookupCache[jobId] = job;
                }
              } catch (_) {}
            }),
          );
        }

        return rawApps.map((app) {
          final cachedJob = _jobLookupCache[app.jobId];
          if (cachedJob != null &&
              (app.jobTitle == 'Vị trí tuyển dụng' ||
                  app.companyName == 'Doanh nghiệp')) {
            return app.copyWith(
              jobTitle: cachedJob.title,
              companyName: cachedJob.companyName,
              companyLogo: cachedJob.companyLogo,
            );
          }
          return app;
        }).toList();
      }
      throw const ApplicationRepositoryException(
        'Không thể tải lịch sử ứng tuyển. Vui lòng thử lại.',
      );
    } on DioException catch (e) {
      if (shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        if (kDebugMode) {
          debugPrint(
            '[ApiApplicationRepository] Gateway applications/me unavailable, using mock fallback.',
          );
        }
        return _fallbackMockRepository.getMyApplications(
          status: status,
          page: page,
          size: size,
        );
      }
      if (e.response == null) {
        throw const ApplicationRepositoryException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
        );
      }
      throw const ApplicationRepositoryException(
        'Không thể tải lịch sử ứng tuyển lúc này. Vui lòng thử lại sau.',
      );
    } on ApplicationRepositoryException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiApplicationRepository] Unexpected parse error: $e');
      }
      throw const ApplicationRepositoryException(
        'Dữ liệu lịch sử ứng tuyển không hợp lệ. Vui lòng thử lại.',
      );
    }
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
          var job = _jobLookupCache[app.jobId];
          if (job == null && app.jobId.isNotEmpty) {
            try {
              job = await _jobRepository.getJobById(app.jobId);
              if (job != null) {
                _jobLookupCache[app.jobId] = job;
              }
            } catch (_) {}
          }
          if (job != null) {
            app = app.copyWith(
              jobTitle: job.title,
              companyName: job.companyName,
              companyLogo: job.companyLogo,
            );
          }
        }
        return app;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      if (shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        return _fallbackMockRepository.getApplicationById(id);
      }
      if (e.response == null) {
        throw const ApplicationRepositoryException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
        );
      }
      throw const ApplicationRepositoryException(
        'Không thể tải chi tiết đơn ứng tuyển lúc này. Vui lòng thử lại sau.',
      );
    } on ApplicationRepositoryException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiApplicationRepository] Unexpected detail error: $e');
      }
      throw const ApplicationRepositoryException(
        'Không thể đọc dữ liệu đơn ứng tuyển. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<bool> hasApplied(String jobId) async {
    try {
      final applications = await getMyApplications();
      return applications.any((app) => app.jobId == jobId);
    } catch (_) {
      if (_enableMocks) {
        return _fallbackMockRepository.hasApplied(jobId);
      }
      return false;
    }
  }
}

/// Clean user-facing exception for application operations (never exposes raw Dio/ProblemDetails).
class ApplicationRepositoryException implements Exception {
  final String message;
  const ApplicationRepositoryException(this.message);

  @override
  String toString() => message;
}
