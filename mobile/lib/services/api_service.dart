import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/therapist.dart';
import '../models/booking.dart';
import '../models/trace_entry.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../models/service_provider.dart';
import '../models/service_booking.dart';
import 'auth_service.dart';

class FindResult {
  final List<Therapist> therapists;
  final String traceId;
  final Map<String, dynamic> intent;

  FindResult({
    required this.therapists,
    required this.traceId,
    required this.intent,
  });
}

class BookingResult {
  final Booking booking;
  final String traceId;
  final String parentNotification;
  final List<Map<String, dynamic>> followupEvents;

  BookingResult({
    required this.booking,
    required this.traceId,
    required this.parentNotification,
    required this.followupEvents,
  });
}

class ApiService {
  // Android emulator: 10.0.2.2 â†’ host machine
  // Real device: your PC's local IP (e.g. 192.168.1.x)
  // Deployed: your Cloud Run / Render URL (e.g. https://noorai-backend-xxx.run.app/api)
  // NOTE: must end with /api (no trailing slash) â€” all routes live under /api/*.
  static const String baseUrl =
      'https://noorai-backend-485583022901.asia-south1.run.app/api';

  static String get _origin {
    // Strip the trailing /api so we can build absolute URLs to /api/voice-notes/...
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  /// Turn a server-relative URL like "/api/voice-notes/abc.m4a" into an
  /// absolute URL the device can reach.
  static String absoluteUrl(String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http')) return relativeOrAbsolute;
    if (relativeOrAbsolute.startsWith('/')) return '$_origin$relativeOrAbsolute';
    return '$_origin/$relativeOrAbsolute';
  }

  Map<String, String> _authHeaders({bool json = true}) {
    final token = AuthService.instance.token;
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Run an authenticated request; if it returns 401, transparently refresh the
  /// access token once and retry. Keeps users logged in without re-prompting.
  Future<http.Response> _retryOn401(
      Future<http.Response> Function() send) async {
    var resp = await send();
    if (resp.statusCode == 401 && await _silentRefresh()) {
      resp = await send();
    }
    return resp;
  }

  /// Exchange the stored refresh token for a fresh access token. Returns false
  /// if there is no refresh token or it has expired (caller should sign out).
  Future<bool> _silentRefresh() async {
    final rt = AuthService.instance.refreshToken;
    if (rt == null) return false;
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': rt}),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        await AuthService.instance
            .updateTokens(data['token'] as String, data['refresh_token'] as String);
        return true;
      }
      if (r.statusCode == 401 || r.statusCode == 403) {
        // Refresh token is genuinely expired/revoked — end the session.
        await AuthService.instance.logout();
      }
    } catch (e) {
      // Network/timeout: keep the session so the user stays logged in offline.
      debugPrint('[ApiService] silent refresh failed: $e');
    }
    return false;
  }

  /// Refresh the session on app start. Returns true if a valid session remains.
  Future<bool> refreshSession() => _silentRefresh();

  /// Revoke the current session server-side, then it is safe to clear locally.
  Future<void> logoutServer() async {
    final rt = AuthService.instance.refreshToken;
    try {
      await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: _authHeaders(),
            body: jsonEncode({'refresh_token': rt}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ApiService] logout request failed (ignored): $e');
    }
  }

