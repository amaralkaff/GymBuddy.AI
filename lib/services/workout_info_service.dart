// lib/services/workout_info_service.dart
import 'package:test_1/services/api_service.dart';

class WorkoutInfo {
  final String woName;
  final int sumWo;
  final double totalCalories;

  const WorkoutInfo({
    required this.woName,
    required this.sumWo,
    required this.totalCalories,
  });

  factory WorkoutInfo.fromJson(Map<String, dynamic> json) {
    return WorkoutInfo(
      woName: json['woName'] as String? ?? '',
      sumWo: int.tryParse(json['sumWo']?.toString() ?? '0') ?? 0,
      totalCalories: double.tryParse(json['totalCalories']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

class WorkoutInfoService {
  final APIService _api = APIService();

  Future<List<WorkoutInfo>> getWorkoutInfo() async {
    try {
      final response = await _api.get('getWoInfo');
      final List<dynamic> workouts = response['data'] as List<dynamic>? ?? [];
      return workouts
          .map((w) => WorkoutInfo.fromJson(w as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load workout info: $e');
    }
  }
}
