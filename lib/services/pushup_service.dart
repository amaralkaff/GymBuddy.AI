import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:workout_ai/services/auth_service.dart';

class PushupService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> submitPushups({
    required int pushUps,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      log('Submitting pushups with token: $token');
      final response = await http.post(
        Uri.parse('$baseUrl/pushup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: jsonEncode({
          'pushUps': pushUps,
        }),
      );
      
      final data = jsonDecode(response.body);
      log('Pushup submission response: $data');
      
      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'Kalori_yang_terbakar_per_push_up': data['Kalori_yang_terbakar_per_push_up'],
          'Total_kalori_yang_terbakar': data['Total_kalori_yang_terbakar'],
        };
      } else {
        log('Pushup submission failed with status code: ${response.statusCode}');
        return {
          'statusCode': response.statusCode,
          'Kalori_yang_terbakar_per_push_up': null,
          'Total_kalori_yang_terbakar': null,
        };
      }
    } catch (e) {
      log('Pushup submission error: $e');
      throw Exception('Failed to submit pushups: $e');
    }
  }

  // Simplified test method that uses existing authentication
  Future<void> testSubmitPushups() async {
    try {
      // Simply try to submit pushups using the existing token
      final result = await submitPushups(pushUps: 12);
      log('Test Submit Pushups Result:');
      log(json.encode(result));
    } catch (e) {
      log('Test Submit Pushups Error: $e');
      throw Exception('Failed to submit pushups: $e');
    }
  }
}