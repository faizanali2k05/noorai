class Therapist {
  final String id;
  final String name;
  final String gender;
  final List<String> specializations;
  final List<String> qualifications;
  final bool verified;
  final String city;
  final String area;
  final double rating;
  final int reviewCount;
  final double basePrice;
  final String bio;
  final List<String> languages;
  
  // For ranking matches
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
    required this.verified,
    required this.city,
    required this.area,
    required this.rating,
    required this.reviewCount,
    required this.basePrice,
    required this.bio,
    required this.languages,
    this.overallScore,
    this.factorScores,
    this.reasoning,
    this.distanceKm,
    this.finalPrice,
    this.nextAvailableSlot,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] ?? json['therapist_id'] ?? '',
      name: json['name'] ?? 'Unknown Therapist',
      gender: json['gender'] ?? '',
      specializations: List<String>.from(json['specializations'] ?? []),
      qualifications: List<String>.from(json['qualifications'] ?? []),
      verified: json['verified'] ?? false,
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      basePrice: (json['base_price'] ?? 0).toDouble(),
      bio: json['bio'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      overallScore: json['overall_score']?.toDouble(),
      factorScores: json['factor_scores'],
      reasoning: json['reasoning'],
      distanceKm: json['distance_km']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      nextAvailableSlot: json['next_available_slot'],
    );
  }
}
