// lib/views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout_ai/models/auth_state.dart';
import 'package:workout_ai/models/user_manager.dart';
import 'package:workout_ai/services/auth_service.dart';
import 'package:workout_ai/services/workout_info_service.dart';
import 'package:workout_ai/views/auth/login_screen.dart';
import 'package:workout_ai/views/pose_detection_view.dart';
import 'package:workout_ai/views/sit_up_detector_view.dart';
import 'package:workout_ai/widgets/progress_tracker.dart';
import 'package:workout_ai/widgets/workout_card.dart';
import 'dart:developer';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final WorkoutInfoService _workoutInfoService = WorkoutInfoService();
  final AuthService _authService = AuthService();
  List<WorkoutInfo> _workoutInfo = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setPortraitOrientation();
  }

  Future<void> _setPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> loadData() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!_authService.isAuthenticated()) {
        _navigateToLogin();
        return;
      }

      await _loadWorkoutInfo();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Data loading error: $e');
      if (!mounted) return;

      if (e.toString().contains('Authentication') || 
          e.toString().contains('Unauthorized')) {
        _navigateToLogin();
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutInfo() async {
    try {
      final workoutInfo = await _workoutInfoService.getWorkoutInfo();
      if (!mounted) return;
      
      setState(() {
        _workoutInfo = workoutInfo;
        _error = null;
      });
    } catch (e) {
      log('Error loading workout info: $e');
      if (!mounted) return;

      if (e.toString().contains('Authentication')) {
        _navigateToLogin();
      } else {
        setState(() {
          _workoutInfo = [];
          _error = e.toString();
        });
      }
      rethrow;
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManager>().clearUserInfo();
      context.read<AuthCubit>().loggedOut();
      AuthService.clearToken();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.logout();
      _navigateToLogin();
    } catch (e) {
      log('Logout error: $e');
      _navigateToLogin();
    }
  }

  Future<void> _startExercise(BuildContext context, Widget exerciseScreen) async {
  try {
    // Set landscape orientation before starting exercise
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;
    
    // Navigate to exercise screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => exerciseScreen,
      ),
    );

    // Reset orientation and reload data if needed
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (result == true && mounted) {
      await _loadData();
    }
  } catch (e) {
    debugPrint('Exercise screen error: $e');
  }
}

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/workout_logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: Colors.black,
                    );
                  },
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Workouts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                WorkoutCard(
                  title: 'Push-up Counter',
                  subtitle: 'Count your push-ups',
                  color: Colors.grey,
                  icon: Icons.fitness_center,
                  animationAsset: 'assets/push-up-animation.json',
                  onTap: () => _startExercise(
                    context,
                    const PoseDetectorView(),
                  ),
                ),
                const SizedBox(width: 16),
                WorkoutCard(
                  title: 'Sit-up Counter',
                  subtitle: 'Track your sit-ups',
                  color: Colors.black,
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
        ],
      ),
    );
  }

  Widget _buildProgress() {
    if (_error != null || _workoutInfo.isEmpty) {
      return ProgressTracker(
        workouts: _workoutInfo,
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadData,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ProgressTracker(
            workouts: _workoutInfo,
            isLoading: _isLoading,
            error: _error,
            onRetry: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to use',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FE54),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status != AuthStatus.authenticated) {
            _navigateToLogin();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8FE54)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFFE8FE54),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildWorkoutCards(),
                        const SizedBox(height: 24),
                        _buildProgress(),
                        const SizedBox(height: 24),
                        _buildInstructions(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    super.dispose();
  }
}