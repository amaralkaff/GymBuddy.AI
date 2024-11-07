// lib/models/exercise_timer_model.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exercise_completion_model.dart';

enum TimerStatus {
  initial,
  running,
  paused,
  completed
}

class ExerciseTimerState {
  final int timeRemaining;
  final TimerStatus status;
  final int totalReps;

  ExerciseTimerState({
    required this.timeRemaining,
    required this.status,
    required this.totalReps,
  });

  ExerciseTimerState copyWith({
    int? timeRemaining,
    TimerStatus? status,
    int? totalReps,
  }) {
    return ExerciseTimerState(
      timeRemaining: timeRemaining ?? this.timeRemaining,
      status: status ?? this.status,
      totalReps: totalReps ?? this.totalReps,
    );
  }
}

class ExerciseTimerCubit extends Cubit<ExerciseTimerState> {
  static const int exerciseDuration = 30;
  Timer? _timer;
  final BuildContext context;
  final String exerciseType;
  
  ExerciseTimerCubit(this.context, this.exerciseType) : super(
    ExerciseTimerState(
      timeRemaining: exerciseDuration,
      status: TimerStatus.initial,
      totalReps: 0,
    )
  );

  void startTimer() {
    if (state.status != TimerStatus.running) {
      emit(state.copyWith(status: TimerStatus.running));
      _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
  }

  void resetTimer() {
    _timer?.cancel();
    emit(ExerciseTimerState(
      timeRemaining: exerciseDuration,
      status: TimerStatus.initial,
      totalReps: 0,
    ));
  }

  void updateReps(int totalReps) {
    emit(state.copyWith(totalReps: totalReps));
  }

  void _onTick(Timer timer) {
    if (state.timeRemaining > 0) {
      emit(state.copyWith(
        timeRemaining: state.timeRemaining - 1,
      ));
    } else {
      timer.cancel();
      emit(state.copyWith(status: TimerStatus.completed));
      _handleExerciseCompletion();
    }
  }

  void _handleExerciseCompletion() {
    context.read<ExerciseCompletion>().markExerciseComplete(exerciseType);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}