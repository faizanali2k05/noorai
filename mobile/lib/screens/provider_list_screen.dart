import 'package:flutter/material.dart';
import '../models/therapist.dart';
import '../services/api_service.dart';
import '../widgets/score_bar.dart';
import 'provider_detail_screen.dart';
import 'agent_trace_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String userQuery;

  const ProviderListScreen({super.key, required this.userQuery});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Therapist> _therapists = [];
  String _traceId = '';
  Map<String, dynamic> _intent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _api.findTherapists(widget.userQuery);
    if (mounted) {
      setState(() {
        _therapists = result.therapists;
        _traceId = result.traceId;
        _intent = result.intent;
        _isLoading = false;
      });
    }
  }

  // Build readable intent chips from extracted intent map
  List<String> get _intentChips {
    final chips = <String>[];
    final service = _intent['service_type'] as String?;
    if (service != null) {
      chips.add(service.replaceAll('_', ' ').split(' ').map((w) {
        return w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' '));
    }
    final city = _intent['city'] as String?;
    final area = _intent['area'] as String?;
    if (city != null || area != null) {
      chips.add([area, city].where((s) => s != null).join(', '));
    }
    final age = _intent['child_age'];
    if (age != null) chips.add('Age $age');
    final budget = _intent['budget_per_session'];
    if (budget != null) chips.add('Budget Rs $budget');
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text(
          'Top Matches',
          style: TextStyle(
              color: Color(0xFF134E4A),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Intent chips bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _intentChips
                  .map((chip) => _buildIntentChip(chip))
                  .toList(),
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0D9488)),
                        SizedBox(height: 16),
                        Text('7 agents working...',
                            style: TextStyle(color: Color(0xFF0D9488))),
                      ],
                    ),
                  )
                : _therapists.isEmpty
                    ? const Center(
                        child: Text('No therapists found for your query.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _therapists.length,
                        itemBuilder: (ctx, i) =>
                            _buildCard(_therapists[i], ctx),
                      ),
          ),
          // See Agent Reasoning button
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AgentTraceScreen(traceId: _traceId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined,
                      color: Color(0xFF0D9488)),
                  label: const Text('See Agent Reasoning →',
                      style: TextStyle(color: Color(0xFF0D9488))),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntentChip(String text) {
    return Chip(
      label: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: const Color(0xFF115E59),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildCard(Therapist t, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Icon(
                    t.gender == 'female' ? Icons.woman : Icons.man,
                    color: const Color(0xFF0284C7),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.verified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified,
                                  color: Colors.blue, size: 17),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${t.rating} ★ (${t.reviewCount} reviews) · ${t.area}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Overall score bar
            if (t.overallScore != null) ...[
              ScoreBar(
                label: 'Overall Match Score',
                score: t.overallScore!,
              ),
            ],
            const SizedBox(height: 8),
            // Highlights
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (t.distanceKm != null)
                  _chip(Icons.location_on_outlined,
                      '${t.distanceKm!.toStringAsFixed(1)} km'),
                _chip(Icons.payments_outlined,
                    'Rs ${t.finalPrice?.toInt() ?? t.basePrice.toInt()}/session'),
                if (t.qualificationLevel != null)
                  _chip(Icons.school_outlined,
                      t.qualificationLevel!.toUpperCase()),
              ],
            ),
            // Reasoning
            if (t.reasoning != null) ...[
              const SizedBox(height: 10),
              Text(
                t.reasoning!,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailScreen(
                        therapist: t,
                        intent: _intent,
                        traceId: _traceId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Details & Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}
