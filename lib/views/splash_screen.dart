// lib/views/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:test_1/models/auth_state.dart';
import 'package:test_1/models/exercise_completion_model.dart';
import 'package:test_1/models/exercise_stats_model.dart';
import 'package:test_1/models/user_manager.dart';
import 'package:test_1/services/auth_service.dart';
import 'package:test_1/views/auth/login_screen.dart';
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
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UserInfoDialog(),
      );

      if (result != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your profile to continue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startExercise(
      BuildContext context, Widget exerciseScreen) async {
    if (!context.read<UserManager>().isUserInfoSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
            ElevatedButton.icon(
              onPressed: () async {
                final authService = AuthService();
                try {
                  await authService.logout();

                  if (mounted) {
                    context.read<UserManager>().clearUserInfo();
                    context.read<AuthCubit>().loggedOut();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to logout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
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

  Widget _buildWorkoutCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String animationAsset,
    required VoidCallback onTap,
  }) {
    final bool isCompleted =
        context.watch<ExerciseCompletion>().isExerciseCompleted(title);
    final stats = context.watch<ExerciseStatsModel>().getStats(title);

    return SizedBox(
      width: 280,
      child: GestureDetector(
        onTap: isCompleted ? null : onTap,
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      color: color.withOpacity(0.1),
                      child: Center(
                        child: Lottie.asset(
                          animationAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                          width: double.infinity,
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
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

                        // Workout Cards Section with fixed height
                        SizedBox(
                          height: 320, // Fixed height for workout cards
                          child: ListView(
                            scrollDirection: Axis.horizontal,
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
                          width: double.infinity,
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
                                text:
                                    'Maintain proper form for accurate counting',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
