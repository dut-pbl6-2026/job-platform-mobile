import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  group('SkillModel Tests', () {
    test('SkillModel serialization and copyWith work properly', () {
      const skill = SkillModel(
        id: 'sk-1',
        name: 'Flutter & Dart',
        proficiency: 5,
        yearsOfExperience: 4,
      );

      final json = skill.toJson();
      expect(json['name'], 'Flutter & Dart');
      expect(json['proficiency'], 5);

      final deserialized = SkillModel.fromJson(json);
      expect(deserialized.id, 'sk-1');
      expect(deserialized.yearsOfExperience, 4);

      final updated = skill.copyWith(proficiency: 4);
      expect(updated.proficiency, 4);
      expect(updated.name, skill.name);
    });
  });

  group('WorkExperienceModel Tests', () {
    test('formattedPeriod handles current vs past jobs correctly', () {
      final currentJob = WorkExperienceModel(
        id: 'exp-1',
        company: 'FPT Software',
        title: 'Senior Developer',
        startDate: DateTime(2022, 1, 1),
        isCurrent: true,
      );
      expect(currentJob.formattedPeriod, '01/2022 - Hiện tại');

      final pastJob = WorkExperienceModel(
        id: 'exp-2',
        company: 'VNG',
        title: 'Junior Developer',
        startDate: DateTime(2020, 6, 1),
        endDate: DateTime(2021, 12, 31),
        isCurrent: false,
      );
      expect(pastJob.formattedPeriod, '06/2020 - 12/2021');
    });

    test('Serialization to/from JSON preserves all fields', () {
      final exp = WorkExperienceModel(
        id: 'exp-1',
        company: 'Viettel',
        title: 'Tech Lead',
        startDate: DateTime(2023, 3, 1),
        isCurrent: true,
        description: 'Quản lý 5 engineers',
      );

      final json = exp.toJson();
      final fromJson = WorkExperienceModel.fromJson(json);
      expect(fromJson.company, 'Viettel');
      expect(fromJson.title, 'Tech Lead');
      expect(fromJson.isCurrent, true);
      expect(fromJson.description, 'Quản lý 5 engineers');
    });
  });

  group('EducationModel Tests', () {
    test('formattedPeriod renders correct years span', () {
      final edu = EducationModel(
        id: 'edu-1',
        institution: 'ĐHBK Đà Nẵng',
        degree: 'Kỹ sư',
        field: 'CNTT',
        startDate: DateTime(2016, 9, 1),
        endDate: DateTime(2020, 6, 30),
        grade: 'Giỏi',
      );
      expect(edu.formattedPeriod, '2016 - 2020');
    });
  });

  group('ProfileModel Tests', () {
    test('completionPercentage calculates profile score appropriately', () {
      final now = DateTime.now();
      // Bare profile
      final emptyProfile = ProfileModel(
        id: 'p-0',
        userId: 'u-0',
        fullName: '',
        createdAt: now,
        updatedAt: now,
      );
      expect(emptyProfile.completionPercentage, 0);

      // Full profile
      final fullProfile = ProfileModel(
        id: 'p-1',
        userId: 'u-1',
        fullName: 'Nguyễn Văn An',
        phone: '0905 123 456',
        address: 'Đà Nẵng',
        headline: 'Flutter Engineer',
        summary: 'Mô tả bản thân...',
        skills: const [SkillModel(id: 's-1', name: 'Flutter')],
        experiences: [
          WorkExperienceModel(
            id: 'e-1',
            company: 'FPT',
            title: 'Dev',
            startDate: DateTime(2022, 1, 1),
          ),
        ],
        educations: [
          EducationModel(
            id: 'ed-1',
            institution: 'DUT',
            degree: 'Kỹ sư',
            field: 'IT',
            startDate: DateTime(2016, 1, 1),
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(fullProfile.completionPercentage, 100);
    });

    test('Profile models enforce camelCase and ignore snake_case fields', () {
      final skill = SkillModel.fromJson({
        'id': 's-1',
        'name': 'Dart',
        'years_of_experience': 5,
      });
      expect(skill.yearsOfExperience, 1);

      final exp = WorkExperienceModel.fromJson({
        'id': 'e-1',
        'company': 'Acme',
        'title': 'Dev',
        'start_date': '2020-01-01T00:00:00Z',
        'end_date': '2022-01-01T00:00:00Z',
        'is_current': true,
      });
      expect(exp.endDate, isNull);
      expect(exp.isCurrent, isFalse);

      final profile = ProfileModel.fromJson({
        'id': 'p-1',
        'user_id': 'u-snake',
        'full_name': 'Snake Name',
        'avatar_url': 'https://example.com/snake.png',
        'date_of_birth': '1999-05-05',
        'work_experiences': const <dynamic>[],
        'education_history': const <dynamic>[],
      });
      expect(profile.userId, isEmpty);
      expect(profile.fullName, isEmpty);
      expect(profile.avatarUrl, isNull);
      expect(profile.dateOfBirth, isNull);
    });
  });
}
