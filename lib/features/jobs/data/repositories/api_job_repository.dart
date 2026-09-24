import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/hive_cache_service.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';
import '../../domain/repositories/job_repository.dart';
import 'mock_job_repository.dart';

/// Remote API Implementation of [IJobRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
class ApiJobRepository implements IJobRepository {
  final Dio _dio;
  final MockJobRepository _fallbackMockRepository = MockJobRepository();

  ApiJobRepository({Dio? dio, String? gatewayBaseUrl})
    : _dio =
          dio ??
          (gatewayBaseUrl != null && gatewayBaseUrl.isNotEmpty
              ? Dio(
                  BaseOptions(
                    baseUrl: gatewayBaseUrl,
                    connectTimeout: const Duration(seconds: 5),
                    receiveTimeout: const Duration(seconds: 5),
                    headers: {'Accept': 'application/json'},
                  ),
                )
              : DioProvider.instance.dio);

  @override
  Future<PaginatedJobs> getJobs(JobFilterParams params) async {
    try {
      final queryParams = <String, dynamic>{
        'page': params.page.toString(),
        'size': params.pageSize.toString(),
      };

      if (params.keyword != null && params.keyword!.isNotEmpty) {
        queryParams['q'] = params.keyword!;
      }
      if (params.location != null && params.location!.isNotEmpty) {
        queryParams['location'] = params.location!;
      }
      if (params.category != null && params.category!.isNotEmpty) {
        queryParams['category'] = params.category!;
      }
      if (params.jobType != null) {
        queryParams['jobType'] = params.jobType!.value;
      }
      if (params.experienceLevel != null) {
        queryParams['experienceLevel'] = params.experienceLevel!.value;
      }
      if (params.skills.isNotEmpty) {
        queryParams['skills'] = params.skills.join(',');
      }
      if (params.specialization != null &&
          params.specialization!.trim().isNotEmpty) {
        queryParams['specialization'] = params.specialization;
      }
      if (params.workplaceType != null &&
          params.workplaceType!.trim().isNotEmpty) {
        queryParams['workplaceType'] = params.workplaceType;
      }
      if (params.country != null && params.country!.trim().isNotEmpty) {
        queryParams['country'] = params.country;
      }
      if (params.internationalRegion != null &&
          params.internationalRegion!.trim().isNotEmpty) {
        queryParams['region'] = params.internationalRegion;
      }
      if (params.salaryRangeId != null &&
          params.salaryRangeId!.trim().isNotEmpty) {
        queryParams['salaryRange'] = params.salaryRangeId;
      }
      if (params.currency.isNotEmpty) {
        queryParams['currency'] = params.currency;
      }
      if (params.salaryMin != null) {
        queryParams['minSalary'] = params.salaryMin.toString();
      }
      if (params.salaryMax != null) {
        queryParams['maxSalary'] = params.salaryMax.toString();
      }
      if (params.sortBy.isNotEmpty) {
        queryParams['sortBy'] = params.sortBy;
      }

      final response = await _dio.get(
        '/api/search/jobs',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          data = jsonDecode(response.data.toString()) as Map<String, dynamic>;
        }

        final items =
            (data['items'] as List<dynamic>?)
                ?.map(
                  (item) => JobModel.fromJson(
                    item is Map<String, dynamic>
                        ? item
                        : Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList() ??
            [];

        // Cache jobs in Hive for offline browsing (OFFLINE-01)
        if (items.isNotEmpty) {
          await HiveCacheService.instance.saveJobs(items);
        }

        return PaginatedJobs(
          items: items,
          total: data['total'] as int? ?? items.length,
          page: data['page'] as int? ?? params.page,
          size: data['size'] as int? ?? params.pageSize,
          totalPages: data['totalPages'] as int? ?? 1,
        );
      }
    } catch (e) {
      debugPrint('[ApiJobRepository] Gateway connection fallback: $e');

      // Check Hive local cache before mock fallback (OFFLINE-01)
      final cached = await HiveCacheService.instance.getCachedJobs();
      if (cached.isNotEmpty) {
        var filteredCached = List<JobModel>.from(cached);
        if (params.keyword != null && params.keyword!.trim().isNotEmpty) {
          final q = params.keyword!.trim().toLowerCase();
          filteredCached = filteredCached
              .where(
                (j) =>
                    j.title.toLowerCase().contains(q) ||
                    j.companyName.toLowerCase().contains(q) ||
                    j.skills.any((s) => s.toLowerCase().contains(q)),
              )
              .toList();
        }
        if (params.location != null &&
            params.location!.trim().isNotEmpty &&
            params.location != 'Tất cả') {
          final loc = params.location!.trim().toLowerCase();
          filteredCached = filteredCached
              .where((j) => j.location.toLowerCase().contains(loc))
              .toList();
        }
        if (params.skills.isNotEmpty) {
          final filterSkillsLower = params.skills
              .map((s) => s.toLowerCase())
              .toSet();
          filteredCached = filteredCached.where((j) {
            final jobSkillsLower = j.skills.map((s) => s.toLowerCase()).toSet();
            return filterSkillsLower.any((fs) => jobSkillsLower.contains(fs));
          }).toList();
        }
        if (params.onlySaved) {
          filteredCached = filteredCached.where((j) => j.isSaved).toList();
        }
        return PaginatedJobs(
          items: filteredCached,
          total: filteredCached.length,
          page: params.page,
          size: params.pageSize,
          totalPages: 1,
        );
      }
    }

    // Graceful fallback to Mock repository if Gateway is offline during local test
    return _fallbackMockRepository.getJobs(params);
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    try {
      final response = await _dio.get(
        '/api/jobs/$id',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          data = jsonDecode(response.data.toString()) as Map<String, dynamic>;
        }
        final job = JobModel.fromJson(data);
        await HiveCacheService.instance.saveJobDetail(job);
        return job;
      }
    } catch (e) {
      debugPrint('[ApiJobRepository] Gateway getJobById fallback: $e');
      final cached = await HiveCacheService.instance.getCachedJobDetail(id);
      if (cached != null) {
        return cached;
      }
    }
    return _fallbackMockRepository.getJobById(id);
  }

  @override
  Future<bool> toggleSaveJob(String id) {
    // TODO(PBL6): Connect to bookmark/saved job API once backend service endpoint is implemented.
    return _fallbackMockRepository.toggleSaveJob(id);
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    final q = query.trim();
    if (q.isEmpty) return _fallbackMockRepository.getSearchSuggestions(query);
    try {
      final response = await _dio.get(
        '/api/search/suggest',
        queryParameters: {'q': q, 'limit': '8'},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic decoded = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        // API returns a bare array; tolerate { items: [...] } envelope too.
        final List<dynamic>? items = decoded is List<dynamic>
            ? decoded
            : (decoded is Map ? decoded['items'] as List<dynamic>? : null);
        if (items != null) {
          return items.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiJobRepository] Gateway suggest fallback: $e');
    }
    return _fallbackMockRepository.getSearchSuggestions(query);
  }
}
