import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  final _api = ApiService();

  int _page = 0;
  bool _busy = false;

  final _childName = TextEditingController();
  int? _childAge;
  String? _condition;
  String? _city;
  final _area = TextEditingController();

  static const _conditions = [
    'Autism / ASD',
    'ADHD',
    'Speech delay',
    'Developmental delay',
    'Down syndrome',
    'Learning difficulty',
    'Behavioral issues',
    'Other',
  ];

  static const _cities = [
    'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi',
    'Faisalabad', 'Multan', 'Peshawar', 'Quetta', 'Other',
  ];

  @override
  void dispose() {
    _pc.dispose();
    _childName.dispose();
    _area.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_page) {
      case 0:
        return _childName.text.trim().isNotEmpty && _childAge != null;
      case 1:
        return _condition != null;
      case 2:
        return _city != null;
      default:
        return false;
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final updated = await _api.updateProfile({
        'child_name': _childName.text.trim(),
        'child_age': _childAge,
        'child_condition': _condition,
        'city': _city,
        'area': _area.text.trim(),
      });
      await AuthService.instance.updateProfile(updated);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_page == 2) {
      _finish();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _page == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pc.previousPage(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                ),
              ),
        title: Text('Step ${_page + 1} of 3'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepChildInfo(),
                  _stepCondition(),
                  _stepLocation(),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!_canNext || _busy) ? null : _next,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_page == 2 ? 'Get started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _page;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? NoorColors.primary
                    : NoorColors.tealSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepShell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NoorColors.primaryDeepest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  Widget _stepChildInfo() {
    return _stepShell(
      title: 'Tell us about your child',
      subtitle: 'This helps us match the right therapist.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Child's name",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _childName,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Ali'),
          ),
          const SizedBox(height: 20),
          const Text("Age",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(16, (i) => i + 1).map((a) {
              final sel = _childAge == a;
              return ChoiceChip(
                label: Text('$a'),
                selected: sel,
                showCheckmark: false,
                selectedColor: NoorColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : NoorColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: NoorColors.tealSoft.withOpacity(0.5),
                side: BorderSide(
                    color: sel ? NoorColors.primary : NoorColors.tealOutline),
                onSelected: (_) => setState(() => _childAge = a),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _stepCondition() {
    return _stepShell(
      title: 'What kind of support is needed?',
      subtitle: 'Pick the closest match — you can refine later.',
      child: Column(
        children: _conditions.map((c) {
          final sel = _condition == c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _condition = c),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: sel ? NoorColors.tealSoft : Colors.white,
                  border: Border.all(
                    color: sel ? NoorColors.primary : Colors.grey.shade300,
                    width: sel ? 1.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: sel
                          ? NoorColors.primary
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: sel
                              ? NoorColors.primaryDeepest
                              : NoorColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _stepLocation() {
    return _stepShell(
      title: 'Where are you based?',
      subtitle: 'We use this to find nearby therapists.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("City", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cities.map((c) {
              final sel = _city == c;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                showCheckmark: false,
                selectedColor: NoorColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : NoorColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: NoorColors.tealSoft.withOpacity(0.5),
                side: BorderSide(
                    color: sel ? NoorColors.primary : NoorColors.tealOutline),
                onSelected: (_) => setState(() => _city = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text("Area / locality (optional)",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _area,
            decoration:
                const InputDecoration(hintText: 'e.g. Gulberg, DHA, F-8'),
          ),
        ],
      ),
    );
  }
}
