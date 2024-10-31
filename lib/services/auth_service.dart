// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_ai/models/user_info_model.dart';
import 'package:workout_ai/services/api_service.dart';

class AuthService {
  static String? _token;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  final APIService _api = APIService();

  static String? getToken() => _token;

  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
    log('Token set: ${token != null}');
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    log('Token and user info cleared');
  }

  Future<void> saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo.toJson()));
    log('User info saved');
  }

  Future<UserInfo?> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      try {
        final userJson = jsonDecode(userStr) as Map<String, dynamic>;
        return UserInfo(
          username: userJson['username'] as String,
          email: userJson['email'] as String,
          password: userJson['password'] as String,
          height: (userJson['height'] as num).toInt(),
          weight: (userJson['weight'] as num).toInt(),
        );
      } catch (e) {
        log('Error parsing user info: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      
      if (_token != null) {
        final userStr = prefs.getString(_userKey);
        return userStr != null;
      }
      return false;
    } catch (e) {
      log('Init auth error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register(UserInfo userInfo) async {
    try {
      log('Attempting registration for email: ${userInfo.email}');
      
      final response = await _api.post(
        'userInfo',
        {
          'username': userInfo.username,
          'email': userInfo.email,
          'password': userInfo.password,
          'height': userInfo.height,
          'weight': userInfo.weight,
        },
        requiresAuth: false,
      );

      log('Registration response: $response');

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        await saveUserInfo(userInfo);
        return {
          'statusCode': response['statusCode'],
          'message': response['message'] ?? 'Registration successful',
          'user': userInfo,
        };
      }

      throw Exception(response['message'] ?? 'Registration failed');
    } catch (e) {
      log('Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      log('Attempting login for email: $email');
      
      final response = await _api.post(
        'login',
        {'email': email, 'password': password},
        requiresAuth: false,
      );

      log('Login response: $response');

      if (response['statusCode'] == 200 && response['token'] != null) {
        final token = response['token'];
        log('Token received: $token');
        await setToken(token);

        final userInfo = UserInfo(
          username: response['user']?['username'] ?? '',
          email: email,
          password: password,
          height: response['user']?['height'] ?? 0,
          weight: response['user']?['weight'] ?? 0,
        );

        await saveUserInfo(userInfo);

        return {
          'statusCode': 200,
          'message': response['message'] ?? 'Login successful',
          'token': token,
          'user': userInfo,
        };
      }

      throw Exception(response['message'] ?? 'Login failed');
    } catch (e) {
      log('Login error: $e');
      await clearToken();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('logout', {}, requiresAuth: true);
    } catch (e) {
      log('Logout error: $e');
    } finally {
      await clearToken();
    }
  }

  bool isAuthenticated() => _token != null;
}
