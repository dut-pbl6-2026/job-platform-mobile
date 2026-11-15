import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/hive_cache_service.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';
import '../../domain/models/recommended_job_model.dart';
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
      // search-svc takes employmentType / experienceLevel with canonical
      // backend values. Options without a backend value are not sent at all.
      final employmentType = params.jobType?.backendValue;
      if (employmentType != null) {
        queryParams['employmentType'] = employmentType;
      }
      final experienceLevel = params.experienceLevel?.backendValue;
      if (experienceLevel != null) {
        queryParams['experienceLevel'] = experienceLevel;
      }
      if (params.skills.isNotEmpty) {
        queryParams['skills'] = params.skills.join(',');
      }
      // search-svc has no parameter for specialization, workplaceType, country,
      // region, salaryRange, currency or includeNegotiable, so those filters are
      // not sent. They stay in the UI state until the backend supports them.
      if (params.salaryMin != null) {
        queryParams['minSalary'] = params.salaryMin.toString();
      }
      if (params.salaryMax != null) {
        queryParams['maxSalary'] = params.salaryMax.toString();
      }
      // search-svc accepts created_at_desc/asc and salary_desc/asc. Mobile's
      // 'newest' and 'relevance' have no exact match, so they are omitted and
      // search-svc applies its default ordering.
      if (params.sortBy == 'salary_desc') {
        queryParams['sortBy'] = 'salary_desc';
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

  @override
  Future<List<RecommendedJob>> getRecommendedJobs({
    int limit = 10,
    bool refresh = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/jobs/recommended',
        queryParameters: {
          'limit': limit.toString(),
          if (refresh) 'refresh': 'true',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;

        final Map<String, dynamic> data;
        if (raw is Map<String, dynamic>) {
          data = raw;
        } else if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        } else if (raw is List) {
          return raw
              .map(
                (item) => RecommendedJob.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        } else {
          data = {};
        }

        final targetData =
            (data['data'] is Map
                ? data['data'] as Map<String, dynamic>
                : null) ??
            data;

        final itemsList =
            targetData['items'] as List<dynamic>? ??
            targetData['jobs'] as List<dynamic>? ??
            [];

        final reasonsMapRaw = targetData['reasons'];
        final Map<String, String> reasonsMap = {};
        if (reasonsMapRaw is Map) {
          for (final entry in reasonsMapRaw.entries) {
            reasonsMap[entry.key.toString()] = entry.value.toString();
          }
        }

        final List<RecommendedJob> recommendedJobs = [];
        for (var i = 0; i < itemsList.length; i++) {
          final item = itemsList[i];
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final jobId =
                map['id']?.toString() ??
                (map['job'] is Map
                    ? (map['job'] as Map)['id']?.toString()
                    : null) ??
                '';
            final reasonFromMap = reasonsMap[jobId];
            recommendedJobs.add(
              RecommendedJob.fromJson(map, defaultReason: reasonFromMap),
            );
          }
        }

        if (recommendedJobs.isNotEmpty) {
          return recommendedJobs;
        }
      }
    } catch (e) {
      debugPrint('[ApiJobRepository] Gateway getRecommendedJobs fallback: $e');
    }

    // Graceful fallback: check local Hive cache first to preserve real UUID jobs
    final cached = await HiveCacheService.instance.getCachedJobs();
    if (cached.isNotEmpty) {
      return cached.take(limit).map((job) {
        return RecommendedJob(
          job: job,
          reason: 'Phù hợp với kỹ năng và vị trí đã lưu của bạn',
          matchType: 'content',
        );
      }).toList();
    }

    // Otherwise fallback to Mock repository (cold start or offline Gateway)
    return _fallbackMockRepository.getRecommendedJobs(
      limit: limit,
      refresh: refresh,
    );
  }
}
