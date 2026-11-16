import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/session/auth_session.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import 'mock_profile_repository.dart';

/// Remote API implementation of [IProfileRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
///
/// Reads may answer with mock data only when the build enables it
/// (`--dart-define=ENABLE_MOCKS=true`) and the gateway was unreachable or
/// answered 5xx. Writes never fall back: reporting "saved" for a request that
/// never reached the server loses the user's edit silently.
class ApiProfileRepository implements IProfileRepository {
  final Dio _dio;
  final MockProfileRepository _fallbackMockRepository = MockProfileRepository();
  final bool _enableMocks;

  ApiProfileRepository({Dio? dio, bool? enableMockFallback})
    : _dio = dio ?? DioProvider.instance.dio,
      _enableMocks = enableMockFallback ?? kEnableMocks;

  /// A user-facing Vietnamese message. The server's ProblemDetails body and any
  /// Dart exception string stay out of it.
  Exception _failure(String message) => Exception(message);

  @override
  Future<ProfileModel> getMyProfile() async {
    try {
      final response = await _dio.get('/api/profiles/me');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return ProfileModel.fromJson(data);
      }
      throw _failure('Không thể tải thông tin hồ sơ cá nhân');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ProfileNotFoundException();
      }
      if (shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        debugPrint(
          '[ApiProfileRepository] Gateway profile/me unavailable, using mock data.',
        );
        return _fallbackMockRepository.getMyProfile();
      }
      debugPrint('[ApiProfileRepository] profile/me failed: ${e.type}');
      throw _failure('Không thể tải thông tin hồ sơ cá nhân');
    }
  }

  @override
  Future<ProfileModel> getOrCreateProfile() async {
    try {
      return await getMyProfile();
    } on ProfileNotFoundException {
      debugPrint('[ApiProfileRepository] profile/me not found, creating it.');
      return createProfile();
    }
  }

  @override
  Future<ProfileModel> createProfile() async {
    final user = AuthSession.instance.currentUser;
    try {
      final response = await _dio.post(
        '/api/profiles',
        data: {
          'fullName': user?.name ?? '',
          if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
            'avatarUrl': user.avatarUrl,
        },
      );

      final status = response.statusCode;
      if ((status == 200 || status == 201) && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return ProfileModel.fromJson(data);
      }
      throw _failure('Không thể tạo hồ sơ cá nhân');
    } on DioException catch (e) {
      debugPrint(
        '[ApiProfileRepository] createProfile failed: '
        '${e.response?.statusCode ?? e.type}',
      );
      throw _failure('Không thể tạo hồ sơ cá nhân');
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel updated) async {
    try {
      final response = await _dio.put(
        '/api/profiles/me',
        data: {
          'fullName': updated.fullName,
          'phone': updated.phone,
          'address': updated.address,
          'headline': updated.headline,
          'summary': updated.summary,
          'dateOfBirth': updated.dateOfBirth?.toIso8601String(),
          'avatarUrl': updated.avatarUrl,
        },
      );

      if (response.statusCode == 200) {
        return updated;
      }
      throw _failure('Không thể cập nhật hồ sơ cá nhân');
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] updateProfile failed: ${e.type}');
      throw _failure('Không thể cập nhật hồ sơ cá nhân');
    }
  }

  @override
  Future<SkillModel> addSkill(SkillModel skill) async {
    try {
      final response = await _dio.post(
        '/api/profiles/skills',
        data: {
          'name': skill.name,
          'proficiency': skill.proficiency,
          'yearsOfExperience': skill.yearsOfExperience,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map && response.data['id'] != null) {
          return skill.copyWith(id: response.data['id'].toString());
        }
        return skill;
      }
      throw _failure('Không thể thêm kỹ năng mới');
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] addSkill failed: ${e.type}');
      throw _failure('Không thể thêm kỹ năng mới');
    }
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    try {
      final response = await _dio.delete('/api/profiles/skills/$skillId');
      if (response.statusCode != 200) {
        throw _failure('Không thể xóa kỹ năng');
      }
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] deleteSkill failed: ${e.type}');
      throw _failure('Không thể xóa kỹ năng');
    }
  }

  @override
  Future<WorkExperienceModel> addExperience(
    WorkExperienceModel experience,
  ) async {
    try {
      final response = await _dio.post(
        '/api/profiles/experiences',
        data: {
          'company': experience.company,
          'title': experience.title,
          'startDate': experience.startDate.toIso8601String(),
          'endDate': experience.endDate?.toIso8601String(),
          'isCurrent': experience.isCurrent,
          'description': experience.description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map && response.data['id'] != null) {
          return experience.copyWith(id: response.data['id'].toString());
        }
        return experience;
      }
      throw _failure('Không thể thêm kinh nghiệm làm việc');
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] addExperience failed: ${e.type}');
      throw _failure('Không thể thêm kinh nghiệm làm việc');
    }
  }

  @override
  Future<void> deleteExperience(String experienceId) async {
    try {
      final response = await _dio.delete(
        '/api/profiles/experiences/$experienceId',
      );
      if (response.statusCode != 200) {
        throw _failure('Không thể xóa kinh nghiệm làm việc');
      }
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] deleteExperience failed: ${e.type}');
      throw _failure('Không thể xóa kinh nghiệm làm việc');
    }
  }

  @override
  Future<EducationModel> addEducation(EducationModel education) async {
    try {
      final response = await _dio.post(
        '/api/profiles/educations',
        data: {
          'institution': education.institution,
          'degree': education.degree,
          'field': education.field,
          'startDate': education.startDate.toIso8601String(),
          'endDate': education.endDate?.toIso8601String(),
          'grade': education.grade,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map && response.data['id'] != null) {
          return education.copyWith(id: response.data['id'].toString());
        }
        return education;
      }
      throw _failure('Không thể thêm thông tin học vấn');
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] addEducation failed: ${e.type}');
      throw _failure('Không thể thêm thông tin học vấn');
    }
  }

  @override
  Future<void> deleteEducation(String educationId) async {
    try {
      final response = await _dio.delete(
        '/api/profiles/educations/$educationId',
      );
      if (response.statusCode != 200) {
        throw _failure('Không thể xóa thông tin học vấn');
      }
    } on DioException catch (e) {
      debugPrint('[ApiProfileRepository] deleteEducation failed: ${e.type}');
      throw _failure('Không thể xóa thông tin học vấn');
    }
  }
}
