import 'package:flutter/material.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text('Follow-Up Agent Timeline', style: TextStyle(color: Color(0xFF134E4A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildTimelineItem(Icons.schedule, 'Session Reminder', '1 Hour Before Session 1', 'Scheduled'),
          _buildTimelineItem(Icons.rate_review, 'Post-Session Feedback', '30 Min After Session 1', 'Scheduled'),
          _buildTimelineItem(Icons.schedule, 'Session Reminder', '1 Hour Before Session 2', 'Scheduled'),
          _buildTimelineItem(Icons.insights, 'Progress Digest', 'After 4 Sessions', 'Pending'),
          _buildTimelineItem(Icons.autorenew, 'Renewal Nudge', 'After Session 8', 'Pending'),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String title, String time, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Scheduled' ? const Color(0xFFD1FAE5) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'Scheduled' ? const Color(0xFF065F46) : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
