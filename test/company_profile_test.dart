import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/constants/company_profile_strings.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/company/data/repositories/api_company_profile_repository.dart';
import 'package:job_platform_mobile/features/company/data/repositories/mock_company_profile_repository.dart';
import 'package:job_platform_mobile/features/company/domain/models/company_profile.dart';
import 'package:job_platform_mobile/features/company/domain/repositories/company_profile_repository.dart';
import 'package:job_platform_mobile/features/company/presentation/company_profile_screen.dart';

const _companyJson = {
  'id': 'company-1',
  'name': 'FPT Software',
  'taxCode': '0101248141',
  'verified': true,
  'logoUrl': 'https://example.test/logo.png',
  'website': 'https://fptsoftware.com',
  'description': 'Công ty công nghệ',
  'address': 'Hà Nội',
  'industry': 'Công nghệ thông tin',
  'size': '1000+ nhân viên',
  'isCompanyAdmin': true,
};

Dio _dio(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://gateway.example.test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: handler));
  return dio;
}

void main() {
  group('CompanyProfile model', () {
    test('parses the backend contract and company admin flag', () {
      final company = CompanyProfile.fromJson(_companyJson);

      expect(company.id, 'company-1');
      expect(company.name, 'FPT Software');
      expect(company.verified, isTrue);
      expect(company.isCompanyAdmin, isTrue);
      expect(company.isUsable, isTrue);
    });

    test('enforces camelCase keys and fails usability without name', () {
      final company = CompanyProfile.fromJson({
        'id': 'company-2',
        'name': ' ',
        'tax_code': '999999',
        'logo_url': 'https://example.test/snake.png',
        'is_company_admin': 'true',
      });

      expect(company.taxCode, isNull);
      expect(company.logoUrl, isNull);
      expect(company.isCompanyAdmin, isFalse);
      expect(company.isUsable, isFalse);
    });

    test('PUT body uses the backend field names and keeps name required', () {
      final company = CompanyProfile.fromJson({
        ..._companyJson,
        'website': '',
        'description': null,
      });
      final body = company.toApiJson();

      expect(body['name'], 'FPT Software');
      expect(body['taxCode'], '0101248141');
      expect(body['logoUrl'], 'https://example.test/logo.png');
      expect(body['website'], isNull);
      expect(body['description'], isNull);
      expect(body['address'], 'Hà Nội');
      expect(body['industry'], 'Công nghệ thông tin');
      expect(body['size'], '1000+ nhân viên');
      expect(body.containsKey('verified'), isFalse);
      expect(body.containsKey('isCompanyAdmin'), isFalse);
    });
  });

  group('ApiCompanyProfileRepository', () {
    test('GET /api/companies/mine returns the company', () async {
      final repo = ApiCompanyProfileRepository(
        dio: _dio((options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/api/companies/mine');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: _companyJson,
            ),
          );
        }),
      );

      final company = await repo.getMyCompany();
      expect(company.name, 'FPT Software');
    });

    test(
      'a response missing the required name fails with retry copy',
      () async {
        final repo = ApiCompanyProfileRepository(
          dio: _dio((options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'id': 'company-1'},
              ),
            );
          }),
        );

        await expectLater(
          repo.getMyCompany(),
          throwsA(
            isA<CompanyProfileException>().having(
              (e) => e.message,
              'message',
              CompanyProfileStrings.loadFailed,
            ),
          ),
        );
      },
    );

    test('a 403 does not invent a company', () async {
      final repo = ApiCompanyProfileRepository(
        dio: _dio((options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 403),
            ),
          );
        }),
      );

      await expectLater(
        repo.getMyCompany(),
        throwsA(isA<CompanyProfileException>()),
      );
    });

    test(
      'PUT /api/companies/{id} sends only editable contract fields',
      () async {
        final company = CompanyProfile.fromJson(_companyJson);
        late Map<String, dynamic> body;
        final repo = ApiCompanyProfileRepository(
          dio: _dio((options, handler) {
            expect(options.method, 'PUT');
            expect(options.path, '/api/companies/company-1');
            body = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {..._companyJson, 'name': 'FPT Software mới'},
              ),
            );
          }),
        );

        final updated = await repo.updateCompany(
          company.copyWith(name: 'FPT Software mới'),
        );

        expect(body['name'], 'FPT Software mới');
        expect(body.containsKey('verified'), isFalse);
        expect(body.containsKey('isCompanyAdmin'), isFalse);
        expect(updated.name, 'FPT Software mới');
      },
    );

    test(
      'PUT answers only a message: the company is read back, not reported as failed',
      () async {
        final company = CompanyProfile.fromJson(_companyJson);
        final calls = <String>[];
        final repo = ApiCompanyProfileRepository(
          dio: _dio((options, handler) {
            calls.add('${options.method} ${options.path}');
            if (options.method == 'PUT') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'Company updated successfully'},
                ),
              );
              return;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {..._companyJson, 'name': 'FPT Software mới'},
              ),
            );
          }),
        );

        final updated = await repo.updateCompany(
          company.copyWith(name: 'FPT Software mới'),
        );

        expect(calls, [
          'PUT /api/companies/company-1',
          'GET /api/companies/mine',
        ]);
        expect(updated.name, 'FPT Software mới');
      },
    );
  });

  group('CompanyProfileScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      MockCompanyProfileRepository repo,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CompanyProfileScreen(repository: repo),
        ),
      );
    }

    testWidgets('shows loading then the read-only company for an admin', (
      tester,
    ) async {
      final repo = MockCompanyProfileRepository(
        delay: const Duration(milliseconds: 50),
      );
      await pumpScreen(tester, repo);

      expect(find.byKey(const Key('company_profile_loading')), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('FPT Software'), findsOneWidget);
      expect(find.text('Đã xác minh'), findsOneWidget);
      expect(find.text('0101248141'), findsOneWidget);
      expect(find.byKey(const Key('company_profile_edit')), findsOneWidget);
    });

    testWidgets('admin edits and saves company details', (tester) async {
      final repo = MockCompanyProfileRepository();
      await pumpScreen(tester, repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('company_profile_edit')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('company_profile_name_field')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('company_profile_name_field')),
        'FPT Software mới',
      );
      await tester.tap(find.byKey(const Key('company_profile_save')));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, 1);
      expect(repo.company.name, 'FPT Software mới');
      expect(find.text('FPT Software mới'), findsOneWidget);
      expect(find.text(CompanyProfileStrings.saved), findsOneWidget);
    });

    testWidgets('member sees read-only reason and a disabled edit control', (
      tester,
    ) async {
      final repo = MockCompanyProfileRepository(
        company: MockCompanyProfileRepository().company.copyWith(
          isCompanyAdmin: false,
        ),
      );
      await pumpScreen(tester, repo);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('company_profile_member_notice')),
        findsOneWidget,
      );
      expect(find.text(CompanyProfileStrings.adminOnlyReason), findsWidgets);

      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('company_profile_edit_disabled')),
      );
      expect(button.onPressed, isNull);
      expect(find.byKey(const Key('company_profile_edit')), findsNothing);
    });

    testWidgets('a failed load shows retry and recovers', (tester) async {
      final repo = MockCompanyProfileRepository(failLoad: true);
      await pumpScreen(tester, repo);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('company_profile_error')), findsOneWidget);
      expect(find.text(CompanyProfileStrings.loadFailed), findsOneWidget);

      repo.failLoad = false;
      await tester.tap(find.byKey(const Key('company_profile_retry')));
      await tester.pumpAndSettle();

      expect(find.text('FPT Software'), findsOneWidget);
    });

    testWidgets('missing required fields fail gracefully instead of spinning', (
      tester,
    ) async {
      final repo = MockCompanyProfileRepository(
        company: const CompanyProfile(
          id: 'company-1',
          name: '',
          isCompanyAdmin: true,
        ),
      );
      await pumpScreen(tester, repo);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('company_profile_loading')), findsNothing);
      expect(find.byKey(const Key('company_profile_error')), findsOneWidget);
      expect(find.byKey(const Key('company_profile_retry')), findsOneWidget);
    });
  });
}
