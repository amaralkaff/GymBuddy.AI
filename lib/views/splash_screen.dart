// lib/views/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:test_1/models/exercise_completion_model.dart';
import 'package:test_1/models/exercise_stats_model.dart';
import 'package:test_1/models/user_manager.dart';
import 'package:test_1/views/pose_detection_view.dart';
import 'package:test_1/views/sit_up_detector_view.dart';
import 'package:test_1/widgets/user_info_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserInfo();
  }

  Future<void> _checkUserInfo() async {
    if (!context.read<UserManager>().isUserInfoSet) {
      // Show user info dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UserInfoDialog(),
      );

      if (result != true && mounted) {
        // If user info wasn't set successfully, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your profile to continue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startExercise(BuildContext context, Widget exerciseScreen) async {
    if (!context.read<UserManager>().isUserInfoSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Switch to landscape orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => exerciseScreen),
      );
    }

    // Switch back to portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }


  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Color color,
  required IconData icon,
  required String animationAsset,
  required VoidCallback onTap,
}) {
  final bool isCompleted = context.watch<ExerciseCompletion>().isExerciseCompleted(title);
  final stats = context.watch<ExerciseStatsModel>().getStats(title);
  
  return GestureDetector(
    onTap: isCompleted ? null : onTap,
    child: Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      animationAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(icon, color: color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (isCompleted && stats != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.repCount} reps completed',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (stats.totalCalories != null)
                                Text(
                                  'Calories burned: ${stats.totalCalories!.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isCompleted)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
  final userManager = context.watch<UserManager>();
  final userInfo = userManager.userInfo;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Workout AI',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      Row(
        children: [
          // Register Button
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => const UserInfoDialog(),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Profile Icon - Only show if user is logged in
          if (userInfo != null)
            IconButton(
              icon: const Icon(Icons.person, color: Colors.green),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const UserInfoDialog(),
                );

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    ],
    );
  }

  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return true;
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header
                _buildHeader(context),
                  
                const SizedBox(height: 24),
                
                // Featured Workouts Section
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Workouts For Programmers ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                  // Workout Cards Carousel
                  SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWorkoutCard(
                    context: context,
                    title: 'Push-up Counter',
                    subtitle: 'Count your push-ups',
                    color: Colors.blue,
                    icon: Icons.fitness_center,
                    animationAsset: 'assets/push-up-animation.json',
                    onTap: () => _startExercise(
                      context,
                      const PoseDetectorView(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutCard(
                    context: context,
                    title: 'Sit-up Counter',
                    subtitle: 'Track your sit-ups',
                    color: Colors.green,
                    icon: Icons.accessibility_new,
                    animationAsset: 'assets/sit-up-animation.json',
                    onTap: () => _startExercise(
                      context,
                      const SitUpDetectorView(),
                    ),
                  ),
                  ],
                ),
              ),

                const SizedBox(height: 24),

                // Instructions Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to use',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        icon: Icons.camera_alt,
                        text: 'Position your device in landscape mode',
                      ),
                      _buildInstructionItem(
                        icon: Icons.accessibility_new,
                        text: 'Make sure your full body is visible',
                      ),
                      _buildInstructionItem(
                        icon: Icons.straighten,
                        text: 'Maintain proper form for accurate counting',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}