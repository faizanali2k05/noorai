import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Lightweight session manager. Persists token + cached profile.
/// Listeners can be added so the UI rebuilds when auth state changes.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _kToken = 'noorai_token';
  static const _kUserId = 'noorai_user_id';
  static const _kEmail = 'noorai_email';
  static const _kName = 'noorai_name';
  static const _kPhone = 'noorai_phone';
  static const _kChildName = 'noorai_child_name';
  static const _kChildAge = 'noorai_child_age';
  static const _kChildCondition = 'noorai_child_condition';
  static const _kCity = 'noorai_city';
  static const _kArea = 'noorai_area';

  String? _token;
  UserProfile? _profile;

  final List<void Function()> _listeners = [];

  String? get token => _token;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _token != null && _profile != null;

  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    final userId = prefs.getString(_kUserId);
    if (_token != null && userId != null) {
      _profile = UserProfile(
        userId: userId,
        email: prefs.getString(_kEmail) ?? '',
        name: prefs.getString(_kName) ?? '',
        phone: prefs.getString(_kPhone),
        childName: prefs.getString(_kChildName),
        childAge: prefs.getInt(_kChildAge),
        childCondition: prefs.getString(_kChildCondition),
        city: prefs.getString(_kCity),
        area: prefs.getString(_kArea),
        createdAt: '',
      );
    }
  }

  Future<void> setSession(String token, UserProfile profile) async {
    _token = token;
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await _writeProfile(prefs, profile);
    _notify();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _writeProfile(prefs, profile);
    _notify();
  }

  Future<void> _writeProfile(SharedPreferences prefs, UserProfile p) async {
    await prefs.setString(_kUserId, p.userId);
    await prefs.setString(_kEmail, p.email);
    await prefs.setString(_kName, p.name);
    Future<void> putOrRemove(String key, String? v) async {
      if (v == null || v.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, v);
      }
    }
    await putOrRemove(_kPhone, p.phone);
    await putOrRemove(_kChildName, p.childName);
    await putOrRemove(_kChildCondition, p.childCondition);
    await putOrRemove(_kCity, p.city);
    await putOrRemove(_kArea, p.area);
    if (p.childAge != null) {
      await prefs.setInt(_kChildAge, p.childAge!);
    } else {
      await prefs.remove(_kChildAge);
    }
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      _kToken, _kUserId, _kEmail, _kName, _kPhone,
      _kChildName, _kChildAge, _kChildCondition, _kCity, _kArea,
    ]) {
      await prefs.remove(k);
    }
    _notify();
  }
}
