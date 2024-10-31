// lib/services/api_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:workout_ai/services/auth_service.dart';

class APIService {
  static const String baseUrl = 'https://backend-workout-ai.vercel.app/api';

  Map<String, String> _getAuthHeaders() {
    final token = AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': 'token=$token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      log('Making GET request to $endpoint');
      final headers = _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      log('Response status: ${response.statusCode}, body: $data');

      if (response.statusCode == 401) {
        AuthService.clearToken();
        throw Exception('Authentication expired');
      }

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Request failed');
      }

      return data;
    } catch (e) {
      log('API GET error: $e');
      if (e.toString().contains('Authentication')) {
        AuthService.clearToken();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = requiresAuth ? _getAuthHeaders() : {
        'Content-Type': 'application/json',
      };

      log('Making POST request to $endpoint');
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      log('Response status: ${response.statusCode}, body: $data');

      if (response.statusCode == 401 && requiresAuth) {
        AuthService.clearToken();
        throw Exception('Authentication expired');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['message'] ?? 'Request failed');
      }

      return data;
    } catch (e) {
      log('API POST error: $e');
      if (e.toString().contains('Authentication')) {
        AuthService.clearToken();
      }
      rethrow;
    }
  }

  Future<bool> delete(String endpoint) async {
    try {
      final headers = _getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        AuthService.clearToken();
        throw Exception('Authentication expired');
      }

      return response.statusCode == 200;
    } catch (e) {
      log('API DELETE error: $e');
      if (e.toString().contains('Authentication')) {
        AuthService.clearToken();
      }
      rethrow;
    }
  }
}