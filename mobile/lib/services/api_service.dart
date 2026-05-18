import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/therapist.dart';

class ApiService {
  // Update this to your actual backend URL when testing on a real device or deployed server
  // For Android emulator pointing to local machine, use 10.0.2.2. For iOS simulator, 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<Therapist>> findTherapists(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/find-therapists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ranked = data['ranked_therapists'] ?? [];
        return ranked.map((json) => Therapist.fromJson(json)).toList();
      } else {
        throw Exception('Failed to find therapists: ${response.body}');
      }
    } catch (e) {
      // Return mock data if backend isn't running to ensure app UI can be seen
      print('API Error: $e. Returning mock data.');
      return _getMockTherapists();
    }
  }

  // Fallback mock data if the python backend is not currently running
  List<Therapist> _getMockTherapists() {
    return [
      Therapist(
        id: 't001',
        name: 'Dr. Ayesha Khan',
        gender: 'female',
        specializations: ['speech_therapy'],
        qualifications: ['M.Phil Speech-Language Pathology'],
        verified: true,
        city: 'Lahore',
        area: 'Gulberg',
        rating: 4.8,
        reviewCount: 64,
        basePrice: 2800,
        bio: 'Specialized in pediatric speech-language therapy for children with autism.',
        languages: ['urdu', 'english'],
        overallScore: 0.92,
        factorScores: {
          'specialization': 1.0,
          'distance': 0.77,
          'rating': 0.90,
        },
        reasoning: 'Top match: M.Phil pediatric speech specialist, 2.3km away, fits budget.',
        distanceKm: 2.3,
        finalPrice: 3360,
        nextAvailableSlot: '2026-05-19T16:00:00',
      ),
      Therapist(
        id: 't002',
        name: 'Dr. Bilal Ahmed',
        gender: 'male',
        specializations: ['speech_therapy', 'behavioral_therapy'],
        qualifications: ['MSc Psychology', 'ABA Certified'],
        verified: true,
        city: 'Lahore',
        area: 'DHA',
        rating: 4.6,
        reviewCount: 42,
        basePrice: 3000,
        bio: 'Focuses on behavioral interventions and speech clarity.',
        languages: ['urdu', 'english', 'punjabi'],
        overallScore: 0.85,
        factorScores: {
          'specialization': 0.8,
          'distance': 0.5,
          'rating': 0.8,
        },
        reasoning: 'Great match: ABA certified, slightly further away.',
        distanceKm: 5.1,
        finalPrice: 3500,
        nextAvailableSlot: '2026-05-20T14:00:00',
      ),
    ];
  }
}
