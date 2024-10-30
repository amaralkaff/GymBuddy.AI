// lib/services/exercise_service.dart
import 'package:flutter/material.dart';
import 'package:test_1/services/workout_info_service.dart';
import 'package:test_1/services/pushup_service.dart';

class ExerciseService {
  final WorkoutInfoService _workoutInfoService = WorkoutInfoService();
  final PushupService _pushupService = PushupService();

  Future<List<WorkoutInfo>> getWorkoutSummary() async {
    try {
      return await _workoutInfoService.getWorkoutInfo();
    } catch (e) {
      debugPrint('Error getting workout summary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitPushupExercise({
    required int weight,
    required int pushups,
  }) async {
    try {
      return await _pushupService.submitPushups(
        weight: weight,
        pushups: pushups,
      );
    } catch (e) {
      debugPrint('Error submitting pushups: $e');
      rethrow;
    }
  }
}