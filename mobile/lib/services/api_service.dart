import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/therapist.dart';
import '../models/booking.dart';
import '../models/trace_entry.dart';

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
  // Android emulator: 10.0.2.2 → host machine
  // Real device: your PC's local IP (e.g. 192.168.1.x)
  // Deployed: your Render/Heroku URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ── Find therapists pipeline ──────────────────────────────────────────────

  Future<FindResult> findTherapists(String userMessage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/find-therapists'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_message': userMessage}),
          )
          .timeout(const Duration(seconds: 20));

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
      throw Exception('API ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('[ApiService] findTherapists: $e — falling back to mock');
      return _mockFindResult();
    }
  }

  // ── Book a therapist ──────────────────────────────────────────────────────

  Future<BookingResult> bookTherapist({
    required String therapistId,
    required String slot,
    required Map<String, dynamic> intent,
    int sessionsCount = 2,
    String? traceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/book'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'therapist_id': therapistId,
              'slot': slot,
              'intent': intent,
              'sessions_count': sessionsCount,
              'trace_id': traceId,
            }),
          )
          .timeout(const Duration(seconds: 25));

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
      throw Exception('Booking API ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('[ApiService] bookTherapist: $e — falling back to mock');
      return _mockBookingResult(therapistId);
    }
  }

  // ── Agent trace ───────────────────────────────────────────────────────────

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
      print('[ApiService] getTrace: $e');
      return null;
    }
  }

  // ── Baseline compare ──────────────────────────────────────────────────────

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
      print('[ApiService] getBaselineComparison: $e');
      return null;
    }
  }

  // ── Dispute ───────────────────────────────────────────────────────────────

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
      print('[ApiService] submitDispute: $e');
      return null;
    }
  }

  // ── Mock fallback data ────────────────────────────────────────────────────

  FindResult _mockFindResult() {
    return FindResult(
      traceId: 'mock-trace-001',
      intent: {
        'service_type': 'speech_therapy',
        'condition': 'speech_delay',
        'child_age': 5,
        'city': 'Lahore',
        'area': 'Gulberg',
        'budget_per_session': 3000,
        'frequency': 'biweekly',
        'urgency': 'scheduled',
        'confidence': 0.94,
      },
      therapists: [
        Therapist(
          id: 't001',
          name: 'Dr. Ayesha Khan',
          gender: 'female',
          specializations: ['speech_therapy', 'language_delay'],
          qualifications: ['M.Phil Speech-Language Pathology, KIBGE'],
          qualificationLevel: 'mphil',
          verified: true,
          city: 'Lahore',
          area: 'Gulberg',
          rating: 4.8,
          reviewCount: 64,
          lastReviewDaysAgo: 5,
          onTimeRate: 0.94,
          cancellationRate: 0.03,
          basePrice: 2800,
          ageRanges: ['preschool', 'school_age'],
          experienceYears: 4,
          availableSlots: [
            '2026-05-20T16:00:00',
            '2026-05-22T16:00:00',
            '2026-05-26T16:00:00',
            '2026-05-29T16:00:00',
          ],
          bio:
              'Specialized in pediatric speech-language therapy for children with autism and speech delays. 4 years of hands-on clinical experience.',
          languages: ['urdu', 'english', 'punjabi'],
          overallScore: 0.92,
          factorScores: {
            'specialization': 1.0,
            'age_range': 1.0,
            'qualifications': 1.0,
            'distance': 0.77,
            'rating': 0.90,
            'reliability': 0.94,
            'price': 0.93,
            'cancellation': 0.85,
          },
          reasoning:
              'Top match: M.Phil pediatric speech specialist, 2.3km away, 4.8★ with 64 reviews, 94% on-time rate, fits budget perfectly.',
          distanceKm: 2.3,
          finalPrice: 3360,
          nextAvailableSlot: '2026-05-20T16:00:00',
        ),
        Therapist(
          id: 't007',
          name: 'Dr. Sara Ahmed',
          gender: 'female',
          specializations: ['speech_therapy', 'behavioral_therapy'],
          qualifications: [
            'MSc Speech-Language Pathology',
            'ABA Level 1 Certified'
          ],
          qualificationLevel: 'masters',
          verified: true,
          city: 'Lahore',
          area: 'DHA',
          rating: 4.6,
          reviewCount: 42,
          lastReviewDaysAgo: 12,
          onTimeRate: 0.89,
          cancellationRate: 0.06,
          basePrice: 3000,
          ageRanges: ['preschool', 'school_age'],
          experienceYears: 3,
          availableSlots: [
            '2026-05-20T16:00:00',
            '2026-05-22T10:00:00',
            '2026-05-27T14:00:00',
          ],
          bio:
              'Focuses on behavioral interventions and speech clarity for children with developmental delays and autism spectrum disorders.',
          languages: ['urdu', 'english'],
          overallScore: 0.85,
          factorScores: {
            'specialization': 0.8,
            'age_range': 1.0,
            'qualifications': 0.85,
            'distance': 0.49,
            'rating': 0.8,
            'reliability': 0.89,
            'price': 0.9,
            'cancellation': 0.7,
          },
          reasoning:
              'Good match: MSc certified, slightly further at 5.1km, reliable record with 89% on-time rate.',
          distanceKm: 5.1,
          finalPrice: 3500,
          nextAvailableSlot: '2026-05-20T16:00:00',
        ),
        Therapist(
          id: 't012',
          name: 'Dr. Nadia Siddiqui',
          gender: 'female',
          specializations: ['speech_therapy', 'special_education'],
          qualifications: ['BSc Speech Therapy, Punjab University'],
          qualificationLevel: 'bachelors',
          verified: false,
          city: 'Lahore',
          area: 'Johar Town',
          rating: 4.2,
          reviewCount: 21,
          lastReviewDaysAgo: 20,
          onTimeRate: 0.82,
          cancellationRate: 0.10,
          basePrice: 2000,
          ageRanges: ['preschool', 'school_age'],
          experienceYears: 2,
          availableSlots: [
            '2026-05-21T09:00:00',
            '2026-05-23T09:00:00',
            '2026-05-28T09:00:00',
          ],
          bio:
              'Early career speech therapist focused on articulation and phonological disorders in preschool-age children.',
          languages: ['urdu'],
          overallScore: 0.71,
          factorScores: {
            'specialization': 0.7,
            'age_range': 1.0,
            'qualifications': 0.5,
            'distance': 0.3,
            'rating': 0.6,
            'reliability': 0.82,
            'price': 0.95,
            'cancellation': 0.5,
          },
          reasoning:
              'Budget option: BSc level (unverified), 7km away, 4.2★. Good price fit but lower qualifications.',
          distanceKm: 7.0,
          finalPrice: 2400,
          nextAvailableSlot: '2026-05-21T09:00:00',
        ),
      ],
    );
  }

  BookingResult _mockBookingResult(String therapistId) {
    return BookingResult(
      booking: Booking(
        bookingId: 'BK-20260519-001',
        therapistId: therapistId,
        userId: 'u001',
        sessions: [
          BookingSession(
              date: '2026-05-20',
              time: '16:00',
              durationMin: 45,
              status: 'confirmed'),
          BookingSession(
              date: '2026-05-22',
              time: '16:00',
              durationMin: 45,
              status: 'confirmed'),
        ],
        totalPrice: 6720,
        confirmationCode: 'NA-AYK-4291',
        status: 'confirmed',
        createdAt: '2026-05-19T11:30:00+05:00',
      ),
      traceId: 'mock-trace-001',
      parentNotification:
          'Salam! Aap ka booking confirm ho gaya hai. Therapist kal 20 May, 4:00 PM ko aap ke ghar aayengi. Confirmation: NA-AYK-4291. Total: Rs 6,720 (2 sessions).',
      followupEvents: [
        {
          'type': 'session_reminder',
          'trigger': '1_hour_before',
          'target_session': 1,
          'message_preview': 'Therapist 1 ghante mein aa rahi hain...',
        },
        {
          'type': 'post_session_feedback',
          'trigger': '30_min_after',
          'target_session': 1,
          'prompt': 'Session kaisi rahi? 1-5 rate karen.',
        },
        {
          'type': 'session_reminder',
          'trigger': '1_hour_before',
          'target_session': 2,
          'message_preview': 'Reminder: Kal 22 May 4:00 PM session hai...',
        },
        {
          'type': 'progress_digest',
          'trigger': 'after_4_sessions',
          'summary': 'Monthly progress check',
        },
        {
          'type': 'renewal_nudge',
          'trigger': 'after_session_8',
          'message_preview':
              'Therapy package complete ho rahi hai. Continue karein?',
        },
      ],
    );
  }
}
