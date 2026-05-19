import 'package:flutter/material.dart';

class ScoreBar extends StatelessWidget {
  final String label;
  final double score;

  const ScoreBar({super.key, required this.label, required this.score});

  Color get _barColor {
    if (score >= 0.8) return const Color(0xFF10B981);
    if (score >= 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
              Text(
                '${(score * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: _barColor,
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}
