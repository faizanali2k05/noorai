import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/service_category.dart';
import 'service_search_screen.dart';

/// "More Services" tab — the core NoorAI experience is special-needs therapy
/// (Find tab); this screen exposes the wider informal-economy services
/// (plumber, electrician, AC technician, tutor, beautician, …).
class ServicesScreen extends StatelessWidget {
  final VoidCallback? onGoToFind;

  const ServicesScreen({super.key, this.onGoToFind});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorColors.background,
      appBar: AppBar(
        title: const Text('Services'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _CoreCard(onTap: onGoToFind)
              .animate()
              .fadeIn(duration: 450.ms)
              .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic),
          const SizedBox(height: 28),
          Row(
            children: [
              const Text(
                'More services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NoorColors.primaryDeepest,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '· trusted providers near you',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              for (int i = 0; i < kServiceCategories.length; i++)
                _CategoryCard(category: kServiceCategories[i])
                    .animate()
                    .fadeIn(delay: (i * 60).ms, duration: 350.ms)
                    .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        delay: (i * 60).ms,
                        duration: 350.ms,
                        curve: Curves.easeOut),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoreCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _CoreCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NoorColors.brand,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Special Needs Therapy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('CORE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'AI-matched, verified therapists for speech, autism, ABA, OT and more — described in your own words.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Find a therapist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.9), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NoorColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceSearchScreen(category: category),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EFE8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NoorColors.greenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon,
                    color: NoorColors.primary, size: 22),
              ),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NoorColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
