import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'therapist_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late Future<List<_ThreadSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ThreadSummary>> _load() async {
    final token = AuthService.instance.token;
    if (token == null) return [];
    try {
      final r = await http.get(
        Uri.parse('${ApiService.baseUrl}/chats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['threads'] as List<dynamic>? ?? [])
          .map((m) => _ThreadSummary.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    final fresh = _load();
    setState(() => _future = fresh);
    await fresh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: NoorColors.primary,
        child: FutureBuilder<List<_ThreadSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: NoorColors.primary),
              );
            }
            final items = snap.data ?? const <_ThreadSummary>[];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  _EmptyChats(),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey.shade100,
                height: 0,
                indent: 76,
              ),
              itemBuilder: (_, i) => _ThreadTile(
                thread: items[i],
                onOpen: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TherapistChatScreen(
                        therapistId: items[i].therapistId,
                        therapistName: 'Therapist ${items[i].therapistId}',
                      ),
                    ),
                  );
                  _refresh();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadSummary {
  final String therapistId;
  final String kind;
  final String? text;
  final int? durationMs;
  final DateTime createdAt;

  _ThreadSummary({
    required this.therapistId,
    required this.kind,
    this.text,
    this.durationMs,
    required this.createdAt,
  });

  factory _ThreadSummary.fromJson(Map<String, dynamic> json) {
    DateTime parsed;
    try {
      parsed = DateTime.parse(json['created_at'] ?? '');
    } catch (_) {
      parsed = DateTime.now();
    }
    return _ThreadSummary(
      therapistId: json['therapist_id'] ?? '',
      kind: json['kind'] ?? 'text',
      text: json['text'],
      durationMs: json['duration_ms'],
      createdAt: parsed,
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _ThreadSummary thread;
  final VoidCallback onOpen;
  const _ThreadTile({required this.thread, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final preview = thread.kind == 'voice'
        ? '🎤 Voice note (${_durationLabel(thread.durationMs)})'
        : (thread.text ?? '');
    return ListTile(
      onTap: onOpen,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: NoorColors.tealSoft,
        child: Text(
          thread.therapistId.length >= 2
              ? thread.therapistId.substring(1, 2).toUpperCase()
              : 'T',
          style: const TextStyle(
            color: NoorColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        'Therapist ${thread.therapistId}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: NoorColors.primaryDeepest,
        ),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade700),
      ),
      trailing: Text(
        DateFormat('h:mm a').format(thread.createdAt.toLocal()),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }

  String _durationLabel(int? ms) {
    if (ms == null) return '';
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NoorColors.tealSoft.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined,
                size: 48, color: NoorColors.primaryDark),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: NoorColors.primaryDeepest,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Open a therapist profile and tap “Message” to start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
