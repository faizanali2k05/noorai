import 'package:flutter/material.dart';
import '../theme.dart';
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
      return '$dayName ${dt.day} ${months[dt.month]}, $displayHour:${dt.minute.toString().padLeft(2, '0')} $amPm';
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
        iconTheme: const IconThemeData(color: Color(0xFF01411C)),
        title: const Text('Therapist Details',
            style: TextStyle(color: Color(0xFF01411C))),
        actions: [
          IconButton(
            tooltip: 'Message therapist',
            icon: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF0E7C42)),
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
                    backgroundColor: const Color(0xFFE4F5EC),
                    child: Icon(
                      t.gender == 'female' ? Icons.woman : Icons.man,
                      color: const Color(0xFF0E7C42),
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
                            color: NoorColors.primary, size: 22),
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
                        color: Color(0xFF0E7C42),
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
              labelColor: Color(0xFF0E7C42),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0E7C42),
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
              backgroundColor: const Color(0xFF0E7C42),
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
                  const Icon(Icons.school, size: 16, color: Color(0xFF0E7C42)),
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
        _sectionTitle('Ratings'),
        const SizedBox(height: 8),
        _buildRatingSummary(t),
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
                      ? const Color(0xFF0E7C42)
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
                        ? const Color(0xFF0E7C42)
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
                            color: Color(0xFF0E7C42),
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

  /// Aggregate rating summary built from real backend fields (rating,
  /// reviewCount, lastReviewDaysAgo) — no fabricated review text.
  Widget _buildRatingSummary(Therapist t) {
    final rating = t.rating;
    final count = t.reviewCount;
    if (rating <= 0 || count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'No ratings yet for this therapist.',
          style: TextStyle(fontSize: 13, color: Color(0xFF5B6B62)),
        ),
      );
    }

    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F5EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7D7BD)),
      ),
      child: Row(
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF01411C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) {
                    IconData icon;
                    if (i < full) {
                      icon = Icons.star;
                    } else if (i == full && hasHalf) {
                      icon = Icons.star_half;
                    } else {
                      icon = Icons.star_border;
                    }
                    return Icon(icon, size: 18, color: const Color(0xFFF59E0B));
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  t.lastReviewDaysAgo != null
                      ? '$count reviews · last review ${t.lastReviewDaysAgo} days ago'
                      : '$count reviews',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF5B6B62)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
