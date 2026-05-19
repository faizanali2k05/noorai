import 'package:flutter/material.dart';

class PriceBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic>? breakdown;
  final double basePrice;
  final double? finalPrice;
  final int sessionsCount;

  const PriceBreakdownWidget({
    super.key,
    this.breakdown,
    required this.basePrice,
    this.finalPrice,
    this.sessionsCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final base = breakdown?['base_rate'] ?? basePrice.toInt();
    final distSurcharge = breakdown?['distance_surcharge'] ?? 0;
    final urgencyMult =
        (breakdown?['urgency_multiplier'] ?? 1.0).toStringAsFixed(1);
    final complexMult =
        (breakdown?['complexity_multiplier'] ?? 1.0).toStringAsFixed(1);
    final loyalty = breakdown?['loyalty_discount'] ?? 0;
    final perSession =
        (finalPrice ?? basePrice).toInt();
    final total = perSession * sessionsCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row('Base Rate', 'Rs $base'),
          _row('Distance Surcharge', 'Rs $distSurcharge'),
          _row('Urgency Multiplier', '× $urgencyMult'),
          _row('Complexity Multiplier', '× $complexMult'),
          if (loyalty > 0) _row('Loyalty Discount', '− Rs $loyalty'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _row(
            'Per Session',
            'Rs $perSession',
            isBold: true,
          ),
          const SizedBox(height: 4),
          _row(
            'Total ($sessionsCount sessions)',
            'Rs $total',
            isBold: true,
            color: const Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, Color color = const Color(0xFF4B5563)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
