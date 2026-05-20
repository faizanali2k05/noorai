import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'provider_list_screen.dart';
import 'dispute_screen.dart';
import 'baseline_compare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _search() {
    if (_promptController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simulate small network delay for smooth UI transition
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderListScreen(
              userQuery: _promptController.text,
            ),
          ),
        );
      }
    });
  }

  void _fillSample(String text) {
    setState(() {
      _promptController.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // Soft elegant off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E4A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Color(0xFF0D9488)),
            tooltip: 'AI vs Traditional',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BaselineCompareScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF0D9488)),
            tooltip: 'Dispute / Help',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DisputeScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      SvgPicture.asset('assets/noorai_logo.svg', width: 72, height: 72),
                      const SizedBox(height: 16),
                      const Text(
                        'NoorAI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF134E4A),
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
                ),
                const SizedBox(height: 60),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                      hintText: "Apne bachay ke liye therapist describe karen...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Try these examples:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSampleChip("5 saal ke bete ko speech therapist chahiye Gulberg Lahore"),
                    _buildSampleChip("Autism wali beti 7 saal F-8 Islamabad ABA therapist"),
                    _buildSampleChip("Physical disability ke liye accessible transport DHA Karachi"),
                    _buildSampleChip("Behray bhai ke liye sign language interpreter Islamabad"),
                    _buildSampleChip("Disabled ammi ke liye home nurse urgently needed Gulberg"),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Find Therapist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
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
                ),
                const SizedBox(height: 32),
              ],
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
          color: const Color(0xFFCCFBF1).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF99F6E4)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0F766E),
          ),
        ),
      ),
    );
  }
}
