/// A simulated booking for a general home-services provider.
class ServiceBooking {
  final String bookingId;
  final String providerName;
  final String category;
  final String date;
  final String time;
  final double price;
  final String confirmationCode;
  final String status;

  ServiceBooking({
    required this.bookingId,
    required this.providerName,
    required this.category,
    required this.date,
    required this.time,
    required this.price,
    required this.confirmationCode,
    required this.status,
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      bookingId: json['booking_id'] ?? '',
      providerName: json['provider_name'] ?? '',
      category: json['category'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      confirmationCode: json['confirmation_code'] ?? '',
      status: json['status'] ?? 'confirmed',
    );
  }
}

class ServiceBookingResult {
  final ServiceBooking booking;
  final String traceId;
  final String userMessage;
  final List<Map<String, dynamic>> followupEvents;

  ServiceBookingResult({
    required this.booking,
    required this.traceId,
    required this.userMessage,
    required this.followupEvents,
  });
}
