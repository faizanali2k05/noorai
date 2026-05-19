import 'package:flutter/material.dart';

class FollowupScreen extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const FollowupScreen({super.key, this.events = const []});

  @override
  Widget build(BuildContext context) {
    final items = events.isNotEmpty ? events : _defaultEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text('Follow-Up Agent Timeline',
            style: TextStyle(color: Color(0xFF134E4A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Follow-Up Agent has scheduled 5 automated events for your therapy journey.',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF065F46)),
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((e) =>
              _buildItem(e.key, e.value, isLast: e.key == items.length - 1)),
        ],
      ),
    );
  }

  Widget _buildItem(int index, Map<String, dynamic> event,
      {bool isLast = false}) {
    final type = event['type'] as String? ?? '';
    final trigger = event['trigger'] as String? ?? '';
    final preview = event['message_preview'] as String? ??
        event['prompt'] as String? ??
        event['summary'] as String? ??
        '';

    final config = _config(type);
    final status = index == 0 ? 'Scheduled' : 'Pending';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config['bg'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(config['icon'] as IconData,
                    color: config['color'] as Color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
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
                        Expanded(
                          child: Text(
                            config['label'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1F2937)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status == 'Scheduled'
                                ? const Color(0xFFD1FAE5)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: status == 'Scheduled'
                                  ? const Color(0xFF065F46)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trigger.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _config(String type) {
    switch (type) {
      case 'session_reminder':
        return {
          'icon': Icons.alarm,
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFE0F2FE),
          'label': 'Session Reminder',
        };
      case 'post_session_feedback':
        return {
          'icon': Icons.rate_review_outlined,
          'color': const Color(0xFF7C3AED),
          'bg': const Color(0xFFEDE9FE),
          'label': 'Post-Session Feedback',
        };
      case 'progress_digest':
        return {
          'icon': Icons.insights,
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFD1FAE5),
          'label': 'Progress Digest',
        };
      case 'renewal_nudge':
        return {
          'icon': Icons.autorenew,
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'label': 'Renewal Nudge',
        };
      default:
        return {
          'icon': Icons.notifications_outlined,
          'color': const Color(0xFF6B7280),
          'bg': Colors.grey.shade100,
          'label': type.replaceAll('_', ' '),
        };
    }
  }

  static const List<Map<String, dynamic>> _defaultEvents = [
    {
      'type': 'session_reminder',
      'trigger': '1_hour_before',
      'target_session': 1,
      'message_preview': 'Dr. Ayesha 1 ghante mein aa rahi hain. Ghar tayyar rakhen!',
    },
    {
      'type': 'post_session_feedback',
      'trigger': '30_min_after',
      'target_session': 1,
      'prompt': 'Session kaisi rahi? 1-5 rate karen aur notes share karen.',
    },
    {
      'type': 'session_reminder',
      'trigger': '1_hour_before',
      'target_session': 2,
      'message_preview': 'Reminder: Kal 22 May 4:00 PM session hai. Confirmation: NA-AYK-4291',
    },
    {
      'type': 'progress_digest',
      'trigger': 'after_4_sessions',
      'summary': 'Monthly progress check — 4 sessions completed. Review goals and therapist performance.',
    },
    {
      'type': 'renewal_nudge',
      'trigger': 'after_session_8',
      'message_preview': 'Therapy package complete ho rahi hai. Continue karein? Rs 3,360/session',
    },
  ];
}
