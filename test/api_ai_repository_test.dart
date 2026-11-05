import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/ai_copilot/data/api_ai_repository.dart';
import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';

void main() {
  Dio gateway(
    void Function(RequestOptions, RequestInterceptorHandler) callback,
  ) {
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.example.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: callback));
    addTearDown(() => dio.close(force: true));
    return dio;
  }

  test(
    'AI-01 sends documented JSON to Gateway and preserves session',
    () async {
      final dio = gateway((options, handler) {
        expect(options.path, '/api/ai/chat');
        expect(options.uri.host, 'gateway.example.test');
        expect(options.data, {
          'message': 'Tìm việc',
          'sessionId': 'existing',
          'stream': false,
          'maxTokens': 512,
        });
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'response': 'Kết quả thật', 'sessionId': 'existing'},
          ),
        );
      });
      final reply = await ApiAiRepository(
        dio: dio,
      ).sendMessage(' Tìm việc ', sessionId: 'existing');
      expect(reply.response, 'Kết quả thật');
      expect(reply.sessionId, 'existing');
    },
  );

  test('AI-01 rejects empty message without sending a request', () async {
    final repo = ApiAiRepository(
      dio: gateway((_, _) => fail('Unexpected request')),
    );
    await expectLater(repo.sendMessage('  '), throwsA(isA<AiFailure>()));
  });

  for (final status in [401, 403, 404, 429, 503]) {
    test('AI-01 maps $status without fake success', () async {
      final dio = gateway(
        (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: status),
          ),
        ),
      );
      await expectLater(
        ApiAiRepository(dio: dio).sendMessage('Tìm việc'),
        throwsA(
          isA<AiFailure>().having(
            (f) => f.message,
            'Vietnamese message',
            isNotEmpty,
          ),
        ),
      );
    });
  }

  test('AI-01 malformed response never becomes an assistant message', () async {
    final dio = gateway(
      (options, handler) => handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'response': '', 'sessionId': 's'},
        ),
      ),
    );
    await expectLater(
      ApiAiRepository(dio: dio).sendMessage('Tìm việc'),
      throwsA(isA<AiFailure>()),
    );
  });

  test(
    'SCORE-01 uploads actual bytes with documented multipart keys',
    () async {
      final dio = gateway((options, handler) {
        expect(options.path, '/api/ai/score-resume');
        final form = options.data as FormData;
        expect(form.fields.single.key, 'job_id');
        expect(form.fields.single.value, 'actual-job');
        expect(form.files.single.key, 'cv_file');
        expect(form.files.single.value.filename, 'cv.pdf');
        expect(form.files.single.value.length, 3);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'overall_score': 78,
              'breakdown': {
                'skills': {
                  'matching': ['Dart'],
                  'missing': ['Docker'],
                  'score': 85,
                },
              },
              'suggestions': ['Mô tả dự án Flutter'],
            },
          ),
        );
      });
      final result = await ApiAiRepository(dio: dio).scoreResume(
        AiCvInput(
          name: 'cv.pdf',
          size: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        jobId: 'actual-job',
      );
      expect(result.score, 78);
      expect(result.matchingSkills, ['Dart']);
      expect(result.missingSkills, ['Docker']);
      expect(() => result.matchingSkills.add('Fake'), throwsUnsupportedError);
    },
  );

  test('SCORE-01 rejects invalid files, empty job, invalid score', () async {
    final repo = ApiAiRepository(
      dio: gateway((_, _) => fail('Unexpected request')),
    );
    for (final file in [
      const AiCvInput(name: 'cv.exe', size: 3),
      const AiCvInput(name: 'cv.pdf', size: 6 * 1024 * 1024),
      const AiCvInput(name: 'cv.pdf', size: 0),
    ]) {
      await expectLater(
        repo.scoreResume(file, jobId: 'job'),
        throwsA(isA<AiFailure>()),
      );
    }
    await expectLater(
      repo.scoreResume(const AiCvInput(name: 'cv.pdf', size: 3), jobId: ''),
      throwsA(isA<AiFailure>()),
    );
    for (final score in [-1, 101, '82', double.nan]) {
      expect(
        () => ApiAiRepository.parseFeedback({'score': score}),
        throwsA(isA<AiFailure>()),
      );
    }
  });

  test('SCORE-01 parses response table schema too', () {
    final result = ApiAiRepository.parseFeedback({
      'score': 79.5,
      'skills': {
        'matching': ['React'],
        'missing': [],
      },
      'suggestions': [],
    });
    expect(result.score, 79.5);
    expect(result.matchingSkills, ['React']);
  });
}
