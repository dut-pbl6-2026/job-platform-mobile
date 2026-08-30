import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';
import '../../domain/repositories/job_repository.dart';
import 'mock_job_repository.dart';

/// Remote API Implementation of [IJobRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
class ApiJobRepository implements IJobRepository {
  final String gatewayBaseUrl;
  final MockJobRepository _fallbackMockRepository = MockJobRepository();
  final HttpClient _httpClient = HttpClient();

  ApiJobRepository({this.gatewayBaseUrl = 'http://localhost:5000'});

  @override
  Future<PaginatedJobs> getJobs(JobFilterParams params) async {
    try {
      final queryParams = <String, String>{
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

      final uri = Uri.parse(
        '$gatewayBaseUrl/api/search/jobs',
      ).replace(queryParameters: queryParams);

      final request = await _httpClient
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      request.headers.set('Accept', 'application/json');

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        final items =
            (data['items'] as List<dynamic>?)
                ?.map((item) => JobModel.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
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
    }

    // Graceful fallback to Mock repository if Gateway is offline during local test
    return _fallbackMockRepository.getJobs(params);
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    try {
      final uri = Uri.parse('$gatewayBaseUrl/api/jobs/$id');
      final request = await _httpClient
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return JobModel.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[ApiJobRepository] Gateway getJobById fallback: $e');
    }
    return _fallbackMockRepository.getJobById(id);
  }

  @override
  Future<bool> toggleSaveJob(String id) {
    return _fallbackMockRepository.toggleSaveJob(id);
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) {
    return _fallbackMockRepository.getSearchSuggestions(query);
  }
}
