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
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (widget.traceId.isEmpty) {
      setState(() {
        _error = 'No trace is available for this result.';
        _isLoading = false;
      });
      return;
    }
    final trace = await _api.getTrace(widget.traceId);
    if (!mounted) return;
    setState(() {
      _trace = trace;
      _error = trace == null ? "Couldn't load the agent trace." : null;
      _isLoading = false;
    });
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
          : _error != null
              ? _buildError()
              : _buildTrace(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF5B6B62)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Color(0xFF0E7C42)),
              label: const Text('Try again',
                  style: TextStyle(color: Color(0xFF0E7C42))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0E7C42)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
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
