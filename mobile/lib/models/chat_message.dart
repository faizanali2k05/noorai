class ChatMessage {
  final String messageId;
  final String threadId;
  final String userId;
  final String therapistId;
  final String sender; // 'user' or 'therapist'
  final String kind;   // 'text' or 'voice'
  final String? text;
  final String? voiceUrl;
  final int? durationMs;
  final DateTime createdAt;

  ChatMessage({
    required this.messageId,
    required this.threadId,
    required this.userId,
    required this.therapistId,
    required this.sender,
    required this.kind,
    this.text,
    this.voiceUrl,
    this.durationMs,
    required this.createdAt,
  });

  bool get isMine => sender == 'user';
  bool get isVoice => kind == 'voice';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsed;
    try {
      parsed = DateTime.parse(json['created_at'] ?? '');
    } catch (_) {
      parsed = DateTime.now();
    }
    return ChatMessage(
      messageId: json['message_id'] ?? '',
      threadId: json['thread_id'] ?? '',
      userId: json['user_id'] ?? '',
      therapistId: json['therapist_id'] ?? '',
      sender: json['sender'] ?? 'user',
      kind: json['kind'] ?? 'text',
      text: json['text'],
      voiceUrl: json['voice_url'],
      durationMs: json['duration_ms'],
      createdAt: parsed,
    );
  }
}
