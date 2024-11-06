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
        throw Exception(response['error'] ??
            response['message'] ??
            'Failed to fetch workout info');
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
  final int month;

  const WorkoutInfo({
    required this.woName,
    required this.sumWo,
    required this.totalCalories,
    required this.id,
    required this.userId,
    required this.month,
  });

  factory WorkoutInfo.fromJson(Map<String, dynamic> json) {
    return WorkoutInfo(
      woName: json['woName'] as String? ?? '',
      sumWo: _parseInteger(json['sumWo']),
      totalCalories: _parseDouble(json['totalCalories']),
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      month: _parseInteger(json['month']),
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

// lib/models/progress_data.dart
class ProgressData {
  final double currentWeight;
  final double totalCalories;
  final int month;

  ProgressData({
    required this.currentWeight,
    required this.totalCalories,
    required this.month,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      currentWeight: _parseDouble(json['currentWeight']),
      totalCalories: _parseDouble(json['totalCalories']),
      month: json['month'] as int,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ProgressResponse {
  final int statusCode;
  final String averageCurrentWeight;
  final List<ProgressData> data;

  ProgressResponse({
    required this.statusCode,
    required this.averageCurrentWeight,
    required this.data,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    return ProgressResponse(
      statusCode: json['statusCode'] as int,
      averageCurrentWeight: json['averageCurrentWeight'] as String,
      data: (json['data'] as List)
          .map((item) => ProgressData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  double get averageWeight => double.tryParse(averageCurrentWeight) ?? 0.0;

  // Helper methods for data processing
  List<ProgressData> get sortedByMonth {
    final sorted = List<ProgressData>.from(data);
    sorted.sort((a, b) => a.month.compareTo(b.month));
    return sorted;
  }

  double get totalCaloriesBurned {
    return data.fold(0.0, (sum, item) => sum + item.totalCalories);
  }

  double get weightChange {
    if (data.isEmpty) return 0;
    final sorted = sortedByMonth;
    return sorted.last.currentWeight - sorted.first.currentWeight;
  }

  double get weightChangePercentage {
    if (data.isEmpty) return 0;
    final sorted = sortedByMonth;
    final firstWeight = sorted.first.currentWeight;
    final change = weightChange;
    return (change / firstWeight * 100).abs();
  }

  bool get isWeightGain => weightChange > 0;
}
