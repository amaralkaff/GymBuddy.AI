// lib/services/pushup_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class PushupService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';

  Future<Map<String, dynamic>> submitPushups({
    required int weight,
    required int pushups,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pushup');
      
      // Create the request body with explicit integer values
      final requestBody = {
        'weight': weight.toInt(),
        'pushups': pushups.toInt(),
      };

      // Convert to JSON string
      final jsonString = json.encode(requestBody);
      print('Raw JSON being sent: $jsonString');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonString,
      );

      print('Request details:');
      print('URL: $uri');
      print('Headers: ${response.request?.headers}');
      print('Body sent: $jsonString');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Exception in submitPushups: $e');
      rethrow;
    }
  }
}