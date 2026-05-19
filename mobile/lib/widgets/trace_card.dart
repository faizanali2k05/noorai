import 'package:flutter/material.dart';
import '../models/trace_entry.dart';

const Map<String, String> _agentEmoji = {
  'Intent Agent': '🧠',
  'Discovery Agent': '🔍',
  'Ranking Agent': '⚖️',
  'Pricing Agent': '💰',
  'Booking Agent': '📅',
  'Notification Agent': '📱',
  'Follow-Up Agent': '🔔',
  'Dispute Agent': '⚡',
};

class TraceCard extends StatelessWidget {
  final TraceEntry entry;

  const TraceCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final emoji = _agentEmoji[entry.agent] ?? '🤖';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$emoji ${entry.agent}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.durationLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (entry.inputSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLabel('Input'),
            const SizedBox(height: 2),
            Text(
              entry.inputSummary,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 8),
          _buildLabel('Reasoning'),
          const SizedBox(height: 2),
          Text(
            entry.reasoning,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF374151), height: 1.4),
          ),
          if (entry.outputSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLabel('Output'),
            const SizedBox(height: 2),
            Text(
              entry.outputSummary,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF059669),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }
}

class HandoffArrow extends StatelessWidget {
  final String dataSummary;

  const HandoffArrow({super.key, required this.dataSummary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          const Icon(Icons.arrow_downward_rounded,
              color: Color(0xFF0D9488), size: 20),
          const SizedBox(height: 2),
          Text(
            dataSummary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF0D9488),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.arrow_downward_rounded,
              color: Color(0xFF0D9488), size: 20),
        ],
      ),
    );
  }
}
