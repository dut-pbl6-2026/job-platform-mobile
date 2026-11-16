import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/ai_repository.dart';

/// No mock fallback: unavailable AI never produces invented answers or scores.
class ApiAiRepository implements IAiRepository {
  ApiAiRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;
  final Dio _dio;
  CancelToken? _cancelToken;

  @override
  void cancelCurrentRequest() => _cancelToken?.cancel();

  @override
  Stream<AiChatChunk> streamChat(String message, {String? sessionId}) async* {
    if (message.trim().isEmpty) {
      throw const AiFailure('Vui lòng nhập câu hỏi.');
    }
    final token = CancelToken();
    _cancelToken = token;
    try {
      final response = await _dio.post<dynamic>(
        '/api/ai/chat',
        data: {
          'message': message.trim(),
          'sessionId': ?sessionId,
          'stream': true,
          'maxTokens': 512,
        },
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Accept': 'text/event-stream, application/json'},
        ),
      );

      final data = response.data;
      String? currentSessionId = sessionId;
      var emittedDone = false;

      if (data is ResponseBody) {
        final lineStream = data.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lineStream) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) {
            continue;
          }

          if (trimmed.startsWith('data:')) {
            var raw = line.startsWith('data:')
                ? line.substring(5)
                : trimmed.substring(5);
            if (raw.startsWith(' ')) {
              raw = raw.substring(1);
            }
            if (raw.trim() == '[DONE]') {
              yield AiChatChunk(
                delta: '',
                sessionId: currentSessionId,
                done: true,
              );
              return;
            }

            try {
              final decoded = jsonDecode(raw.trim());
              if (decoded is Map) {
                final delta =
                    decoded['delta'] as String? ??
                    decoded['text'] as String? ??
                    decoded['response'] as String? ??
                    '';
                final sid = decoded['sessionId'] as String?;
                if (sid != null && sid.isNotEmpty) {
                  currentSessionId = sid;
                }
                final isDone = decoded['done'] == true;
                if (isDone) emittedDone = true;
                if (delta.isNotEmpty || isDone) {
                  yield AiChatChunk(
                    delta: delta,
                    sessionId: currentSessionId,
                    done: isDone,
                  );
                }
              } else if (decoded is String) {
                yield AiChatChunk(delta: decoded, sessionId: currentSessionId);
              }
            } catch (_) {
              yield AiChatChunk(delta: raw, sessionId: currentSessionId);
            }
          } else {
            try {
              final decoded = jsonDecode(trimmed);
              if (decoded is Map) {
                final delta =
                    decoded['delta'] as String? ??
                    decoded['response'] as String? ??
                    decoded['text'] as String? ??
                    '';
                final sid = decoded['sessionId'] as String?;
                if (sid != null && sid.isNotEmpty) {
                  currentSessionId = sid;
                }
                final isDone = decoded['done'] == true;
                if (isDone) emittedDone = true;
                if (delta.isNotEmpty || isDone) {
                  yield AiChatChunk(
                    delta: delta,
                    sessionId: currentSessionId,
                    done: isDone,
                  );
                }
              }
            } catch (_) {
              // Ignore unparsed non-JSON lines
            }
          }
        }
      } else if (data is Map) {
        final responseText =
            data['response'] as String? ?? data['delta'] as String? ?? '';
        final sid = data['sessionId'] as String?;
        if (sid != null && sid.isNotEmpty) {
          currentSessionId = sid;
        }
        yield AiChatChunk(
          delta: responseText,
          sessionId: currentSessionId,
          done: true,
        );
        emittedDone = true;
      } else if (data is String) {
        yield AiChatChunk(delta: data, sessionId: currentSessionId, done: true);
        emittedDone = true;
      }

      if (!emittedDone) {
        yield AiChatChunk(delta: '', sessionId: currentSessionId, done: true);
      }
    } on DioException catch (error) {
      throw _failure(error);
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  @override
  Future<void> clearSession(String sessionId) async {
    final cleanId = sessionId.trim();
    if (cleanId.isEmpty) return;
    try {
      await _dio.delete<dynamic>(
        '/api/ai/session/${Uri.encodeComponent(cleanId)}',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return;
      }
      throw _failure(error);
    }
  }

  @override
  Future<AiChatReply> sendMessage(String message, {String? sessionId}) async {
    if (message.trim().isEmpty) {
      throw const AiFailure('Vui lòng nhập câu hỏi.');
    }
    final token = CancelToken();
    _cancelToken = token;
    try {
      final response = await _dio.post<dynamic>(
        '/api/ai/chat',
        data: {
          'message': message.trim(),
          'sessionId': ?sessionId,
          // SRS documents JSON; SSE event payloads are not specified yet.
          'stream': false,
          'maxTokens': 512,
        },
        cancelToken: token,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      final data = response.data;
      if (data is! Map ||
          data['response'] is! String ||
          (data['response'] as String).trim().isEmpty ||
          data['sessionId'] is! String ||
          (data['sessionId'] as String).isEmpty) {
        throw const AiFailure('Phản hồi AI không hợp lệ. Vui lòng thử lại.');
      }
      return AiChatReply(
        response: data['response'] as String,
        sessionId: data['sessionId'] as String,
      );
    } on DioException catch (error) {
      throw _failure(error);
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  AiFailure _failure(DioException error) {
    if (CancelToken.isCancel(error)) {
      return const AiFailure('Đã dừng yêu cầu.', cancelled: true);
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return const AiFailure(
        'Quá thời gian tải lên CV. Vui lòng kiểm tra kết nối mạng và thử lại.',
      );
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return const AiFailure(
        'Dịch vụ AI phản hồi quá lâu. Vui lòng thử lại sau.',
      );
    }
    final message = switch (error.response?.statusCode) {
      400 || 422 => 'Không thể xử lý yêu cầu. Kiểm tra câu hỏi hoặc file CV.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền truy cập.',
      404 => 'Không tìm thấy việc làm hoặc dịch vụ AI chưa được triển khai.',
      413 => 'File CV quá lớn. Vui lòng chọn file không quá 5 MB.',
      429 => 'Bạn đã đạt giới hạn sử dụng AI. Vui lòng thử lại sau.',
      500 ||
      502 ||
      503 ||
      504 => 'Dịch vụ AI đang không khả dụng. Vui lòng thử lại sau.',
      _ => 'Không thể kết nối dịch vụ AI. Vui lòng kiểm tra mạng và thử lại.',
    };
    return AiFailure(message);
  }
}
