class TraceEntry {
  final String agent;
  final String startedAt;
  final int durationMs;
  final String inputSummary;
  final String reasoning;
  final String outputSummary;

  TraceEntry({
    required this.agent,
    required this.startedAt,
    required this.durationMs,
    required this.inputSummary,
    required this.reasoning,
    required this.outputSummary,
  });

  factory TraceEntry.fromJson(Map<String, dynamic> json) {
    return TraceEntry(
      agent: json['agent'] ?? 'Unknown Agent',
      startedAt: json['started_at'] ?? '',
      durationMs: json['duration_ms'] ?? 0,
      inputSummary: json['input_summary'] ?? '',
      reasoning: json['reasoning'] ?? '',
      outputSummary: json['output_summary'] ?? '',
    );
  }

  String get durationLabel {
    if (durationMs < 1000) return '${durationMs}ms';
    return '${(durationMs / 1000).toStringAsFixed(1)}s';
  }
}

class TraceLog {
  final String traceId;
  final String createdAt;
  final String? userMessage;
  final List<TraceEntry> entries;

  TraceLog({
    required this.traceId,
    required this.createdAt,
    this.userMessage,
    required this.entries,
  });

  factory TraceLog.fromJson(Map<String, dynamic> json) {
    return TraceLog(
      traceId: json['trace_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      userMessage: json['user_message'],
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => TraceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalDurationMs =>
      entries.fold(0, (sum, e) => sum + e.durationMs);

  String get totalDurationLabel {
    final ms = totalDurationMs;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
}
