class UserProfile {
  final String userId;
  final String email;
  final String name;
  final String? phone;
  final String? childName;
  final int? childAge;
  final String? childCondition;
  final String? city;
  final String? area;
  final String createdAt;

  UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    this.phone,
    this.childName,
    this.childAge,
    this.childCondition,
    this.city,
    this.area,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      childName: json['child_name'],
      childAge: json['child_age'],
      childCondition: json['child_condition'],
      city: json['city'],
      area: json['area'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get onboardingComplete =>
      (childName?.isNotEmpty ?? false) &&
      childAge != null &&
      (childCondition?.isNotEmpty ?? false) &&
      (city?.isNotEmpty ?? false);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
