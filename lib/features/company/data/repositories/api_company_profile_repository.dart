import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/company_profile_strings.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/company_profile.dart';
import '../../domain/repositories/company_profile_repository.dart';

/// Gateway-only implementation of [ICompanyProfileRepository].
///
/// Calls `/api/companies/mine` and `/api/companies/{id}` through YARP and never
/// invents a company. A response missing `id`/`name`, or an unreachable
/// gateway, surfaces as [CompanyProfileException] so the screen can show retry.
class ApiCompanyProfileRepository implements ICompanyProfileRepository {
  ApiCompanyProfileRepository({Dio? dio})
    : _dio = dio ?? DioProvider.instance.dio;

  final Dio _dio;

  @override
  Future<CompanyProfile> getMyCompany() async {
    try {
      final response = await _dio.get('/api/companies/mine');
      final company = _parseCompany(response.data);
      if (!company.isUsable) {
        throw const CompanyProfileException(CompanyProfileStrings.loadFailed);
      }
      return company;
    } on CompanyProfileException {
      rethrow;
    } on DioException catch (error) {
      debugPrint(
        '[ApiCompanyProfileRepository] companies/mine failed: '
        '${error.response?.statusCode ?? error.type}',
      );
      throw CompanyProfileException(_messageFor(error));
    } catch (error) {
      debugPrint('[ApiCompanyProfileRepository] malformed company: $error');
      throw const CompanyProfileException(CompanyProfileStrings.loadFailed);
    }
  }

  @override
  Future<CompanyProfile> updateCompany(CompanyProfile company) async {
    if (company.id.trim().isEmpty) {
      throw const CompanyProfileException(CompanyProfileStrings.saveFailed);
    }
    try {
      final response = await _dio.put(
        '/api/companies/${company.id.trim()}',
        data: company.toApiJson(),
      );
      if (response.statusCode == 204) return company;
      if (response.statusCode == 200) {
        if (response.data is Map) {
          final updated = _parseCompany(response.data);
          if (updated.isUsable) return updated;
        }
        // PUT only answers { message }; read the authoritative company back. A failed re-read
        // must not turn a successful save into an error.
        try {
          return await getMyCompany();
        } on CompanyProfileException {
          return company;
        }
      }
      throw const CompanyProfileException(CompanyProfileStrings.saveFailed);
    } on CompanyProfileException {
      rethrow;
    } on DioException catch (error) {
      debugPrint(
        '[ApiCompanyProfileRepository] update company failed: '
        '${error.response?.statusCode ?? error.type}',
      );
      throw CompanyProfileException(_saveMessageFor(error));
    } catch (error) {
      debugPrint('[ApiCompanyProfileRepository] malformed update: $error');
      throw const CompanyProfileException(CompanyProfileStrings.saveFailed);
    }
  }

  CompanyProfile _parseCompany(dynamic data) {
    if (data is Map) {
      return CompanyProfile.fromJson(Map<String, dynamic>.from(data));
    }
    throw const CompanyProfileException(CompanyProfileStrings.loadFailed);
  }

  String _messageFor(DioException error) {
    if (error.response == null) {
      return 'Lỗi kết nối mạng, vui lòng thử lại';
    }
    return switch (error.response!.statusCode) {
      403 => 'Bạn không có quyền xem thông tin công ty.',
      404 => 'Tài khoản của bạn chưa gắn với công ty.',
      503 => 'Dịch vụ công ty tạm thời không khả dụng. Vui lòng thử lại sau.',
      _ => CompanyProfileStrings.loadFailed,
    };
  }

  String _saveMessageFor(DioException error) {
    if (error.response == null) {
      return 'Lỗi kết nối mạng, vui lòng thử lại';
    }
    return switch (error.response!.statusCode) {
      403 => CompanyProfileStrings.adminOnlyReason,
      404 => 'Không tìm thấy công ty. Vui lòng tải lại.',
      422 || 400 => 'Thông tin công ty chưa hợp lệ. Vui lòng kiểm tra lại.',
      503 => 'Dịch vụ công ty tạm thời không khả dụng. Vui lòng thử lại sau.',
      _ => CompanyProfileStrings.saveFailed,
    };
  }
}
