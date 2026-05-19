class Therapist {
  final String id;
  final String name;
  final String gender;
  final List<String> specializations;
  final List<String> qualifications;
  final String? qualificationLevel;
  final bool verified;
  final String city;
  final String area;
  final double rating;
  final int reviewCount;
  final int? lastReviewDaysAgo;
  final double? onTimeRate;
  final double? cancellationRate;
  final double basePrice;
  final List<String>? ageRanges;
  final int? experienceYears;
  final List<String>? availableSlots;
  final String bio;
  final List<String> languages;

  // Populated from ranked API response
  final double? overallScore;
  final Map<String, dynamic>? factorScores;
  final String? reasoning;
  final double? distanceKm;
  final double? finalPrice;
  final String? nextAvailableSlot;

  Therapist({
    required this.id,
    required this.name,
    required this.gender,
    required this.specializations,
    required this.qualifications,
    this.qualificationLevel,
    required this.verified,
    required this.city,
    required this.area,
    required this.rating,
    required this.reviewCount,
    this.lastReviewDaysAgo,
    this.onTimeRate,
    this.cancellationRate,
    required this.basePrice,
    this.ageRanges,
    this.experienceYears,
    this.availableSlots,
    required this.bio,
    required this.languages,
    this.overallScore,
    this.factorScores,
    this.reasoning,
    this.distanceKm,
    this.finalPrice,
    this.nextAvailableSlot,
  });

  // The ranked API response nests therapist details under a 'therapist' key:
  // { therapist_id, overall_score, factor_scores, reasoning, distance_km, price, therapist: {...} }
  factory Therapist.fromJson(Map<String, dynamic> json) {
    final t = (json['therapist'] as Map<String, dynamic>?) ?? json;

    final slots = (t['available_slots'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    return Therapist(
      id: t['id'] ?? json['therapist_id'] ?? '',
      name: t['name'] ?? 'Unknown Therapist',
      gender: t['gender'] ?? 'not_specified',
      specializations: List<String>.from(t['specializations'] ?? []),
      qualifications: List<String>.from(t['qualifications'] ?? []),
      qualificationLevel: t['qualification_level'],
      verified: t['verified'] ?? false,
      city: t['city'] ?? '',
      area: t['area'] ?? '',
      rating: (t['rating'] ?? 0.0).toDouble(),
      reviewCount: t['review_count'] ?? 0,
      lastReviewDaysAgo: t['last_review_days_ago'],
      onTimeRate: t['on_time_rate']?.toDouble(),
      cancellationRate: t['cancellation_rate']?.toDouble(),
      basePrice: (t['base_price'] ?? 0).toDouble(),
      ageRanges: (t['age_ranges'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      experienceYears: t['experience_years'],
      availableSlots: slots,
      bio: t['bio'] ?? '',
      languages: List<String>.from(t['languages'] ?? []),
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      factorScores: json['factor_scores'] as Map<String, dynamic>?,
      reasoning: json['reasoning'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      // Backend returns 'price' in ranked response; 'final_price' in direct pricing
      finalPrice: (json['price'] ?? json['final_price'] as num?)?.toDouble(),
      nextAvailableSlot: slots?.isNotEmpty == true ? slots!.first : null,
    );
  }
}
