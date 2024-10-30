// lib/models/workout_state.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_1/services/exercise_service.dart';
import 'package:test_1/services/workout_info_service.dart';

enum WorkoutStatus { initial, loading, success, failure }

class WorkoutState {
  final WorkoutStatus status;
  final List<WorkoutInfo> workouts;
  final String? error;

  WorkoutState({
    this.status = WorkoutStatus.initial,
    this.workouts = const [],
    this.error,
  });

  WorkoutState copyWith({
    WorkoutStatus? status,
    List<WorkoutInfo>? workouts,
    String? error,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      workouts: workouts ?? this.workouts,
      error: error,
    );
  }
}

class WorkoutCubit extends Cubit<WorkoutState> {
  final ExerciseService _exerciseService;

  WorkoutCubit(this._exerciseService) : super(WorkoutState());

  Future<void> loadWorkouts() async {
    emit(state.copyWith(status: WorkoutStatus.loading));
    try {
      final workouts = await _exerciseService.getWorkoutSummary();
      emit(state.copyWith(
        status: WorkoutStatus.success,
        workouts: workouts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> submitPushups({
    required int weight,
    required int pushups,
  }) async {
    try {
      await _exerciseService.submitPushupExercise(
        weight: weight,
        pushups: pushups,
      );
      loadWorkouts(); // Refresh workout data after submission
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
