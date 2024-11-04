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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutInfoService _workoutInfoService = WorkoutInfoService();
  final AuthService _authService = AuthService();
  List<WorkoutInfo> _workoutInfo = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
    _setPortraitOrientation();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _setPortraitOrientation();
    super.dispose();
  }

  // Add tab change handler
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    // If switching to progress tab
    if (_tabController.index == 1) {
      // Check if we need to refresh
      if (_shouldRefreshData()) {
        _loadWorkoutInfo();
      }
    }
  }

  bool _shouldRefreshData() {
    if (_lastLoadTime == null) return true;

    // Refresh if last load was more than 30 seconds ago
    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);
    return difference.inSeconds > 30;
  }

  Future<void> _loadWorkoutInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutInfo = await _workoutInfoService.getWorkoutInfo();
      if (!mounted) return;

      setState(() {
        _workoutInfo = workoutInfo;
        _error = null;
        _lastLoadTime = DateTime.now();
        _isLoading = false;
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
          _isLoading = false;
        });
      }
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

  Future<void> _startExercise(
      BuildContext context, Widget exerciseScreen) async {
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

  String get _userName {
    final user = context.read<UserManager>().userInfo;
    return user?.username ?? '';
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFE8FE54),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildWorkoutCards(),
            const SizedBox(height: 24),
            // _buildInstructions(),
            // const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;

    // Get appropriate greeting based on time of day
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8FE54).withOpacity(0.2),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FE54).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getGreetingIcon(hour),
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE8FE54),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ready for today\'s workout?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGreetingIcon(int hour) {
    if (hour < 6) {
      return Icons.bedtime; // Night time
    } else if (hour < 12) {
      return Icons.wb_sunny; // Morning
    } else if (hour < 17) {
      return Icons.wb_cloudy; // Afternoon
    } else if (hour < 20) {
      return Icons.wb_twilight; // Evening
    } else {
      return Icons.nightlight; // Night
    }
  }

  Widget _buildQuickStats() {
    final totalWorkouts = _workoutInfo.length;
    final totalCalories = _workoutInfo.fold<double>(
      0,
      (sum, workout) => sum + workout.totalCalories,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Total Workouts',
                '$totalWorkouts',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Calories Burned',
                '${totalCalories.toStringAsFixed(1)} cal',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: _buildHeader(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE8FE54),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.home_outlined),
                text: 'Beranda',
              ),
              Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Progress',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadWorkoutInfo();
        _lastLoadTime =
            DateTime.now(); // Update last load time after manual refresh
      },
      color: const Color(0xFFE8FE54),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgress(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8FE54)),
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
          appBar: _buildAppBar(),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildHomeTab(),
                _buildWorkoutsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Hero(
          tag: 'app_logo',
          child: Image.asset(
            'assets/workout_logo.png',
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.fitness_center,
                size: 32,
                color: Colors.black,
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Update _buildWorkoutCards for better fit in tab view
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (_lastLoadTime != null)
                Text(
                  'Last updated: ${_formatLastUpdate(_lastLoadTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressTracker(
            workouts: _workoutInfo,
            isLoading: false, // We handle loading state in tab view
            error: _error,
            onRetry: _loadWorkoutInfo,
          ),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _loadData() async {
    await _loadWorkoutInfo();
  }

  Future<void> _setPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
