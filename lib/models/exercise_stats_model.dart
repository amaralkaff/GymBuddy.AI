// lib/models/exercise_stats_model.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class ExerciseStats {
  final String exerciseType;
  final int repCount;
  final double? caloriesPerRep;
  final double? totalCalories;
  final DateTime completedAt;

  ExerciseStats({
    required this.exerciseType,
    required this.repCount,
    this.caloriesPerRep,
    this.totalCalories,
    required this.completedAt,
  });
}

class ExerciseStatsModel extends Cubit<Map<String, ExerciseStats>> {
  ExerciseStatsModel() : super({});

  get exerciseType => null;

  get repCount => null;

  get caloriesPerRep => null;

  get totalCalories => null;
  
  void updateStats({
    required String exerciseType,
    required int repCount,
    double? caloriesPerRep,
    double? totalCalories,
  }) {
    final newStats = Map<String, ExerciseStats>.from(state);
    newStats[exerciseType] = ExerciseStats(
      exerciseType: exerciseType,
      repCount: repCount,
      caloriesPerRep: caloriesPerRep,
      totalCalories: totalCalories,
      completedAt: DateTime.now(),
    );
    emit(newStats);
  }
  
  ExerciseStats? getStats(String exerciseType) {
    return state[exerciseType];
  }
  
  void clearStats() {
    emit({});
  }
}