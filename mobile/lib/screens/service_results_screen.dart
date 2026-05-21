import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/service_provider.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import 'agent_trace_screen.dart';
import 'service_booking_screen.dart';

/// Shows the ranked general-service providers returned by the agent pipeline.
class ServiceResultsScreen extends StatefulWidget {
  final String userQuery;

  const ServiceResultsScreen({super.key, required this.userQuery});

  @override
  State<ServiceResultsScreen> createState() => _ServiceResultsScreenState();
}

class _ServiceResultsScreenState extends State<ServiceResultsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  List<ServiceProvider> _providers = [];
  String _traceId = '';
  Map<String, dynamic> _intent = {};

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
    try {
      final result = await _api.findServices(widget.userQuery);
      if (!mounted) return;
      setState(() {
        _providers = result.providers;
        _traceId = result.traceId;
        _intent = result.intent;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<String> get _intentChips {
    final chips = <String>[];
    final category = _intent['category'] as String?;
    if (category != null) chips.add(serviceCategoryLabel(category));
    final city = _intent['city'] as String?;
    final area = _intent['area'] as String?;
    if (city != null || area != null) {
      chips.add([area, city].where((s) => s != null).join(', '));
    }
    final time = _intent['preferred_time'] as String?;
    if (time != null && time != 'flexible') chips.add(time);
    final urgency = _intent['urgency'] as String?;
    if (urgency != null && urgency != 'scheduled') {
      chips.add(urgency.replaceAll('_', ' '));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorColors.background,
      appBar: AppBar(title: const Text('Top Matches')),
      body: Column(
        children: [
          if (!_isLoading && _error == null && _intentChips.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _intentChips
                    .map((c) => Chip(
                          label: Text(c,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white)),
                          backgroundColor: NoorColors.primaryDeepest,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: NoorColors.primary),
                        SizedBox(height: 16),
                        Text('Agents matching providers…',
                            style: TextStyle(color: NoorColors.primary)),
                      ],
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : _providers.isEmpty
                        ? const Center(
                            child: Text('No providers found for your request.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _providers.length,
                            itemBuilder: (ctx, i) =>
                                _buildCard(_providers[i], i),
                          ),
          ),
          if (!_isLoading && _error == null && _providers.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgentTraceScreen(traceId: _traceId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined,
                      color: NoorColors.primary),
                  label: const Text('See Agent Reasoning →',
                      style: TextStyle(color: NoorColors.primary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: NoorColors.primary),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: NoorColors.textMuted),
            const SizedBox(height: 16),
            const Text("Couldn't reach NoorAI",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NoorColors.primaryDeepest)),
            const SizedBox(height: 8),
            Text(_error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: NoorColors.textSecondary)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: NoorColors.primary),
              label: const Text('Try again',
                  style: TextStyle(color: NoorColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NoorColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ServiceProvider p, int rank) {
    final isTop = rank == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTop
            ? Border.all(color: NoorColors.primary, width: 1.6)
            : Border.all(color: const Color(0xFFE3EFE8)),
        boxShadow: [
          BoxShadow(
            color: isTop
                ? NoorColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isTop ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTop)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: const BoxDecoration(
                color: NoorColors.brand,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                  SizedBox(width: 6),
                  Text('BEST MATCH · AI RANKED #1',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: NoorColors.greenSoft,
                      child: Icon(serviceCategoryIcon(p.category),
                          color: NoorColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ),
                              if (p.verified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    color: NoorColors.primary, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${serviceCategoryLabel(p.category)} · ${p.area}, ${p.city}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _stat(Icons.star, '${p.rating} (${p.reviewCount})',
                        const Color(0xFFF59E0B)),
                    if (p.distanceKm != null)
                      _stat(Icons.location_on_outlined,
                          '${p.distanceKm!.toStringAsFixed(1)} km',
                          NoorColors.textSecondary),
                    _stat(Icons.payments_outlined,
                        'Rs ${(p.price ?? p.basePrice).toInt()}',
                        NoorColors.primaryDark),
                    if (p.onTimeRate != null)
                      _stat(Icons.timer_outlined,
                          '${(p.onTimeRate! * 100).toInt()}% on-time',
                          NoorColors.textSecondary),
                  ],
                ),
                if (p.reasoning != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NoorColors.greenSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_outlined,
                            size: 16, color: NoorColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.reasoning!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: NoorColors.textPrimary,
                                  height: 1.4)),
                        ),
                      ],
                    ),
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
                          builder: (_) => ServiceBookingScreen(
                            provider: p,
                            intent: _intent,
                            traceId: _traceId,
                          ),
                        ),
                      );
                    },
                    child: Text('Book ${p.name}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                color: NoorColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
