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

  @override
  Future<ResumeFeedback> scoreResume(
    AiCvInput cv, {
    required String jobId,
  }) async {
    final extension = cv.name.split('.').last.toLowerCase();
    if (!['pdf', 'docx'].contains(extension)) {
      throw const AiFailure('Chấm CV hỗ trợ file PDF hoặc DOCX.');
    }
    if (cv.size <= 0 ||
        cv.size > 5 * 1024 * 1024 ||
        (cv.bytes != null && cv.bytes!.length != cv.size)) {
      throw const AiFailure(
        'CV phải có dung lượng lớn hơn 0 và không quá 5 MB.',
      );
    }
    if (jobId.trim().isEmpty) {
      throw const AiFailure('Vui lòng chọn việc làm để đối chiếu CV.');
    }
    final token = CancelToken();
    _cancelToken = token;
    try {
      final MultipartFile file;
      if (cv.bytes != null) {
        file = MultipartFile.fromBytes(cv.bytes!, filename: cv.name);
      } else if (cv.path != null) {
        file = await MultipartFile.fromFile(cv.path!, filename: cv.name);
      } else {
        throw const AiFailure('Không thể đọc file CV. Vui lòng chọn lại.');
      }
      final response = await _dio.post<dynamic>(
        '/api/ai/score-resume',
        data: FormData.fromMap({'cv_file': file, 'job_id': jobId.trim()}),
        cancelToken: token,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return parseFeedback(response.data);
    } on DioException catch (error) {
      throw _failure(error);
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure(
        'Không thể đọc CV hoặc kết quả chấm. Vui lòng thử lại.',
      );
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  /// Accept both the response table and the detailed SRS 5.3.4 example.
  static ResumeFeedback parseFeedback(dynamic data) {
    if (data is! Map) throw const AiFailure('Kết quả chấm CV không hợp lệ.');
    final score = data['overall_score'] ?? data['score'];
    if (score is! num || !score.isFinite || score < 0 || score > 100) {
      throw const AiFailure('Kết quả chấm CV không hợp lệ.');
    }
    final breakdown = data['breakdown'];
    final skills = breakdown is Map ? breakdown['skills'] : data['skills'];
    return ResumeFeedback(
      score: score.toDouble(),
      matchingSkills: _strings(skills is Map ? skills['matching'] : null),
      missingSkills: _strings(skills is Map ? skills['missing'] : null),
      suggestions: _strings(data['suggestions']),
    );
  }

  static List<String> _strings(dynamic value) {
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw const AiFailure('Kết quả chấm CV không hợp lệ.');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  AiFailure _failure(DioException error) {
    if (CancelToken.isCancel(error)) {
      return const AiFailure('Đã dừng yêu cầu.', cancelled: true);
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
