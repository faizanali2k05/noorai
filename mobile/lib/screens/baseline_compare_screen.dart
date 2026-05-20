import 'package:flutter/material.dart';

class BaselineCompareScreen extends StatelessWidget {
  const BaselineCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF01411C)),
        title: const Text('AI vs Traditional', style: TextStyle(color: Color(0xFF01411C))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Search Query", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    '"Mere bete ko speech delay hai 5 saal ka hai Gulberg Lahore mein hafte mein 2 baar 3000 budget"',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn('Traditional System', false)),
                const SizedBox(width: 16),
                Expanded(child: _buildColumn('NoorAI System', true)),
              ],
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "Same query. Smarter answer.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0E7C42)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(String title, bool isAi) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isAi ? const Color(0xFF0E7C42) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isAi ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCompareItem('Closest first (distance only)', '8-factor weighted scoring', isAi),
        _buildCompareItem('"Physiotherapist 800m away"', '"Dr. Ayesha 2.3km, speech specialist"', isAi),
        _buildCompareItem('Not specialized in speech', 'M.Phil speech-language pathology', isAi, isMatch: isAi),
        _buildCompareItem('No age range data', 'Specializes in preschool/school age', isAi, isMatch: isAi),
        _buildCompareItem('No price transparency', 'Full agentic price breakdown', isAi, isMatch: isAi),
        _buildCompareItem('No reasoning shown', 'Per-factor scores visible', isAi, isMatch: isAi),
      ],
    );
  }

  Widget _buildCompareItem(String trad, String ai, bool isAiColumn, {bool? isMatch}) {
    final text = isAiColumn ? ai : trad;
    
    Color bgColor = Colors.white;
    Color iconColor = Colors.grey;
    IconData? icon;

    if (isMatch != null) {
      if (isAiColumn && isMatch) {
        bgColor = const Color(0xFFECFDF5);
        iconColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
      } else if (!isAiColumn && !isMatch) {
        bgColor = const Color(0xFFFEF2F2);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.cancel;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMatch != null ? iconColor.withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMatch != null ? (isAiColumn ? const Color(0xFF065F46) : const Color(0xFF991B1B)) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
