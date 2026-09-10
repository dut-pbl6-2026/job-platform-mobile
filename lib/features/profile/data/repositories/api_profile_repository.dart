import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import 'mock_profile_repository.dart';

/// Remote API implementation of [IProfileRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
class ApiProfileRepository implements IProfileRepository {
  final Dio _dio;
  final MockProfileRepository _fallbackMockRepository = MockProfileRepository();

  ApiProfileRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;

  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['message'] ?? data['detail'])
          : null;
      return Exception(
        serverMsg ?? '$defaultMessage (${e.response?.statusCode})',
      );
    }
    return Exception('$defaultMessage: ${e.message}');
  }

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
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể tải thông tin hồ sơ cá nhân');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway profile/me offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    return _fallbackMockRepository.getMyProfile();
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
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể cập nhật hồ sơ cá nhân');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway updateProfile offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    return _fallbackMockRepository.updateProfile(updated);
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
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể thêm kỹ năng mới');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway addSkill offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    return _fallbackMockRepository.addSkill(skill);
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    try {
      final response = await _dio.delete('/api/profiles/skills/$skillId');
      if (response.statusCode == 200) return;
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể xóa kỹ năng');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway deleteSkill offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    await _fallbackMockRepository.deleteSkill(skillId);
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
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể thêm kinh nghiệm làm việc');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway addExperience offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    return _fallbackMockRepository.addExperience(experience);
  }

  @override
  Future<void> deleteExperience(String experienceId) async {
    try {
      final response = await _dio.delete(
        '/api/profiles/experiences/$experienceId',
      );
      if (response.statusCode == 200) return;
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể xóa kinh nghiệm làm việc');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway deleteExperience offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    await _fallbackMockRepository.deleteExperience(experienceId);
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
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể thêm thông tin học vấn');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway addEducation offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    return _fallbackMockRepository.addEducation(education);
  }

  @override
  Future<void> deleteEducation(String educationId) async {
    try {
      final response = await _dio.delete(
        '/api/profiles/educations/$educationId',
      );
      if (response.statusCode == 200) return;
    } on DioException catch (e) {
      if (e.response != null) {
        throw _handleError(e, 'Không thể xóa thông tin học vấn');
      }
      debugPrint(
        '[ApiProfileRepository] Gateway deleteEducation offline, falling back to mock: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApiProfileRepository] Unexpected error: $e');
    }
    await _fallbackMockRepository.deleteEducation(educationId);
  }
}
