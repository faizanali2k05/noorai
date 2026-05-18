import 'package:flutter/material.dart';
import '../models/therapist.dart';
import 'followup_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Therapist therapist;

  const BookingConfirmationScreen({super.key, required this.therapist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF134E4A))),
              const SizedBox(height: 8),
              const Text('TC-AYK-4291', style: TextStyle(fontSize: 18, color: Color(0xFF0D9488), fontWeight: FontWeight.w600, letterSpacing: 2)),
              const SizedBox(height: 32),
              
              // Simulated WhatsApp Widget
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF075E54), // WhatsApp Green
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mark_chat_unread, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('NoorAI Bot (Notification Agent)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5DDD5), // WhatsApp Chat Background
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Salam! Aap ka booking confirm ho gaya hai. ${therapist.name} (${therapist.specializations.first.replaceAll('_', ' ')}) kal 19 May, 4:00 PM ko aap ke ghar aayengi. Confirmation: TC-AYK-4291",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FollowupScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('View Follow-Up Schedule', style: TextStyle(fontSize: 16, color: Color(0xFF0D9488))),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
