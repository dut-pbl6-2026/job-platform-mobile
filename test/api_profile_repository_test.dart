import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/api_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  group('ApiProfileRepository Tests', () {
    test('Can instantiate ApiProfileRepository', () {
      final repo = ApiProfileRepository();
      expect(repo, isNotNull);
    });

    test('Falls back gracefully to mock when Gateway is offline', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Connection refused',
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final repo = ApiProfileRepository(dio: dio);

      final profile = await repo.getMyProfile();
      expect(profile, isNotNull);
      expect(profile.fullName.isNotEmpty, isTrue);

      final newSkill = await repo.addSkill(
        const SkillModel(
          id: 'skill-new',
          name: 'GraphQL',
          proficiency: 4,
          yearsOfExperience: 2,
        ),
      );
      expect(newSkill.name, equals('GraphQL'));
    });

    test('Throws exception on HTTP error with response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Unauthorized'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      final repo = ApiProfileRepository(dio: dio);

      expect(() => repo.getMyProfile(), throwsA(isA<Exception>()));
    });
  });
}
