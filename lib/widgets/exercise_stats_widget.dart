// lib/widgets/exercise_stats_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exercise_completion_model.dart';
import '../models/push_up_model.dart';
import '../models/sit_up_model.dart';

class ExerciseStatsWidget extends StatefulWidget {
  final String exerciseType;
  final int reps;
  static const int targetReps = 5; // Changed from timer to rep target

  const ExerciseStatsWidget({
    required this.exerciseType,
    required this.reps,
    super.key,
  });

  @override
  State<ExerciseStatsWidget> createState() => _ExerciseStatsWidgetState();
}

class _ExerciseStatsWidgetState extends State<ExerciseStatsWidget> {
  bool _isCompleted = false;

  @override
  void didUpdateWidget(ExerciseStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if target reps reached
    if (widget.reps >= ExerciseStatsWidget.targetReps && !_isCompleted) {
      print('Target reps reached: ${widget.reps}');
      _isCompleted = true;
      _handleExerciseCompletion();
    }
  }

  void _handleExerciseCompletion() {
    if (!mounted) return;
    print('Handling exercise completion');
    
    context.read<ExerciseCompletion>().markExerciseComplete(widget.exerciseType);
    
    if (widget.exerciseType == 'Push-up Counter') {
      context.read<PushUpCounter>().resetCounter();
    } else if (widget.exerciseType == 'Sit-up Counter') {
      context.read<SitUpCounter>().resetCounter();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final remainingReps = ExerciseStatsWidget.targetReps - widget.reps;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.exerciseType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reps: ${widget.reps} / ${ExerciseStatsWidget.targetReps}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.reps < ExerciseStatsWidget.targetReps)
            Text(
              '$remainingReps more to go!',
              style: TextStyle(
                color: remainingReps <= 2 ? Colors.green[300] : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (widget.reps >= ExerciseStatsWidget.targetReps)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Exercise Complete!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: widget.reps / ExerciseStatsWidget.targetReps,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.reps >= ExerciseStatsWidget.targetReps 
                  ? Colors.green 
                  : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}