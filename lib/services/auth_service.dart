// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_info_model.dart';

class AuthService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';

  Future<bool> register(UserInfo userInfo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/userInfo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userInfo.toJson()),
      );

      print('Registration Response: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['statusCode'] == 201 &&
            responseData['message'] == "succeed save user info") {
          return true;
        }
      }

      throw Exception(responseData['message'] ?? 'Registration failed');
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response: ${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['statusCode'] == 200) {
        // Create basic user info from login credentials
        final userInfo = UserInfo(
          username: '', // Will be populated later if needed
          email: email,
          password: password,
          height: 0, // Will be populated later if needed
          weight: 0, // Will be populated later if needed
        );

        return {
          'statusCode': 200,
          'message': responseData['message'],
          'user': userInfo,
        };
      }

      throw Exception(responseData['message'] ?? 'Login failed');
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/logout'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
}
