import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  late MockProfileRepository repository;

  setUp(() {
    repository = MockProfileRepository();
    repository.reset();
  });

  group('MockProfileRepository Tests', () {
    test(
      'getMyProfile returns seeded candidate profile (PROFILE-01-05)',
      () async {
        final profile = await repository.getMyProfile();
        expect(profile.fullName.isNotEmpty, true);
        expect(profile.headline, isNotNull);
        expect(profile.skills.isNotEmpty, true);
        expect(profile.experiences.isNotEmpty, true);
        expect(profile.educations.isNotEmpty, true);
      },
    );

    test(
      'updateProfile modifies personal information (PROFILE-01-01)',
      () async {
        final initial = await repository.getMyProfile();
        final updated = initial.copyWith(
          fullName: 'Trần Văn Bảo',
          headline: 'Staff Mobile Architect',
          phone: '0987 654 321',
        );

        final saved = await repository.updateProfile(updated);
        expect(saved.fullName, 'Trần Văn Bảo');
        expect(saved.headline, 'Staff Mobile Architect');
        expect(saved.phone, '0987 654 321');

        final fresh = await repository.getMyProfile();
        expect(fresh.fullName, 'Trần Văn Bảo');
      },
    );

    test(
      'addSkill and deleteSkill manipulate skills collection (PROFILE-01-02)',
      () async {
        final newSkill = const SkillModel(
          id: 'sk-new-99',
          name: 'Golang & Microservices',
          proficiency: 4,
          yearsOfExperience: 2,
        );

        await repository.addSkill(newSkill);
        var profile = await repository.getMyProfile();
        expect(
          profile.skills.any((s) => s.name == 'Golang & Microservices'),
          true,
        );

        // Delete the skill
        await repository.deleteSkill('sk-new-99');
        profile = await repository.getMyProfile();
        expect(profile.skills.any((s) => s.id == 'sk-new-99'), false);
      },
    );

    test(
      'addExperience and deleteExperience manipulate work experiences (PROFILE-01-03)',
      () async {
        final newExp = WorkExperienceModel(
          id: 'exp-new-99',
          company: 'Shopee Vietnam',
          title: 'Lead Engineer',
          startDate: DateTime(2024, 1, 1),
          isCurrent: true,
        );

        await repository.addExperience(newExp);
        var profile = await repository.getMyProfile();
        expect(
          profile.experiences.any((e) => e.company == 'Shopee Vietnam'),
          true,
        );

        await repository.deleteExperience('exp-new-99');
        profile = await repository.getMyProfile();
        expect(profile.experiences.any((e) => e.id == 'exp-new-99'), false);
      },
    );

    test(
      'addEducation and deleteEducation manipulate education history (PROFILE-01-04)',
      () async {
        final newEdu = EducationModel(
          id: 'edu-new-99',
          institution: 'Đại học Quốc tế RMIT',
          degree: 'Thạc sĩ',
          field: 'Software Engineering',
          startDate: DateTime(2021, 9, 1),
          endDate: DateTime(2023, 6, 30),
        );

        await repository.addEducation(newEdu);
        var profile = await repository.getMyProfile();
        expect(
          profile.educations.any(
            (e) => e.institution == 'Đại học Quốc tế RMIT',
          ),
          true,
        );

        await repository.deleteEducation('edu-new-99');
        profile = await repository.getMyProfile();
        expect(profile.educations.any((e) => e.id == 'edu-new-99'), false);
      },
    );
  });
}
