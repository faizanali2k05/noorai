import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/service_category.dart';
import '../widgets/primary_button.dart';
import 'service_results_screen.dart';

/// Lets the user describe a general service need in natural language. The
/// field is pre-filled with a category-specific example they can edit.
class ServiceSearchScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceSearchScreen({super.key, required this.category});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.category.hint);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceResultsScreen(userQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Scaffold(
      backgroundColor: NoorColors.background,
      appBar: AppBar(title: Text(c.label)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: NoorColors.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(c.icon, color: NoorColors.primary, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Describe what you need',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NoorColors.primaryDeepest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type in Urdu, Roman Urdu or English — include your area and time.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Find providers',
                icon: Icons.search_rounded,
                height: 56,
                onPressed: _search,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
