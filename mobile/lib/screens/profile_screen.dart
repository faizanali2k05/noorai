import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final p = AuthService.instance.profile;
    if (p == null) return;
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(profile: p),
      ),
    );
    if (updated != null) {
      await AuthService.instance.updateProfile(updated);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign in again to see your bookings."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: NoorColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthService.instance.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: p == null
          ? const Center(
              child: CircularProgressIndicator(color: NoorColors.primary))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildHeader(p),
                const SizedBox(height: 24),
                _section('Your child'),
                _row(Icons.child_care, 'Name', p.childName ?? '—'),
                _row(Icons.cake_outlined, 'Age',
                    p.childAge == null ? '—' : '${p.childAge} years'),
                _row(Icons.medical_services_outlined, 'Needs',
                    p.childCondition ?? '—'),
                const SizedBox(height: 16),
                _section('Location'),
                _row(Icons.location_city, 'City', p.city ?? '—'),
                _row(Icons.place_outlined, 'Area',
                    (p.area?.isNotEmpty ?? false) ? p.area! : '—'),
                const SizedBox(height: 16),
                _section('Contact'),
                _row(Icons.mail_outline, 'Email', p.email),
                _row(Icons.phone_outlined, 'Phone',
                    (p.phone?.isNotEmpty ?? false) ? p.phone! : '—'),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: NoorColors.danger),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(color: NoorColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'NoorAI v1.0 · For families who deserve better.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(UserProfile p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NoorColors.primary, NoorColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              p.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name.isEmpty ? 'Welcome' : p.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NoorColors.primaryDark),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NoorColors.primaryDeepest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const _EditProfileScreen({required this.profile});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _api = ApiService();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _childName;
  late final TextEditingController _area;
  late int? _childAge;
  late String? _condition;
  late String? _city;
  bool _busy = false;

  static const _conditions = [
    'Autism / ASD', 'ADHD', 'Speech delay', 'Developmental delay',
    'Down syndrome', 'Learning difficulty', 'Behavioral issues', 'Other',
  ];
  static const _cities = [
    'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi',
    'Faisalabad', 'Multan', 'Peshawar', 'Quetta', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone ?? '');
    _childName = TextEditingController(text: p.childName ?? '');
    _area = TextEditingController(text: p.area ?? '');
    _childAge = p.childAge;
    _condition = p.childCondition;
    _city = p.city;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _childName.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final updated = await _api.updateProfile({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'child_name': _childName.text.trim(),
        'child_age': _childAge,
        'child_condition': _condition,
        'city': _city,
        'area': _area.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: NoorColors.primary, strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label('Your name'),
          TextField(controller: _name),
          const SizedBox(height: 14),
          _label('Phone'),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+92 …'),
          ),
          const SizedBox(height: 14),
          _label("Child's name"),
          TextField(controller: _childName),
          const SizedBox(height: 14),
          _label("Child's age"),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(16, (i) => i + 1).map((a) {
              final sel = _childAge == a;
              return ChoiceChip(
                label: Text('$a'),
                selected: sel,
                showCheckmark: false,
                selectedColor: NoorColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : NoorColors.primaryDark,
                ),
                backgroundColor: NoorColors.tealSoft,
                onSelected: (_) => setState(() => _childAge = a),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('Condition'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _conditions.map((c) {
              final sel = _condition == c;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                showCheckmark: false,
                selectedColor: NoorColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : NoorColors.primaryDark,
                ),
                backgroundColor: NoorColors.tealSoft,
                onSelected: (_) => setState(() => _condition = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('City'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _cities.map((c) {
              final sel = _city == c;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                showCheckmark: false,
                selectedColor: NoorColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : NoorColors.primaryDark,
                ),
                backgroundColor: NoorColors.tealSoft,
                onSelected: (_) => setState(() => _city = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('Area / locality'),
          TextField(
            controller: _area,
            decoration: const InputDecoration(hintText: 'Gulberg, DHA, F-8…'),
          ),
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          s,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700),
        ),
      );
}
