import 'package:flutter/material.dart';
import '../models/therapist.dart';
import '../widgets/score_bar.dart';
import '../widgets/price_breakdown.dart';
import 'booking_confirmation_screen.dart';
import 'therapist_chat_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  final Therapist therapist;
  final Map<String, dynamic> intent;
  final String traceId;

  const ProviderDetailScreen({
    super.key,
    required this.therapist,
    required this.intent,
    required this.traceId,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    // Pre-select the first available slot
    if (widget.therapist.availableSlots?.isNotEmpty == true) {
      _selectedSlot = widget.therapist.availableSlots!.first;
    }
  }

  String _formatSlot(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dayName = days[dt.weekday - 1];
      final hour = dt.hour;
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$dayName ${dt.day} ${months[dt.month]}, ${displayHour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.therapist;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text('Therapist Details',
            style: TextStyle(color: Color(0xFF134E4A))),
        actions: [
          IconButton(
            tooltip: 'Message therapist',
            icon: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF0D9488)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TherapistChatScreen(
                    therapistId: widget.therapist.id,
                    therapistName: widget.therapist.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Icon(
                      t.gender == 'female' ? Icons.woman : Icons.man,
                      color: const Color(0xFF0284C7),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937)),
                      ),
                      if (t.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.specializations
                        .map((s) => s.replaceAll('_', ' '))
                        .join(' · ')
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D9488),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${t.rating} ★  ·  ${t.reviewCount} reviews  ·  ${t.area}, ${t.city}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const TabBar(
              labelColor: Color(0xFF0D9488),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0D9488),
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Scores'),
                Tab(text: 'Schedule'),
                Tab(text: 'Price'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(t),
                  _buildScoresTab(t),
                  _buildScheduleTab(t),
                  _buildPriceTab(t),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedSlot == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationScreen(
                          therapist: t,
                          slot: _selectedSlot!,
                          intent: widget.intent,
                          traceId: widget.traceId,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _selectedSlot == null
                  ? 'Select a slot to Book'
                  : 'Book Now — ${_formatSlot(_selectedSlot!)}',
              style:
                  const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Therapist t) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('About'),
        const SizedBox(height: 8),
        Text(t.bio,
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF4B5563), height: 1.5)),
        const SizedBox(height: 20),
        _sectionTitle('Qualifications'),
        const SizedBox(height: 8),
        ...t.qualifications.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(q,
                          style: const TextStyle(
                              color: Color(0xFF4B5563), fontSize: 14))),
                ],
              ),
            )),
        const SizedBox(height: 20),
        _sectionTitle('Details'),
        const SizedBox(height: 8),
        _detailRow(Icons.work_outline,
            '${t.experienceYears ?? "—"} years of experience'),
        _detailRow(Icons.child_care,
            'Age ranges: ${(t.ageRanges ?? []).join(', ')}'),
        _detailRow(Icons.language,
            'Languages: ${t.languages.join(', ')}'),
        if (t.onTimeRate != null)
          _detailRow(Icons.timer_outlined,
              '${(t.onTimeRate! * 100).toInt()}% on-time rate'),
        if (t.cancellationRate != null)
          _detailRow(Icons.cancel_outlined,
              '${(t.cancellationRate! * 100).toInt()}% cancellation rate'),
        const SizedBox(height: 20),
        _sectionTitle('Patient Reviews'),
        const SizedBox(height: 8),
        ..._mockReviews(t),
      ],
    );
  }

  Widget _buildScoresTab(Therapist t) {
    final fs = t.factorScores;
    if (fs == null) {
      return const Center(
          child: Text('Score breakdown not available',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (t.overallScore != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFF059669), size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Match Score',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF065F46))),
                    Text(
                      '${(t.overallScore! * 100).toInt()}% match',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _sectionTitle('8-Factor Breakdown'),
        const SizedBox(height: 12),
        ...(fs.entries.map((e) => ScoreBar(
              label: e.key.replaceAll('_', ' ').split(' ').map((w) {
                return w.isEmpty
                    ? w
                    : '${w[0].toUpperCase()}${w.substring(1)}';
              }).join(' '),
              score: (e.value as num).toDouble(),
            ))),
        const SizedBox(height: 16),
        if (t.reasoning != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              '🤖 ${t.reasoning}',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleTab(Therapist t) {
    final slots = t.availableSlots ?? [];
    if (slots.isEmpty) {
      return const Center(
          child: Text('No available slots',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Available Slots (next 14 days)'),
        const SizedBox(height: 4),
        Text('Tap a slot to select it for booking.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ...slots.map((slot) {
          final isSelected = slot == _selectedSlot;
          return GestureDetector(
            onTap: () => setState(() => _selectedSlot = slot),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFECFDF5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.calendar_today_outlined,
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatSlot(slot),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF065F46)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Text('Selected',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceTab(Therapist t) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Pricing Agent Breakdown'),
        const SizedBox(height: 4),
        Text('Dynamic pricing computed by the Pricing Agent.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        PriceBreakdownWidget(
          basePrice: t.basePrice,
          finalPrice: t.finalPrice,
          sessionsCount: 2,
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937)));
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4B5563))),
          ),
        ],
      ),
    );
  }

  List<Widget> _mockReviews(Therapist t) {
    final reviews = [
      {
        'name': 'Sadia M.',
        'date': '12 May 2026',
        'rating': 5,
        'text':
            'Excellent therapist! My son showed visible improvement after just 3 sessions. Very patient and professional.',
      },
      {
        'name': 'Tariq A.',
        'date': '28 Apr 2026',
        'rating': 5,
        'text':
            'Highly recommended. She is very understanding and explains progress clearly to the parents.',
      },
      {
        'name': 'Hina K.',
        'date': '15 Apr 2026',
        'rating': 4,
        'text':
            'Great with children. Punctual and uses engaging techniques. Slightly over our budget but worth it.',
      },
    ];
    return reviews
        .map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(r['date'] as String,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      r['rating'] as int,
                      (_) => const Icon(Icons.star,
                          size: 13, color: Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(r['text'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4)),
                ],
              ),
            ))
        .toList();
  }
}
