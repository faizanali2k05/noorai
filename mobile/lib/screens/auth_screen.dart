import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _api = ApiService();

  final _loginEmail = TextEditingController();
  final _loginPw = TextEditingController();

  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPw = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _obscureLogin = true;
  bool _obscureSignup = true;
  bool _rememberMe = true;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPw.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPw.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final email = _loginEmail.text.trim();
    final pw = _loginPw.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _api.login(email: email, password: pw, remember: _rememberMe);
      await AuthService.instance
          .setSession(r.token, r.refreshToken, r.user, remember: _rememberMe);
      if (!mounted) return;
      _routeAfterAuth();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doSignup() async {
    final name = _signupName.text.trim();
    final email = _signupEmail.text.trim();
    final pw = _signupPw.text;
    if (name.isEmpty || email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Please fill all fields.');
      return;
    }
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pw.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _api.register(email: email, password: pw, name: name);
      await AuthService.instance
          .setSession(r.token, r.refreshToken, r.user, remember: true);
      if (!mounted) return;
      _routeAfterAuth();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _routeAfterAuth() {
    final p = AuthService.instance.profile;
    final next = (p?.onboardingComplete ?? false)
        ? const MainShell()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  String _friendly(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NoorColors.brand,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: SvgPicture.asset(
                          'assets/master/noorai-mark-white.svg',
                          width: 56,
                          height: 56),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to NoorAI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: NoorColors.primaryDeepest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find the right therapist for your child',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: NoorColors.tealSoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: NoorColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: NoorColors.primaryDark,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Sign in'),
                    Tab(text: 'Create account'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tab,
                  children: [_buildLoginForm(), _buildSignupForm()],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: NoorColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: NoorColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPw,
          obscureText: _obscureLogin,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureLogin
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  activeColor: NoorColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Remember me',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Sign in',
          busy: _busy,
          onPressed: _busy ? null : _doLogin,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        TextField(
          controller: _signupName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupPw,
          obscureText: _obscureSignup,
          decoration: InputDecoration(
            hintText: 'Password (min 8 characters)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureSignup
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Create account',
          busy: _busy,
          onPressed: _busy ? null : _doSignup,
        ),
      ],
    );
  }
}
