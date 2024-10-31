// lib/widgets/progress_tracker.dart
import 'package:flutter/material.dart';
import 'package:workout_ai/services/workout_info_service.dart';

class ProgressTracker extends StatelessWidget {
  final List<WorkoutInfo> workouts;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const ProgressTracker({
    super.key,
    required this.workouts,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!.contains('Authentication')
                        ? 'Please log in again to view your progress'
                        : 'Unable to load workout progress',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (workouts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No workouts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete your first workout to see your progress here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        final color = workout.woName.contains('Push') ? Colors.blue : Colors.green;
        return _buildWorkoutItem(workout, color);
      },
    );
  }

  Widget _buildWorkoutItem(WorkoutInfo workout, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                workout.woName.contains('Push')
                    ? Icons.fitness_center
                    : Icons.accessibility_new,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.woName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          '${workout.sumWo} sets',
                          color,
                          color.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          '${workout.totalCalories.toStringAsFixed(1)} cal',
                          Colors.green,
                          Colors.green.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}