  // â”€â”€ Find therapists pipeline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<FindResult> findTherapists(String userMessage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/find-therapists'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_message': userMessage}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend returns 'ranked' (not 'ranked_therapists')
        final ranked = (data['ranked'] as List<dynamic>? ?? []);
        final therapists = ranked
            .map((j) => Therapist.fromJson(j as Map<String, dynamic>))
            .toList();
        return FindResult(
          therapists: therapists,
          traceId: data['trace_id'] as String? ?? '',
          intent: data['intent'] as Map<String, dynamic>? ?? {},
        );
      }
      throw _httpError(response);
    } on Exception {
      rethrow;
    } catch (e) {
      // Network / timeout / parse failures â€” surface a clean message, no mock.
      debugPrint('[ApiService] findTherapists failed: $e');
      throw Exception(_networkMessage(e));
    }
  }

  // â”€â”€ Book a therapist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<BookingResult> bookTherapist({
    required String therapistId,
    required String slot,
    required Map<String, dynamic> intent,
    int sessionsCount = 2,
    String? traceId,
  }) async {
    try {
      final response = await _retryOn401(() => http
          .post(
            Uri.parse('$baseUrl/book'),
            headers: _authHeaders(),
            body: jsonEncode({
              'therapist_id': therapistId,
              'slot': slot,
              'intent': intent,
              'sessions_count': sessionsCount,
              'trace_id': traceId,
            }),
          )
          .timeout(const Duration(seconds: 25)));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final booking = Booking.fromJson(data['booking'] as Map<String, dynamic>);
        final notifs = data['notifications'] as Map<String, dynamic>? ?? {};
        final toParent = notifs['to_parent'] as Map<String, dynamic>? ?? {};
        final followup = data['followup'] as Map<String, dynamic>? ?? {};
        final events = (followup['scheduled_events'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        return BookingResult(
          booking: booking,
          traceId: data['trace_id'] as String? ?? traceId ?? '',
          parentNotification: toParent['message'] as String? ?? '',
          followupEvents: events,
        );
      }
      throw _httpError(response);
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] bookTherapist failed: $e');
      throw Exception(_networkMessage(e));
    }
  }

  // â”€â”€ Agent trace â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<TraceLog?> getTrace(String traceId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/trace/$traceId'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return TraceLog.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] getTrace: $e');
      return null;
    }
  }

  // â”€â”€ Baseline compare â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>?> getBaselineComparison(
      String userMessage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/baseline-compare'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_message': userMessage}),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] getBaselineComparison: $e');
      return null;
    }
  }

  // ── General home services (plumber, electrician, AC, tutor, …) ────────────

  Future<ServiceFindResult> findServices(String userMessage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/find-services'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_message': userMessage}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ranked = (data['ranked'] as List<dynamic>? ?? []);
        return ServiceFindResult(
          providers: ranked
              .map((j) => ServiceProvider.fromJson(j as Map<String, dynamic>))
              .toList(),
          traceId: data['trace_id'] as String? ?? '',
          intent: data['intent'] as Map<String, dynamic>? ?? {},
        );
      }
      throw _httpError(response);
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] findServices failed: $e');
      throw Exception(_networkMessage(e));
    }
  }

  Future<ServiceBookingResult> bookService({
    required String providerId,
    String? slot,
    required Map<String, dynamic> intent,
    String? traceId,
  }) async {
    try {
      final response = await _retryOn401(() => http
          .post(
            Uri.parse('$baseUrl/book-service'),
            headers: _authHeaders(),
            body: jsonEncode({
              'provider_id': providerId,
              'slot': slot,
              'intent': intent,
              'trace_id': traceId,
            }),
          )
          .timeout(const Duration(seconds: 25)));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notifs = data['notifications'] as Map<String, dynamic>? ?? {};
        final toUser = notifs['to_user'] as Map<String, dynamic>? ?? {};
        final followup = data['followup'] as Map<String, dynamic>? ?? {};
        final events = (followup['scheduled_events'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        return ServiceBookingResult(
          booking: ServiceBooking.fromJson(
              data['booking'] as Map<String, dynamic>),
          traceId: data['trace_id'] as String? ?? traceId ?? '',
          userMessage: toUser['message'] as String? ?? '',
          followupEvents: events,
        );
      }
      throw _httpError(response);
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] bookService failed: $e');
      throw Exception(_networkMessage(e));
    }
  }

  // â”€â”€ Dispute â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>?> submitDispute({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/dispute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'booking_id': bookingId, 'reason': reason}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] submitDispute: $e');
      return null;
    }
  }

  // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<({UserProfile user, String token, String refreshToken})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'name': name}),
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (
        user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
        token: data['token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
    }
    throw _httpError(r);
  }

  Future<({UserProfile user, String token, String refreshToken})> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'email': email, 'password': password, 'remember': remember}),
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (
        user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
        token: data['token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
    }
    throw _httpError(r);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> patch) async {
    final r = await _retryOn401(() => http
        .patch(
          Uri.parse('$baseUrl/auth/me'),
          headers: _authHeaders(),
          body: jsonEncode(patch),
        )
        .timeout(const Duration(seconds: 20)));
    if (r.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw _httpError(r);
  }

  // â”€â”€ Bookings list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<List<Booking>> listMyBookings() async {
    try {
      final r = await _retryOn401(() => http
          .get(Uri.parse('$baseUrl/bookings'), headers: _authHeaders(json: false))
          .timeout(const Duration(seconds: 15)));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return (data['bookings'] as List<dynamic>? ?? [])
            .map((b) => Booking.fromJson(b as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // â”€â”€ Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<List<Map<String, dynamic>>> listChatThreads() async {
    try {
      final r = await _retryOn401(() => http
          .get(Uri.parse('$baseUrl/chats'), headers: _authHeaders(json: false))
          .timeout(const Duration(seconds: 15)));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return (data['threads'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ChatMessage>> listMessages(String therapistId) async {
    try {
      final r = await _retryOn401(() => http
          .get(
            Uri.parse('$baseUrl/chats/$therapistId'),
            headers: _authHeaders(json: false),
          )
          .timeout(const Duration(seconds: 15)));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return (data['messages'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ChatMessage?> sendText(String therapistId, String text) async {
    try {
      final r = await _retryOn401(() => http
          .post(
            Uri.parse('$baseUrl/chats/$therapistId'),
            headers: _authHeaders(),
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 15)));
      if (r.statusCode == 200) {
        return ChatMessage.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ChatMessage?> sendVoiceNote({
    required String therapistId,
    required String filePath,
    required int durationMs,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chats/$therapistId/voice');
      final req = http.MultipartRequest('POST', uri);
      final token = AuthService.instance.token;
      if (token != null) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.fields['duration_ms'] = durationMs.toString();
      final file = File(filePath);
      final filename = filePath.split(Platform.pathSeparator).last;
      req.files.add(http.MultipartFile.fromBytes(
        'voice',
        await file.readAsBytes(),
        filename: filename,
        contentType: MediaType('audio', 'mp4'),
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final r = await http.Response.fromStream(streamed);
      if (r.statusCode == 200) {
        return ChatMessage.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Exception _httpError(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      final detail = body is Map ? body['detail'] : null;
      return Exception(detail?.toString() ?? 'Request failed (${r.statusCode})');
    } catch (_) {
      return Exception('Request failed (${r.statusCode})');
    }
  }

  /// Turn a low-level network/parse failure into a clean, user-facing message.
  String _networkMessage(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) {
      return 'The request timed out. Please check your connection and try again.';
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Could not reach the NoorAI server. Please check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
