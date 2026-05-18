import 'package:flutter/material.dart';
import '../models/therapist.dart';
import '../services/api_service.dart';
import 'provider_detail_screen.dart';
import 'agent_trace_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String userQuery;

  const ProviderListScreen({super.key, required this.userQuery});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Therapist> _therapists = [];

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    try {
      final results = await _apiService.findTherapists(widget.userQuery);
      if (mounted) {
        setState(() {
          _therapists = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
          style: TextStyle(color: Color(0xFF134E4A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Edit intent logic here
            },
            child: const Text('Edit Intent', style: TextStyle(color: Color(0xFF0D9488))),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              children: [
                _buildIntentChip('Speech Therapy'),
                _buildIntentChip('Lahore Gulberg'),
                _buildIntentChip('Age 5'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _therapists.length,
                  itemBuilder: (context, index) {
                    final t = _therapists[index];
                    return _buildTherapistCard(t, context);
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AgentTraceScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, color: Color(0xFF0D9488)),
                label: const Text('See Agent Reasoning →', style: TextStyle(color: Color(0xFF0D9488))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIntentChip(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: const Color(0xFF115E59),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }

  Widget _buildTherapistCard(Therapist t, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Icon(t.gender == 'female' ? Icons.woman : Icons.man, color: const Color(0xFF0284C7), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.verified)
                            const Icon(Icons.verified, color: Colors.blue, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.rating} ★ (${t.reviewCount} reviews)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Score: ${(t.overallScore ?? 0) * 100}% Match', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: t.overallScore,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF10B981),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHighlightChip('Speech Specialist ✓', Icons.check_circle_outline),
                _buildHighlightChip('${t.distanceKm}km away', Icons.location_on_outlined),
                _buildHighlightChip('Rs ${t.finalPrice}/session', Icons.payments_outlined),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProviderDetailScreen(therapist: t)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF1F2937),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}
