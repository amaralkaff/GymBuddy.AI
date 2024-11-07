import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SitUpService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';

  Future<Map<String, dynamic>> submitSitUps({
    required int sitUps,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      log('Submitting situps with token: $token');
      final response = await http.post(
        Uri.parse('$baseUrl/situp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: jsonEncode({
          'sitUps': sitUps,
        }),
      );

      final data = jsonDecode(response.body);
      log('Situp submission response: $data');

      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'Kalori_yang_terbakar_per_sit_up':
              data['Kalori_yang_terbakar_per_sit_up'],
          'Total_kalori_yang_terbakar': data['Total_kalori_yang_terbakar'],
        };
      } else {
        log('Situp submission failed with status code: ${response.statusCode}');
        return {
          'statusCode': response.statusCode,
          'Kalori_yang_terbakar_per_sit_up': null,
          'Total_kalori_yang_terbakar': null,
        };
      }
    } catch (e) {
      log('Situp submission error: $e');
      throw Exception('Failed to submit situps: $e');
    }
  }

  Future<void> testSubmitSitUps() async {
    try {
      final result = await submitSitUps(sitUps: 12);
      log('Test Submit SitUps Result:');
      log(json.encode(result));
    } catch (e) {
      log('Test Submit SitUps Error: $e');
      throw Exception('Failed to submit situps: $e');
    }
  }
}
