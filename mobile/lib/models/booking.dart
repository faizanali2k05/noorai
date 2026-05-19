class BookingSession {
  final String date;
  final String time;
  final int durationMin;
  final String status;

  BookingSession({
    required this.date,
    required this.time,
    required this.durationMin,
    required this.status,
  });

  factory BookingSession.fromJson(Map<String, dynamic> json) {
    return BookingSession(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      durationMin: json['duration_min'] ?? 45,
      status: json['status'] ?? 'confirmed',
    );
  }

  String get formattedDate {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      return '$day ${months[month]}';
    } catch (_) {
      return date;
    }
  }
}

class Booking {
  final String bookingId;
  final String therapistId;
  final String userId;
  final List<BookingSession> sessions;
  final int totalPrice;
  final String confirmationCode;
  final String status;
  final String createdAt;

  Booking({
    required this.bookingId,
    required this.therapistId,
    required this.userId,
    required this.sessions,
    required this.totalPrice,
    required this.confirmationCode,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? '',
      therapistId: json['therapist_id'] ?? '',
      userId: json['user_id'] ?? 'u001',
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => BookingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['total_price'] ?? 0) as int,
      confirmationCode: json['confirmation_code'] ?? 'NA-DEMO-0001',
      status: json['status'] ?? 'confirmed',
      createdAt: json['created_at'] ?? '',
    );
  }
}
