import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../theme.dart';

class TherapistChatScreen extends StatefulWidget {
  final String therapistId;
  final String therapistName;
  const TherapistChatScreen({
    super.key,
    required this.therapistId,
    required this.therapistName,
  });

  @override
  State<TherapistChatScreen> createState() => _TherapistChatScreenState();
}

class _TherapistChatScreenState extends State<TherapistChatScreen> {
  final _api = ApiService();
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _recorder = AudioRecorder();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  DateTime? _recordStartedAt;
  Timer? _recordTimer;
  Duration _elapsed = Duration.zero;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final msgs = await _api.listMessages(widget.therapistId);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToEnd(animated: false);
  }

  void _scrollToEnd({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final pos = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          pos,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(pos);
      }
    });
  }

  Future<void> _sendText() async {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    final msg = await _api.sendText(widget.therapistId, txt);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (msg != null) {
        _messages.add(msg);
        _textCtrl.clear();
      }
    });
    if (msg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message. Try again.')),
      );
    } else {
      _scrollToEnd();
    }
  }

  Future<void> _startRecording() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }
    if (!await _recorder.hasPermission()) {
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/noorai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    _recordStartedAt = DateTime.now();
    _recordPath = path;
    _elapsed = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _recordStartedAt == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_recordStartedAt!);
      });
      if (_elapsed.inSeconds >= 120) {
        _stopAndSend();
      }
    });
    setState(() => _recording = true);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _recording = false;
      _recordStartedAt = null;
      _recordPath = null;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _stopAndSend() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _elapsed;
    setState(() {
      _recording = false;
      _recordStartedAt = null;
      _elapsed = Duration.zero;
    });
    final finalPath = path ?? _recordPath;
    if (finalPath == null || duration.inMilliseconds < 500) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording too short')),
      );
      return;
    }
    setState(() => _sending = true);
    final msg = await _api.sendVoiceNote(
      therapistId: widget.therapistId,
      filePath: finalPath,
      durationMs: duration.inMilliseconds,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (msg != null) _messages.add(msg);
    });
    if (msg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send voice note')),
      );
    } else {
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: NoorColors.tealSoft,
              child: Text(
                widget.therapistName.isNotEmpty
                    ? widget.therapistName[0].toUpperCase()
                    : 'T',
                style: const TextStyle(
                  color: NoorColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.therapistName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: NoorColors.primaryDeepest,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Voice + text · Replies within 24h',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: NoorColors.primary),
                  )
                : _messages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: _messages[i]),
                      ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NoorColors.tealSoft.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 40, color: NoorColors.primaryDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NoorColors.primaryDeepest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a text message or hold the mic to send a voice note about your child.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: _recording ? _buildRecordingBar() : _buildTextBar(),
      ),
    );
  }

  Widget _buildTextBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Message…',
              fillColor: NoorColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                    color: NoorColors.primary, width: 1.2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
            ),
            onSubmitted: (_) => _sendText(),
          ),
        ),
        const SizedBox(width: 6),
        if (_textCtrl.text.trim().isEmpty)
          _circleButton(
            icon: Icons.mic_rounded,
            onPressed: _startRecording,
            color: NoorColors.primary,
          )
        else
          _circleButton(
            icon: Icons.send_rounded,
            onPressed: _sending ? null : _sendText,
            color: NoorColors.primary,
          ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: NoorColors.danger),
          onPressed: _cancelRecording,
          tooltip: 'Cancel',
        ),
        Expanded(
          child: Row(
            children: [
              _PulsingDot(),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_elapsed),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: NoorColors.primaryDeepest,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Recording… max 2 min',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        _circleButton(
          icon: Icons.send_rounded,
          onPressed: _stopAndSend,
          color: NoorColors.primary,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: onPressed == null ? color.withOpacity(0.5) : color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: NoorColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bg = isMine ? NoorColors.primary : Colors.white;
    final fg = isMine ? Colors.white : NoorColors.textPrimary;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: EdgeInsets.symmetric(
          horizontal: message.isVoice ? 8 : 14,
          vertical: message.isVoice ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: isMine
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isVoice)
              _VoicePlayer(message: message, mine: isMine)
            else
              Text(
                message.text ?? '',
                style: TextStyle(color: fg, fontSize: 15, height: 1.3),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.createdAt.toLocal()),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white.withOpacity(0.75)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  final ChatMessage message;
  final bool mine;
  const _VoicePlayer({required this.message, required this.mine});

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  late final AudioPlayer _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _total = Duration(milliseconds: widget.message.durationMs ?? 0);
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      if (d > Duration.zero) {
        setState(() => _total = d);
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final url = widget.message.voiceUrl;
    if (url == null) return;
    final absolute = ApiService.absoluteUrl(url);
    await _player.play(UrlSource(absolute));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.mine ? Colors.white : NoorColors.primary;
    final faint = widget.mine
        ? Colors.white.withOpacity(0.4)
        : Colors.grey.shade300;
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: accent,
              size: 28,
            ),
            onPressed: _toggle,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: faint,
                    color: accent,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt(_playing ? _position : _total),
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.mine
                        ? Colors.white.withOpacity(0.85)
                        : Colors.grey.shade700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
