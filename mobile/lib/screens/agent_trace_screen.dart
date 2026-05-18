import 'package:flutter/material.dart';

class AgentTraceScreen extends StatelessWidget {
  const AgentTraceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text('How NoorAI Decided', style: TextStyle(color: Color(0xFF134E4A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "7 Antigravity Agents completed in 2.3s",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildAgentCard("🧠 Intent Agent", "0.4s", "Detected Roman Urdu. Extracted service=speech_therapy, age=5, city=Lahore, budget=3000.\nConfidence: 0.94"),
          _buildHandoffArrow("{ service: speech_therapy, city: Lahore, age: 5 }"),
          
          _buildAgentCard("🔍 Discovery Agent", "0.2s", "Filtered 30 mock therapists down to 12 candidates matching city and specialization within 15km."),
          _buildHandoffArrow("{ 12 candidates found }"),
          
          _buildAgentCard("⚖️ Ranking Agent", "0.6s", "Applied 8-factor formula. Dr. Ayesha Khan scored highest due to exact specialization match, M.Phil verification, and optimal pricing ratio."),
          _buildHandoffArrow("{ top 3 scored }"),
          
          _buildAgentCard("💰 Pricing Agent", "0.3s", "Computed dynamic price. Base: 2800. Distance surcharge: 0. Urgency (scheduled): x1.0. Complexity (autism): x1.2 = Rs 3360."),
          _buildHandoffArrow("{ prices calculated }"),
          
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Export JSON Trace', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF134E4A),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAgentCard(String title, String time, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
              Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }

  Widget _buildHandoffArrow(String dataPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          const Icon(Icons.arrow_downward, color: Color(0xFF0D9488)),
          Text(dataPassed, style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontStyle: FontStyle.italic)),
          const Icon(Icons.arrow_downward, color: Color(0xFF0D9488)),
        ],
      ),
    );
  }
}
