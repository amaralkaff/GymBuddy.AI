// lib/widgets/exercise_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exercise_completion_model.dart';
import '../models/exercise_stats_model.dart';
import '../models/weight_manager.dart';
import '../services/pushup_service.dart';

class ExerciseOverlay extends StatelessWidget {
  final String exerciseType;
  final int reps;
  final VoidCallback? onBackPressed;

  const ExerciseOverlay({
    Key? key,
    required this.exerciseType,
    required this.reps,
    this.onBackPressed,
  }) : super(key: key);

  Future<void> _submitWorkout(BuildContext context) async {
    if (exerciseType == 'Push-up Counter') {
      final weightManager = context.read<WeightManager>();
      
      if (!weightManager.hasWeight()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your weight first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final pushupService = PushupService();
        final result = await pushupService.submitPushups(
          weight: weightManager.getWeight(),
          pushups: reps,
        );

        context.read<ExerciseStatsModel>().updateStats(
          exerciseType: exerciseType,
          repCount: reps,
          caloriesPerRep: double.tryParse(result['Kalori_yang_terbakar_per_push_up']?.toString() ?? '0'),
          totalCalories: double.tryParse(result['Total_kalori_yang_terbakar']?.toString() ?? '0'),
        );

        if (context.mounted) {
          context.read<ExerciseCompletion>().markExerciseComplete(exerciseType);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit workout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Back Button
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackPressed,
          ),
        ),
        
        // Rep Counter and Done Button
        Positioned(
          top: 40,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                  children: [
                    Text(
                      exerciseType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Reps: $reps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitWorkout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}