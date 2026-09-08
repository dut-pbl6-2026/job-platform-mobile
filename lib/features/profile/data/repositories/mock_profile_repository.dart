import 'dart:async';
import '../../../../core/session/auth_session.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

/// In-memory mock implementation of [IProfileRepository]
/// Seeded with rich Vietnamese candidate profile data (PROFILE-01, MOB-01-05)
class MockProfileRepository implements IProfileRepository {
  // Singleton instance to share profile changes across screens in current session
  static final MockProfileRepository _instance = MockProfileRepository._internal();
  factory MockProfileRepository() => _instance;
  MockProfileRepository._internal() {
    _initSeedProfile();
  }

  late ProfileModel _profile;

  void _initSeedProfile() {
    final currentUser = AuthSession.instance.currentUser;
    final now = DateTime.now();

    _profile = ProfileModel(
      id: 'prof-001',
      userId: currentUser?.id ?? 'user-001',
      fullName: currentUser?.name.isNotEmpty == true
          ? currentUser!.name
          : 'Nguyễn Văn An',
      phone: '0905 123 456',
      address: 'Hải Châu, Đà Nẵng, Việt Nam',
      headline: 'Senior Flutter & Cross-Platform Mobile Engineer',
      summary:
          'Kỹ sư phần mềm với hơn 4 năm kinh nghiệm chuyên sâu phát triển ứng dụng di động cho cả iOS và Android bằng Flutter & Dart. Đam mê thiết kế Clean Architecture, tối ưu hóa 60fps UI rendering và quản lý trạng thái hiệu năng cao (Riverpod / BLoC).',
      dateOfBirth: DateTime(1998, 5, 15),
      avatarUrl: null,
      skills: [
        const SkillModel(
          id: 'sk-1',
          name: 'Flutter & Dart',
          proficiency: 5,
          yearsOfExperience: 4,
        ),
        const SkillModel(
          id: 'sk-2',
          name: 'Clean Architecture & Riverpod',
          proficiency: 5,
          yearsOfExperience: 3,
        ),
        const SkillModel(
          id: 'sk-3',
          name: 'RESTful APIs & YARP Gateway',
          proficiency: 4,
          yearsOfExperience: 4,
        ),
        const SkillModel(
          id: 'sk-4',
          name: 'Git, CI/CD & Fastlane',
          proficiency: 4,
          yearsOfExperience: 3,
        ),
        const SkillModel(
          id: 'sk-5',
          name: 'Unit & Widget Testing',
          proficiency: 4,
          yearsOfExperience: 3,
        ),
      ],
      experiences: [
        WorkExperienceModel(
          id: 'exp-1',
          company: 'FPT Software',
          title: 'Senior Flutter Developer',
          startDate: DateTime(2022, 1, 1),
          endDate: null,
          isCurrent: true,
          description:
              'Phụ trách kiến trúc ứng dụng di động cho khách hàng quốc tế. Tối ưu hóa hiệu năng, giảm thiểu crash rate xuống dưới 0.1% và hướng dẫn các thành viên junior trong team.',
        ),
        WorkExperienceModel(
          id: 'exp-2',
          company: 'VNG Corporation',
          title: 'Mobile Engineer',
          startDate: DateTime(2020, 6, 1),
          endDate: DateTime(2021, 12, 31),
          isCurrent: false,
          description:
              'Tham gia phát triển tính năng ví điện tử và thanh toán QR. Tích hợp native SDKs trên cả iOS và Android.',
        ),
      ],
      educations: [
        EducationModel(
          id: 'edu-1',
          institution: 'Đại học Bách Khoa - Đại học Đà Nẵng',
          degree: 'Kỹ sư',
          field: 'Công nghệ Thông tin',
          startDate: DateTime(2016, 9, 1),
          endDate: DateTime(2020, 6, 30),
          grade: 'Tốt nghiệp loại Giỏi (GPA 3.4/4.0)',
        ),
      ],
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }

  @override
  Future<ProfileModel> getMyProfile() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _profile;
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = updated.copyWith(updatedAt: DateTime.now());
    return _profile;
  }

  @override
  Future<SkillModel> addSkill(SkillModel skill) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newSkill = skill.id.isEmpty
        ? skill.copyWith(id: 'sk-${DateTime.now().millisecondsSinceEpoch}')
        : skill;

    final updatedSkills = List<SkillModel>.from(_profile.skills)..add(newSkill);
    _profile = _profile.copyWith(
      skills: updatedSkills,
      updatedAt: DateTime.now(),
    );
    return newSkill;
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final updatedSkills = _profile.skills.where((s) => s.id != skillId).toList();
    _profile = _profile.copyWith(
      skills: updatedSkills,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<WorkExperienceModel> addExperience(WorkExperienceModel experience) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final newExp = experience.id.isEmpty
        ? experience.copyWith(id: 'exp-${DateTime.now().millisecondsSinceEpoch}')
        : experience;

    final updatedExperiences = List<WorkExperienceModel>.from(_profile.experiences)
      ..insert(0, newExp);
    _profile = _profile.copyWith(
      experiences: updatedExperiences,
      updatedAt: DateTime.now(),
    );
    return newExp;
  }

  @override
  Future<void> deleteExperience(String experienceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final updatedExperiences =
        _profile.experiences.where((e) => e.id != experienceId).toList();
    _profile = _profile.copyWith(
      experiences: updatedExperiences,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<EducationModel> addEducation(EducationModel education) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final newEdu = education.id.isEmpty
        ? education.copyWith(id: 'edu-${DateTime.now().millisecondsSinceEpoch}')
        : education;

    final updatedEducations = List<EducationModel>.from(_profile.educations)
      ..insert(0, newEdu);
    _profile = _profile.copyWith(
      educations: updatedEducations,
      updatedAt: DateTime.now(),
    );
    return newEdu;
  }

  @override
  Future<void> deleteEducation(String educationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final updatedEducations =
        _profile.educations.where((e) => e.id != educationId).toList();
    _profile = _profile.copyWith(
      educations: updatedEducations,
      updatedAt: DateTime.now(),
    );
  }

  /// Helper for unit tests to reset data
  void reset() {
    _initSeedProfile();
  }
}
