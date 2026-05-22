import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import 'provider_list_screen.dart';
import 'dispute_screen.dart';
import 'baseline_compare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();

  static const List<String> _samples = [
    "5 saal ke bete ko speech therapist chahiye Gulberg Lahore",
    "Autism wali beti 7 saal F-8 Islamabad ABA therapist",
    "Physical disability ke liye accessible transport DHA Karachi",
    "Behray bhai ke liye sign language interpreter Islamabad",
    "Disabled ammi ke liye home nurse urgently needed Gulberg",
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;
    // Dismiss the keyboard before the page transition so the layout doesn't
    // resize mid-animation (a common source of janky transitions).
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderListScreen(userQuery: query),
      ),
    );
  }

  void _fillSample(String text) {
    setState(() {
      _promptController.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6), // Soft elegant off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF01411C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Color(0xFF0E7C42)),
            tooltip: 'AI vs Traditional',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BaselineCompareScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF0E7C42)),
            tooltip: 'Dispute / Help',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DisputeScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: NoorColors.brand,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: SvgPicture.asset(
                                    'assets/master/noorai-mark-white.svg',
                                    width: 64,
                                    height: 64),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'NoorAI',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: NoorColors.primaryDeepest,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pakistan's first AI therapist marketplace\nfor special needs families",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(
                                begin: 0.18,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutCubic),
                        const SizedBox(height: 48),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _promptController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText:
                                  "Apne bachay ke liye therapist describe karen...",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideY(
                                begin: 0.12,
                                end: 0,
                                delay: 150.ms,
                                duration: 550.ms,
                                curve: Curves.easeOutCubic),
                        const SizedBox(height: 24),
                        const Text(
                          "Try these examples:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E7C42),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < _samples.length; i++)
                              _buildSampleChip(_samples[i])
                                  .animate()
                                  .fadeIn(
                                      delay: (300 + i * 90).ms,
                                      duration: 400.ms)
                                  .slideX(
                                      begin: 0.15,
                                      end: 0,
                                      delay: (300 + i * 90).ms,
                                      duration: 450.ms,
                                      curve: Curves.easeOut),
                          ],
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Find Therapist',
                          icon: Icons.arrow_forward_rounded,
                          height: 56,
                          onPressed: _search,
                        )
                            .animate()
                            .fadeIn(delay: 850.ms, duration: 500.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                delay: 850.ms,
                                duration: 550.ms,
                                curve: Curves.easeOutCubic),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            "🇵🇰 350,000+ children in Pakistan need therapy.\nMost families search on Facebook.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.5,
                            ),
                          ),
                        ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildSampleChip(String text) {
    return GestureDetector(
      onTap: () => _fillSample(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE4F5EC).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7D7BD)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0A5C30),
          ),
        ),
      ),
    );
  }
}
