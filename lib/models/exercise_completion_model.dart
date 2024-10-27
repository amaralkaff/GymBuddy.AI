// lib/models/exercise_completion_model.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class ExerciseCompletion extends Cubit<Set<String>> {
  ExerciseCompletion() : super({});
  
  void markExerciseComplete(String exerciseType) {
    final newState = Set<String>.from(state);
    newState.add(exerciseType);
    emit(newState);
  }
  
  void resetCompletions() {
    emit({});
  }
  
  bool isExerciseCompleted(String exerciseType) {
    return state.contains(exerciseType);
  }
}
