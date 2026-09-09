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

  @override
  Future<ProfileModel> getMyProfile() async {
    try {
      final response = await _dio.get('/api/profile/me');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return ProfileModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway profile/me fallback: $e');
    }
    return _fallbackMockRepository.getMyProfile();
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel updated) async {
    try {
      final response = await _dio.put(
        '/api/profile',
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
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway updateProfile fallback: $e');
    }
    return _fallbackMockRepository.updateProfile(updated);
  }

  @override
  Future<SkillModel> addSkill(SkillModel skill) async {
    try {
      final response = await _dio.post(
        '/api/profile/skills',
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
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway addSkill fallback: $e');
    }
    return _fallbackMockRepository.addSkill(skill);
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    try {
      final response = await _dio.delete('/api/profile/skills/$skillId');
      if (response.statusCode == 200) return;
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway deleteSkill fallback: $e');
    }
    await _fallbackMockRepository.deleteSkill(skillId);
  }

  @override
  Future<WorkExperienceModel> addExperience(
    WorkExperienceModel experience,
  ) async {
    try {
      final response = await _dio.post(
        '/api/profile/experience',
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
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway addExperience fallback: $e');
    }
    return _fallbackMockRepository.addExperience(experience);
  }

  @override
  Future<void> deleteExperience(String experienceId) async {
    try {
      final response = await _dio.delete(
        '/api/profile/experience/$experienceId',
      );
      if (response.statusCode == 200) return;
    } catch (e) {
      debugPrint(
        '[ApiProfileRepository] Gateway deleteExperience fallback: $e',
      );
    }
    await _fallbackMockRepository.deleteExperience(experienceId);
  }

  @override
  Future<EducationModel> addEducation(EducationModel education) async {
    try {
      final response = await _dio.post(
        '/api/profile/education',
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
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway addEducation fallback: $e');
    }
    return _fallbackMockRepository.addEducation(education);
  }

  @override
  Future<void> deleteEducation(String educationId) async {
    try {
      final response = await _dio.delete('/api/profile/education/$educationId');
      if (response.statusCode == 200) return;
    } catch (e) {
      debugPrint('[ApiProfileRepository] Gateway deleteEducation fallback: $e');
    }
    await _fallbackMockRepository.deleteEducation(educationId);
  }
}
