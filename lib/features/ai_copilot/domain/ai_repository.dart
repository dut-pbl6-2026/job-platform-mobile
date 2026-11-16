final class AiChatReply {
  const AiChatReply({required this.response, required this.sessionId});
  final String response;
  final String sessionId;

  AiChatReply copyWith({String? response, String? sessionId}) => AiChatReply(
    response: response ?? this.response,
    sessionId: sessionId ?? this.sessionId,
  );
}

final class AiChatChunk {
  const AiChatChunk({required this.delta, this.sessionId, this.done = false});
  final String delta;
  final String? sessionId;
  final bool done;

  AiChatChunk copyWith({String? delta, String? sessionId, bool? done}) =>
      AiChatChunk(
        delta: delta ?? this.delta,
        sessionId: sessionId ?? this.sessionId,
        done: done ?? this.done,
      );
}

final class AiFailure implements Exception {
  const AiFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// Gateway contracts from SRS 5.2.3 (AI-01).
abstract interface class IAiRepository {
  Future<AiChatReply> sendMessage(String message, {String? sessionId});
  Stream<AiChatChunk> streamChat(String message, {String? sessionId});
  Future<void> clearSession(String sessionId);
  void cancelCurrentRequest();
}
