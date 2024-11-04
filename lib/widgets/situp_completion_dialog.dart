// lib/widgets/situp_completion_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout_ai/models/exercise_completion_model.dart';
import 'package:workout_ai/models/exercise_stats_model.dart';
import 'package:workout_ai/services/situp_service.dart';
import 'package:workout_ai/views/splash_screen.dart';

class SitUpCompletionDialog extends StatefulWidget {
  final String exerciseType;
  final int reps;

  const SitUpCompletionDialog({
    super.key,
    required this.exerciseType,
    required this.reps,
  });

  @override
  State<SitUpCompletionDialog> createState() => _SitUpCompletionDialogState();
}

class _SitUpCompletionDialogState extends State<SitUpCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final situpService = SitUpService();
      final result = await situpService.submitSitUps(
        sitUps: widget.reps,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        context.read<ExerciseStatsModel>().updateStats(
              exerciseType: widget.exerciseType,
              repCount: widget.reps,
              caloriesPerRep: double.tryParse(
                result['Kalori_yang_terbakar_per_sit_up'] ?? '0',
              ),
              totalCalories: double.tryParse(
                result['Total_kalori_yang_terbakar'] ?? '0',
              ),
            );

        context
            .read<ExerciseCompletion>()
            .markExerciseComplete(widget.exerciseType);

        Navigator.of(context).pop();
        Navigator.of(context).pop();

        final navigatorContext = Navigator.of(context);
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout completed! Calories burned: ${result['Total_kalori_yang_terbakar']}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (navigatorContext.context.mounted) {
          final splashScreenState = navigatorContext.context
              .findAncestorStateOfType<State<SplashScreen>>();
          if (splashScreenState != null) {
            (splashScreenState as dynamic).loadData();
          }
        }
      } else {
        throw Exception('Failed to submit workout');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Complete Workout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.exerciseType}s completed:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${widget.reps}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
