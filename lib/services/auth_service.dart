// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_info_model.dart';
import '../services/api_service.dart';

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

        // Get complete user info after successful login
        try {
          final userResponse = await _api.get('userinfo');
          final userData = userResponse['user'] as Map<String, dynamic>;
          final userInfo = UserInfo.fromJson({
            ...userData,
            'email': email,
            'password': password, // Store password temporarily for session
          });

          await saveUserInfo(userInfo);

          return {
            'statusCode': 200,
            'message': response['message'] ?? 'Login successful',
            'token': token,
            'user': userInfo,
          };
        } catch (userError) {
          log('Error fetching detailed user info: $userError');
          // Fallback to basic user info from login response
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
      }

      throw Exception(response['message'] ?? 'Login failed');
    } catch (e) {
      log('Login error: $e');
      await clearToken();
      rethrow;
    }
  }

  Future<UserInfo> getUserInfo() async {
    try {
      // First try to get from local storage
      final savedInfo = await loadUserInfo();
      if (savedInfo != null) {
        // Verify if local data is still valid
        try {
          final response = await _api.get('userinfo');
          if (response['statusCode'] == 200) {
            final userData = response['user'] as Map<String, dynamic>;
            // Preserve sensitive data that might not come from API
            final updatedInfo = UserInfo.fromJson({
              ...userData,
              'email': savedInfo.email,
              'password': savedInfo.password,
            });
            await saveUserInfo(updatedInfo);
            return updatedInfo;
          }
        } catch (e) {
          log('Error refreshing user info: $e');
          // Return saved info if API call fails
          return savedInfo;
        }
      }

      // If no saved info, get from API
      final response = await _api.get('userinfo');
      if (response['statusCode'] == 200) {
        final userData = response['user'] as Map<String, dynamic>;
        final userInfo = UserInfo.fromJson(userData);
        await saveUserInfo(userInfo);
        return userInfo;
      }

      throw Exception(response['message'] ?? 'Failed to fetch user info');
    } catch (e) {
      log('Get user info error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserInfo(UserInfo userInfo) async {
    try {
      final response = await _api.post(
        'updateuser',
        userInfo.toJson(),
        requiresAuth: true,
      );

      if (response['statusCode'] == 200) {
        await saveUserInfo(userInfo);
        return {
          'statusCode': 200,
          'message': 'User info updated successfully',
          'user': userInfo,
        };
      }

      throw Exception(response['message'] ?? 'Failed to update user info');
    } catch (e) {
      log('Update user info error: $e');
      rethrow;
    }
  }

  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      final response = await _api.get('validate-token');
      return response['statusCode'] == 200;
    } catch (e) {
      log('Token validation error: $e');
      return false;
    }
  }

  Future<void> refreshToken() async {
    try {
      final response = await _api.post('refresh-token', {}, requiresAuth: true);
      if (response['token'] != null) {
        await setToken(response['token']);
      }
    } catch (e) {
      log('Token refresh error: $e');
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
