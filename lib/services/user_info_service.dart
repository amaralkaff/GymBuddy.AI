// lib/services/user_info_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_info_model.dart';

class UserInfoService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';

  Future<bool> saveUserInfo(UserInfo userInfo) async {
    try {
      final uri = Uri.parse('$baseUrl/userInfo');
      
      final Map<String, dynamic> body = {
        'username': userInfo.username,
        'email': userInfo.email,
        'height': userInfo.height,
        'weight': userInfo.weight,
      };

      print('Request URL: $uri');
      print('Request body: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check for both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        // Verify the success message in the response
        if (responseData['statusCode'] == 201 && 
            responseData['message'] == "succeed save user info") {
          return true;
        }
      }
      throw Exception('Failed to save user info: Unexpected response');
    } catch (e) {
      print('Error in saveUserInfo: $e');
      rethrow;
    }
  }
}