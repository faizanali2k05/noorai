import 'package:flutter/material.dart';

class DisputeScreen extends StatelessWidget {
  const DisputeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF01411C)),
        title: const Text('Dispute & Help', style: TextStyle(color: Color(0xFF01411C))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Need help with your booking?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Our Dispute Agent will automatically resolve issues or rebook you.",
              style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 32),
            _buildDisputeCard(
              context,
              'Therapist Cancelled',
              'Trigger Dispute Agent to find an immediate replacement for the same slot.',
              Icons.event_busy,
              true,
            ),
            _buildDisputeCard(
              context,
              'Therapist No-Show',
              'Report that the therapist did not arrive at the scheduled time.',
              Icons.person_off,
              false,
            ),
            _buildDisputeCard(
              context,
              'Price Dispute',
              'The therapist requested a different amount than the Pricing Agent calculated.',
              Icons.price_change,
              false,
            ),
            _buildDisputeCard(
              context,
              'Service Complaint',
              'Report an issue with the quality of the therapy session.',
              Icons.report_problem,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeCard(BuildContext context, String title, String subtitle, IconData icon, bool isStressTest) {
    return GestureDetector(
      onTap: () {
        if (isStressTest) {
          _showCancellationStressTest(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute reported.')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isStressTest ? const Color(0xFF0E7C42) : Colors.grey.shade200, width: isStressTest ? 2 : 1),
          boxShadow: [
            if (isStressTest)
              BoxShadow(color: const Color(0xFF0E7C42).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isStressTest ? const Color(0xFF0E7C42).withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isStressTest ? const Color(0xFF0E7C42) : Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isStressTest ? const Color(0xFF0E7C42) : const Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCancellationStressTest(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.autorenew, color: Color(0xFF0E7C42)),
                SizedBox(width: 8),
                Text('Dispute Agent Activated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01411C))),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Dr. Ayesha Khan had to cancel. We found a verified alternative for the exact same slot:",
              style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. Sara Ahmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('4.7★ · 3.1km · M.Phil Verified', style: TextStyle(color: Colors.black87)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('Same slot available', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text('+ 10% discount applied for inconvenience', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rebooked successfully!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E7C42)),
                    child: const Text('Confirm Rebook', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
