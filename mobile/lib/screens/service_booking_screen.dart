import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/service_provider.dart';
import '../models/service_booking.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import 'agent_trace_screen.dart';

/// Simulated end-to-end booking for a general-service provider:
/// booking → confirmation → notification → follow-up reminder.
class ServiceBookingScreen extends StatefulWidget {
  final ServiceProvider provider;
  final Map<String, dynamic> intent;
  final String traceId;

  const ServiceBookingScreen({
    super.key,
    required this.provider,
    required this.intent,
    required this.traceId,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  ServiceBooking? _booking;
  String _userMessage = '';
  List<Map<String, dynamic>> _followups = [];
  String _fullTraceId = '';

  @override
  void initState() {
    super.initState();
    _book();
  }

  Future<void> _book() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.bookService(
        providerId: widget.provider.id,
        slot: widget.provider.nextAvailableSlot,
        intent: widget.intent,
        traceId: widget.traceId,
      );
      if (!mounted) return;
      setState(() {
        _booking = result.booking;
        _userMessage = result.userMessage;
        _followups = result.followupEvents;
        _fullTraceId = result.traceId;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NoorColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: NoorColors.primary),
              const SizedBox(height: 20),
              const Text('Booking Agent processing…',
                  style: TextStyle(
                      color: NoorColors.primary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Securing slot · Sending confirmation · Scheduling reminder',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        backgroundColor: NoorColors.background,
        appBar: AppBar(title: const Text('Booking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: NoorColors.danger),
                const SizedBox(height: 16),
                const Text('Booking failed',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NoorColors.primaryDeepest)),
                const SizedBox(height: 8),
                Text(_error ?? 'Please try again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: NoorColors.textSecondary)),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _book,
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
        ),
      );
    }

    final b = _booking!;
    return Scaffold(
      backgroundColor: NoorColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: NoorColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text('Booking Confirmed!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NoorColors.primaryDeepest)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: NoorColors.greenSoft,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(b.confirmationCode,
                    style: const TextStyle(
                        fontSize: 18,
                        color: NoorColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 24),

              // Booking detail card
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: NoorColors.greenSoft,
                          child: Icon(serviceCategoryIcon(b.category),
                              color: NoorColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.providerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(serviceCategoryLabel(b.category),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    _row(Icons.event, 'Date', b.date),
                    const SizedBox(height: 8),
                    _row(Icons.schedule, 'Time', b.time),
                    const SizedBox(height: 8),
                    _row(Icons.payments_outlined, 'Price',
                        'Rs ${b.price.toInt()}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // WhatsApp-style notification preview (from Notification Agent)
              _whatsappPreview(b),
              const SizedBox(height: 16),

              // Follow-up reminders (from Follow-Up Agent)
              if (_followups.isNotEmpty) _followupCard(),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgentTraceScreen(traceId: _fullTraceId),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined,
                    color: NoorColors.primary, size: 18),
                label: const Text('View Full Agent Trace',
                    style: TextStyle(color: NoorColors.primary)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: NoorColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking is simulated for the NoorAI prototype. No real provider was contacted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NoorColors.primary),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _whatsappPreview(ServiceBooking b) {
    final msg = _userMessage.isNotEmpty
        ? _userMessage
        : 'Booking confirmed with ${b.providerName}. Confirmation: ${b.confirmationCode}.';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_chat_unread, color: Color(0xFF075E54), size: 18),
              SizedBox(width: 8),
              Text('NoorAI Bot · Notification Agent',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF075E54))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _followupCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: NoorColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Follow-up scheduled',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ..._followups.map((e) {
            final type = (e['type'] ?? '').toString().replaceAll('_', ' ');
            final detail = (e['message_preview'] ?? e['prompt'] ?? e['at'] ?? '')
                .toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: NoorColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                        if (detail.isNotEmpty)
                          Text(detail,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
