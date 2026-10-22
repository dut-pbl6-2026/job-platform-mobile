import 'dart:typed_data';

final class AiChatReply {
  const AiChatReply({required this.response, required this.sessionId});
  final String response;
  final String sessionId;

  AiChatReply copyWith({String? response, String? sessionId}) => AiChatReply(
    response: response ?? this.response,
    sessionId: sessionId ?? this.sessionId,
  );
}

final class ResumeFeedback {
  const ResumeFeedback({
    required this.score,
    this.matchingSkills = const [],
    this.missingSkills = const [],
    this.suggestions = const [],
  });
  final double score;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final List<String> suggestions;

  ResumeFeedback copyWith({
    double? score,
    List<String>? matchingSkills,
    List<String>? missingSkills,
    List<String>? suggestions,
  }) => ResumeFeedback(
    score: score ?? this.score,
    matchingSkills: List.unmodifiable(matchingSkills ?? this.matchingSkills),
    missingSkills: List.unmodifiable(missingSkills ?? this.missingSkills),
    suggestions: List.unmodifiable(suggestions ?? this.suggestions),
  );
}

final class AiCvInput {
  const AiCvInput({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
  });
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;
}

final class AiFailure implements Exception {
  const AiFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// Gateway contracts from SRS 5.2.3 and 5.3.3 (AI-01, SCORE-01).
abstract interface class IAiRepository {
  Future<AiChatReply> sendMessage(String message, {String? sessionId});
  Future<ResumeFeedback> scoreResume(AiCvInput cv, {required String jobId});
  void cancelCurrentRequest();
}
