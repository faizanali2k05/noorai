import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../theme.dart';

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  final _api = ApiService();
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listMyBookings();
  }

  Future<void> _refresh() async {
    final fresh = _api.listMyBookings();
    setState(() => _future = fresh);
    await fresh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: NoorColors.primary,
        child: FutureBuilder<List<Booking>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: NoorColors.primary),
              );
            }
            final items = snap.data ?? const <Booking>[];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  _EmptyState(),
                ],
              );
            }
            final now = DateTime.now();
            final upcoming = <Booking>[];
            final past = <Booking>[];
            for (final b in items) {
              if (_isUpcoming(b, now)) {
                upcoming.add(b);
              } else {
                past.add(b);
              }
            }
            return ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _sectionLabel('Upcoming'),
                  ...upcoming.map((b) => _BookingCard(booking: b)),
                  const SizedBox(height: 8),
                ],
                if (past.isNotEmpty) ...[
                  _sectionLabel('Past'),
                  ...past.map((b) => _BookingCard(booking: b)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isUpcoming(Booking b, DateTime now) {
    if (b.status == 'user_cancelled' || b.status == 'therapist_cancelled') {
      return false;
    }
    for (final s in b.sessions) {
      try {
        final dt = DateTime.parse('${s.date}T${s.time}');
        if (dt.isAfter(now)) return true;
      } catch (_) {}
    }
    return false;
  }

  Widget _sectionLabel(String txt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        txt.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final statusColor = _statusColor(status);
    final firstSession = booking.sessions.isNotEmpty
        ? booking.sessions.first
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NoorColors.tealSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available,
                    color: NoorColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Therapist ${booking.therapistId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: NoorColors.primaryDeepest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.confirmationCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (firstSession != null)
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${_fmtDate(firstSession.date)} at ${firstSession.time}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.layers, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${booking.sessions.length} session${booking.sessions.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs ${NumberFormat.decimalPattern().format(booking.totalPrice)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: NoorColors.primaryDark,
                  fontSize: 15,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trace view coming from confirmation flow'),
                    ),
                  );
                },
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Details'),
                style: TextButton.styleFrom(
                  foregroundColor: NoorColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMM yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'user_cancelled':
        return 'Cancelled';
      case 'therapist_cancelled':
        return 'Cancelled by therapist';
      case 'rebooked':
        return 'Rebooked';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return NoorColors.primary;
      case 'completed':
        return Colors.grey.shade600;
      case 'user_cancelled':
      case 'therapist_cancelled':
        return NoorColors.danger;
      case 'rebooked':
        return NoorColors.amber;
      default:
        return NoorColors.textSecondary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NoorColors.tealSoft.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy,
                size: 48, color: NoorColors.primaryDark),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: NoorColors.primaryDeepest,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Find and book a therapist from the Home tab — your sessions will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
