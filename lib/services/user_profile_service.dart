// lib/services/user_profile_service.dart
import 'dart:developer';

import '../models/user_profile_model.dart';
import '../services/api_service.dart';

class UserProfileService {
  final APIService _api = APIService();

  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _api.get('userProfile');

      if (response['statusCode'] != 200) {
        throw Exception(response['message'] ?? 'Failed to fetch user profile');
      }

      if (response['data'] == null) {
        throw Exception('User profile data is missing');
      }

      final profileData = response['data'] as Map<String, dynamic>;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      log('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<UserProfile> updateUserProfile({
    required String username,
    required String email,
    required int height,
    required int weight,
  }) async {
    try {
      final response = await _api.post(
        'userProfile',
        {
          'username': username,
          'email': email,
          'height': height,
          'weight': weight,
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception(response['message'] ?? 'Failed to update user profile');
      }

      if (response['data'] == null) {
        throw Exception('Updated profile data is missing');
      }

      final profileData = response['data'] as Map<String, dynamic>;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      log('Error updating user profile: $e');
      rethrow;
    }
  }
}
