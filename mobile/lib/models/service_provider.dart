/// A general home-services provider (plumber, electrician, AC technician, …)
/// returned by the /api/find-services ranking pipeline.
class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String city;
  final String area;
  final double rating;
  final int reviewCount;
  final double? onTimeRate;
  final double basePrice;
  final List<String> availableSlots;
  final bool verified;
  final int? experienceYears;
  final String bio;
  final String? phone;

  // Populated from the ranked response.
  final double? overallScore;
  final Map<String, dynamic>? factorScores;
  final String? reasoning;
  final double? distanceKm;
  final double? price;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.area,
    required this.rating,
    required this.reviewCount,
    this.onTimeRate,
    required this.basePrice,
    required this.availableSlots,
    required this.verified,
    this.experienceYears,
    required this.bio,
    this.phone,
    this.overallScore,
    this.factorScores,
    this.reasoning,
    this.distanceKm,
    this.price,
  });

  String? get nextAvailableSlot =>
      availableSlots.isNotEmpty ? availableSlots.first : null;

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final p = (json['provider'] as Map<String, dynamic>?) ?? json;
    return ServiceProvider(
      id: p['id'] ?? json['provider_id'] ?? '',
      name: p['name'] ?? 'Provider',
      category: p['category'] ?? '',
      city: p['city'] ?? '',
      area: p['area'] ?? '',
      rating: (p['rating'] ?? 0.0).toDouble(),
      reviewCount: p['review_count'] ?? 0,
      onTimeRate: p['on_time_rate']?.toDouble(),
      basePrice: (p['base_price'] ?? 0).toDouble(),
      availableSlots: (p['available_slots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      verified: p['verified'] ?? false,
      experienceYears: p['experience_years'],
      bio: p['bio'] ?? '',
      phone: p['phone'],
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      factorScores: json['factor_scores'] as Map<String, dynamic>?,
      reasoning: json['reasoning'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

class ServiceFindResult {
  final List<ServiceProvider> providers;
  final String traceId;
  final Map<String, dynamic> intent;

  ServiceFindResult({
    required this.providers,
    required this.traceId,
    required this.intent,
  });
}
