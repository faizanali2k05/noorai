import 'package:flutter/material.dart';
import '../models/therapist.dart';
import 'booking_confirmation_screen.dart';

class ProviderDetailScreen extends StatelessWidget {
  final Therapist therapist;

  const ProviderDetailScreen({super.key, required this.therapist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        title: const Text('Details', style: TextStyle(color: Color(0xFF134E4A))),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Icon(therapist.gender == 'female' ? Icons.woman : Icons.man, color: const Color(0xFF0284C7), size: 50),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        therapist.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      if (therapist.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.verified, color: Colors.blue, size: 24),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    therapist.specializations.join(', ').replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF0D9488),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF0D9488),
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'Price'),
                    ],
                  ),
                  SizedBox(
                    height: 350,
                    child: TabBarView(
                      children: [
                        _buildOverviewTab(),
                        const Center(child: Text("Reviews coming soon")),
                        const Center(child: Text("Schedule coming soon")),
                        _buildPriceTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingConfirmationScreen(therapist: therapist)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(therapist.bio, style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563), height: 1.5)),
          const SizedBox(height: 24),
          const Text('Qualifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          ...therapist.qualifications.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q, style: const TextStyle(color: Color(0xFF4B5563)))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPriceTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transparent Pricing Agent Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _priceRow('Base Rate', 'Rs ${therapist.basePrice}'),
                _priceRow('Distance Surcharge', 'Rs 0'),
                _priceRow('Urgency Multiplier', 'x 1.0'),
                _priceRow('Complexity Multiplier', 'x 1.2'),
                const Divider(height: 24),
                _priceRow('Per Session', 'Rs ${therapist.finalPrice}', isBold: true),
                _priceRow('Total (2 sessions)', 'Rs ${(therapist.finalPrice ?? 0) * 2}', isBold: true, color: const Color(0xFF0D9488)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false, Color color = const Color(0xFF4B5563)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
