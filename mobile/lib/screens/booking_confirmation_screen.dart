import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/therapist.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import 'followup_screen.dart';
import 'agent_trace_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Therapist therapist;
  final String slot;
  final Map<String, dynamic> intent;
  final String traceId;

  const BookingConfirmationScreen({
    super.key,
    required this.therapist,
    required this.slot,
    required this.intent,
    required this.traceId,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  final bool _hasError = false;
  Booking? _booking;
  String _parentMessage = '';
  List<Map<String, dynamic>> _followupEvents = [];
  String _fullTraceId = '';

  @override
  void initState() {
    super.initState();
    _book();
  }

  Future<void> _book() async {
    final result = await _api.bookTherapist(
      therapistId: widget.therapist.id,
      slot: widget.slot,
      intent: widget.intent,
      sessionsCount: 2,
      traceId: widget.traceId,
    );

    if (mounted) {
      setState(() {
        _booking = result.booking;
        _parentMessage = result.parentNotification;
        _followupEvents = result.followupEvents;
        _fullTraceId = result.traceId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4FBF6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0E7C42)),
              const SizedBox(height: 20),
              const Text(
                'Booking Agent processing...',
                style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0E7C42),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Securing slot · Sending notifications · Scheduling follow-ups',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Booking failed. Please try again.')),
      );
    }

    final booking = _booking!;
    final t = widget.therapist;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01411C)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F5EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.confirmationCode,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF0A5C30),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 24),

              // Session list
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE4F5EC),
                          child: Icon(
                            t.gender == 'female'
                                ? Icons.woman
                                : Icons.man,
                            color: const Color(0xFF0E7C42),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                  t.specializations.first
                                      .replaceAll('_', ' '),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        if (t.verified)
                          const Icon(Icons.verified,
                              color: NoorColors.primary, size: 18),
                      ],
                    ),
                    const Divider(height: 20),
                    ...booking.sessions.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: NoorColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${s.formattedDate} at ${s.time}  ·  ${s.durationMin} min',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total (2 sessions)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(
                          'Rs ${booking.totalPrice}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0E7C42)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // WhatsApp mock notification
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF075E54),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mark_chat_unread,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'NoorAI Bot · Notification Agent',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5DDD5),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _parentMessage.isNotEmpty
                              ? _parentMessage
                              : 'Salam! Aap ka booking confirm ho gaya hai. ${t.name} kal 4:00 PM ko aap ke ghar aayengi. Confirmation: ${booking.confirmationCode}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action buttons
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FollowupScreen(events: _followupEvents),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Color(0xFF0E7C42)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('View Follow-Up Schedule',
                    style:
                        TextStyle(fontSize: 15, color: Color(0xFF0E7C42))),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AgentTraceScreen(traceId: _fullTraceId),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined,
                    color: Color(0xFF6B7280), size: 18),
                label: const Text('View Full Agent Trace',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7C42),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Text(
                'NoorAI does not provide medical diagnosis. This platform connects families with therapists.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
