import 'package:flutter/material.dart';
import '../models/trace_entry.dart';
import '../services/api_service.dart';
import '../widgets/trace_card.dart';

class AgentTraceScreen extends StatefulWidget {
  final String traceId;

  const AgentTraceScreen({super.key, required this.traceId});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  TraceLog? _trace;

  // Handoff summaries shown between agent cards
  static const List<String> _handoffs = [
    '{ service_type, condition, city, age, budget }',
    '{ candidates_found, candidate_ids[] }',
    '{ top_3_scores, factor_scores[] }',
    '{ prices_calculated, breakdown }',
    '{ booking_confirmed, confirmation_code }',
    '{ notifications_sent, whatsapp_mock }',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.traceId.isNotEmpty && !widget.traceId.startsWith('mock')) {
      final trace = await _api.getTrace(widget.traceId);
      if (mounted) {
        setState(() {
          _trace = trace;
          _isLoading = false;
        });
        return;
      }
    }
    // Fallback to built-in mock trace
    if (mounted) {
      setState(() {
        _trace = _mockTrace();
        _isLoading = false;
      });
    }
  }

  TraceLog _mockTrace() {
    return TraceLog(
      traceId: widget.traceId,
      createdAt: DateTime.now().toIso8601String(),
      userMessage:
          'Mere bete ko speech delay hai 5 saal ka hai Gulberg Lahore mein hafte mein 2 baar 3000 budget',
      entries: [
        TraceEntry(
          agent: 'Intent Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 420,
          inputSummary: '"Mere bete ko speech delay hai 5 saal ka..."',
          reasoning:
              'Detected Roman Urdu. Extracted service=speech_therapy, condition=speech_delay, age=5, city=Lahore, area=Gulberg, budget=3000, frequency=biweekly. Confidence: 0.94.',
          outputSummary:
              '{"service_type":"speech_therapy","city":"Lahore","child_age":5,"confidence":0.94}',
        ),
        TraceEntry(
          agent: 'Discovery Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 185,
          inputSummary: '{"city":"Lahore","service":"speech_therapy","age":5}',
          reasoning:
              'Applied hard filters: city=Lahore, specialization=speech_therapy, age in range. Found 12 candidates within 15km after expanding from initial 5km radius.',
          outputSummary: '{"candidate_count":12,"candidate_ids":["t001","t004","t007",...]}',
        ),
        TraceEntry(
          agent: 'Ranking Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 640,
          inputSummary: '{"candidate_count":12,"weights":"8-factor"}',
          reasoning:
              'Scored 12 candidates across 8 factors. Top: Dr. Ayesha Khan (0.92) — M.Phil specialist, 2.3km, 4.8★, 94% on-time, budget fits. Applied verification multiplier ×1.15 and gender preference ×1.0.',
          outputSummary:
              '{"top_ids":["t001","t007","t012"],"top_scores":[0.92,0.85,0.71]}',
        ),
        TraceEntry(
          agent: 'Pricing Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 310,
          inputSummary:
              '{"therapist_ids":["t001","t007","t012"],"urgency":"scheduled"}',
          reasoning:
              'Calculated dynamic prices: base 2800 × urgency 1.0 × complexity 1.2 − 0 loyalty = Rs 3,360 for t001. Similarly priced top-3.',
          outputSummary: '{"t001":3360,"t007":3500,"t012":2400}',
        ),
        TraceEntry(
          agent: 'Booking Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 220,
          inputSummary: '{"therapist_id":"t001","slot":"2026-05-20T16:00:00","sessions_count":2}',
          reasoning:
              'Optimistic lock check passed — slot available. Created booking BK-20260519-001. Wrote 2 sessions to bookings.json. Confirmation code: NA-AYK-4291.',
          outputSummary: '{"booking_id":"BK-20260519-001","confirmation_code":"NA-AYK-4291","status":"confirmed"}',
        ),
        TraceEntry(
          agent: 'Notification Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 290,
          inputSummary: '{"booking_id":"BK-20260519-001"}',
          reasoning:
              'Generated Roman Urdu WhatsApp message for parent (detected language preference from query). Generated English message for therapist.',
          outputSummary:
              '{"to_parent":{"channel":"whatsapp","language":"roman_urdu"},"to_therapist":{"channel":"whatsapp","language":"english"}}',
        ),
        TraceEntry(
          agent: 'Follow-Up Agent',
          startedAt: DateTime.now().toIso8601String(),
          durationMs: 175,
          inputSummary: '{"booking_id":"BK-20260519-001","sessions":2}',
          reasoning:
              'Scheduled 5 follow-up events: 2 reminders (1h before each session), 1 post-session feedback (30min after session 1), 1 progress digest (after session 4), 1 renewal nudge (after session 8).',
          outputSummary: '{"scheduled_events":5,"first_trigger":"1_hour_before_session_1"}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF01411C)),
        title: const Text('How NoorAI Decided',
            style: TextStyle(color: Color(0xFF01411C))),
        actions: [
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh,
                color: Color(0xFF0E7C42), size: 18),
            label: const Text('Replay',
                style: TextStyle(color: Color(0xFF0E7C42))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0E7C42)),
                  SizedBox(height: 16),
                  Text('Loading agent trace...',
                      style: TextStyle(color: Color(0xFF0E7C42))),
                ],
              ),
            )
          : _buildTrace(),
    );
  }

  Widget _buildTrace() {
    final entries = _trace?.entries ?? [];
    if (entries.isEmpty) {
      return const Center(child: Text('No trace data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF01411C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${entries.length} Antigravity Agents completed in ${_trace!.totalDurationLabel}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                textAlign: TextAlign.center,
              ),
              if (_trace?.userMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  '"${_trace!.userMessage}"',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Agent cards with handoff arrows
        for (int i = 0; i < entries.length; i++) ...[
          TraceCard(entry: entries[i]),
          if (i < entries.length - 1 && i < _handoffs.length)
            HandoffArrow(dataSummary: _handoffs[i]),
        ],

        const SizedBox(height: 20),
        // Export button
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Trace ID: ${widget.traceId}\n(Export: GET /api/trace/${widget.traceId})'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text('Export JSON Trace',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF01411C),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Trace ID: ${widget.traceId}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
