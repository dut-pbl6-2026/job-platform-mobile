import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';

void main() {
  group('JobFilterParams Skills Tests (SEARCH-01)', () {
    test('default JobFilterParams has empty skills and 0 active filters', () {
      const params = JobFilterParams();
      expect(params.skills, isEmpty);
      expect(params.hasActiveFilters, isFalse);
      expect(params.activeFilterCount, 0);
    });

    test(
      'adding skills increases activeFilterCount and sets hasActiveFilters',
      () {
        const params = JobFilterParams(skills: ['Flutter', 'Dart']);
        expect(params.skills, equals(['Flutter', 'Dart']));
        expect(params.hasActiveFilters, isTrue);
        expect(params.activeFilterCount, 1);
      },
    );

    test('copyWith can update or clear skills', () {
      const params = JobFilterParams(skills: ['Flutter']);
      final updated = params.copyWith(skills: ['React', 'TypeScript']);
      expect(updated.skills, equals(['React', 'TypeScript']));

      final cleared = updated.copyWith(clearSkills: true);
      expect(cleared.skills, isEmpty);
    });

    test('clearAllFilters resets skills list', () {
      const params = JobFilterParams(
        keyword: 'Dev',
        skills: ['Flutter', 'Bloc'],
        location: 'Hà Nội',
      );
      final reset = params.clearAllFilters();
      expect(reset.skills, isEmpty);
      expect(reset.keyword, isNull);
      expect(reset.location, isNull);
      expect(reset.hasActiveFilters, isFalse);
    });
  });

  group('MockJobRepository Skills Filtering Tests (SEARCH-01)', () {
    late MockJobRepository repository;

    setUp(() {
      repository = MockJobRepository();
    });

    test('filters jobs matching selected single skill', () async {
      final result = await repository.getJobs(
        const JobFilterParams(skills: ['Flutter']),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        final hasSkill = job.skills.any(
          (s) => s.toLowerCase().contains('flutter'),
        );
        expect(hasSkill, isTrue);
      }
    });

    test('filters jobs matching multiple skills (case-insensitive)', () async {
      final result = await repository.getJobs(
        const JobFilterParams(skills: ['react', 'TYPESCRIPT']),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        final matchesAny = job.skills.any(
          (s) =>
              s.toLowerCase().contains('react') ||
              s.toLowerCase().contains('typescript'),
        );
        expect(matchesAny, isTrue);
      }
    });

    test('returns empty or filtered list when skill has no matches', () async {
      final result = await repository.getJobs(
        const JobFilterParams(skills: ['NonExistentSkillXYZ123']),
      );
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });
  });
}
