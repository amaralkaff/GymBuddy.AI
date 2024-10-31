// lib/services/workout_info_service.dart
import 'dart:developer';
import 'package:workout_ai/services/api_service.dart';

class WorkoutInfoService {
  final APIService _api = APIService();

  Future<List<WorkoutInfo>> getWorkoutInfo() async {
    try {
      final response = await _api.get('getWoInfo');
      log('Workout info response: $response');

      if (response['statusCode'] != 200) {
        throw Exception(response['error'] ?? response['message'] ?? 'Failed to fetch workout info');
      }

      final List<dynamic> workouts = response['data'] as List<dynamic>? ?? [];
      return workouts
          .map((w) => WorkoutInfo.fromJson(w as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error in getWorkoutInfo: $e');
      rethrow;
    }
  }
}

class WorkoutInfo {
  final String woName;
  final int sumWo;
  final double totalCalories;
  final String id;
  final String userId;

  const WorkoutInfo({
    required this.woName,
    required this.sumWo,
    required this.totalCalories,
    required this.id,
    required this.userId,
  });

  factory WorkoutInfo.fromJson(Map<String, dynamic> json) {
    return WorkoutInfo(
      woName: json['woName'] as String? ?? '',
      sumWo: _parseInteger(json['sumWo']),
      totalCalories: _parseDouble(json['totalCalories']),
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
    );
  }

  static int _parseInteger(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}