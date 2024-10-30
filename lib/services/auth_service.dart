// lib/services/auth_service.dart
import 'package:test_1/models/user_info_model.dart';
import 'package:test_1/services/api_service.dart';

class AuthService {
  final APIService _api = APIService();

  Future<bool> register(UserInfo userInfo) async {
    try {
      final response = await _api.post('userInfo', userInfo.toJson());
      return response['statusCode'] == 201 && 
             response['message'] == "succeed save user info";
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('login', {
        'email': email,
        'password': password,
      });

      if (response['statusCode'] == 200) {
        return {
          'statusCode': 200,
          'message': response['message'],
          'user': UserInfo(
            username: '',
            email: email,
            password: password,
            height: 0,
            weight: 0,
          ),
        };
      }
      throw Exception(response['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<bool> logout() async {
    return _api.delete('logout');
  }
}