// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_1/models/auth_state.dart';
import 'package:test_1/models/user_manager.dart';
import 'package:test_1/services/auth_service.dart';
import 'package:test_1/services/workout_info_service.dart';
import 'package:test_1/views/pose_detection_view.dart';
import 'package:test_1/views/sit_up_detector_view.dart';
import 'package:test_1/widgets/progress_tracker.dart';
import 'package:test_1/widgets/workout_card.dart';
import 'package:test_1/widgets/user_info_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final WorkoutInfoService _workoutInfoService = WorkoutInfoService();
  List<WorkoutInfo> _workoutInfo = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkUserInfo();
    _loadWorkoutInfo();
  }

  Future<void> _loadWorkoutInfo() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final workoutInfo = await _workoutInfoService.getWorkoutInfo();
      if (mounted) {
        setState(() {
          _workoutInfo = workoutInfo;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workoutInfo = [];
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
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

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWorkoutInfo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Available Workouts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        WorkoutCard(
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
                        WorkoutCard(
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProgressTracker(
                    workouts: _workoutInfo,
                    isLoading: _isLoading,
                    error: _error,
                    onRetry: _loadWorkoutInfo,
                  ),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Workout AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                await AuthService().logout();
                if (mounted) {
                  context.read<UserManager>().clearUserInfo();
                  context.read<AuthCubit>().loggedOut();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            const SizedBox(height: 16),
            _buildInstructionItem(
              Icons.screen_rotation,
              'Position your device in landscape mode',
            ),
            _buildInstructionItem(
              Icons.visibility,
              'Make sure your full body is visible',
            ),
            _buildInstructionItem(
              Icons.fitness_center,
              'Maintain proper form for accurate counting',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
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
}
