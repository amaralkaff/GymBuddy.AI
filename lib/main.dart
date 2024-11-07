import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/auth_state.dart';
import '../models/exercise_completion_model.dart';
import '../models/exercise_stats_model.dart';
import '../models/push_up_model.dart';
import '../models/sit_up_model.dart';
import '../models/user_manager.dart';
import '../models/weight_manager.dart';
import '../services/auth_service.dart';
import '../views/auth/login_screen.dart';
import '../views/splash_screen.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system optimizations
  await _configureSystem();

  // Initialize auth
  final authService = AuthService();
  final isAuthenticated = await authService.initializeAuth();

  // Run app with error handling
  runZonedGuarded(
    () => runApp(MyApp(isAuthenticated: isAuthenticated)),
    (error, stack) {
      debugPrint('Error caught by runZonedGuarded: $error\n$stack');
    },
  );
}

Future<void> _configureSystem() async {
  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Platform specific optimizations
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
    }

    // Optimize Flutter rendering
    SchedulerBinding.instance.ensureFrameCallbacksRegistered();

    // Set image cache size
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  } catch (e) {
    debugPrint('Error configuring system: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({
    super.key,
    this.isAuthenticated = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _createBlocProviders(),
      child: const AppWithAuth(),
    );
  }

  List<BlocProvider> _createBlocProviders() {
    return [
      BlocProvider<AuthCubit>(
        create: (context) {
          final cubit = AuthCubit();
          if (isAuthenticated) {
            cubit.initializeAuth(true);
          }
          return cubit;
        },
        lazy: false,
      ),
      BlocProvider<UserManager>(
        create: (context) => UserManager(),
      ),
      BlocProvider<WeightManager>(
        create: (context) => WeightManager(),
      ),
      BlocProvider<PushUpCounter>(
        create: (context) => PushUpCounter(),
      ),
      BlocProvider<SitUpCounter>(
        create: (context) => SitUpCounter(),
      ),
      BlocProvider<ExerciseCompletion>(
        create: (context) => ExerciseCompletion(),
      ),
      BlocProvider<ExerciseStatsModel>(
        create: (context) => ExerciseStatsModel(),
      ),
    ];
  }
}

class AppWithAuth extends StatefulWidget {
  const AppWithAuth({super.key});

  @override
  State<AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends State<AppWithAuth> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Free up resources
        imageCache.clear();
        imageCache.clearLiveImages();
        break;
      case AppLifecycleState.resumed:
        // Reinitialize if needed
        setState(() {});
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Workout AI',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: _buildTheme(),
          onGenerateRoute: (settings) => _generateRoute(settings, state),
          builder: (context, child) {
            // Add error boundary
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (child == null)
                  const Center(child: Text('Failed to load screen')),
              ],
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      platform: Theme.of(context).platform,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings, AuthState state) {
    try {
      switch (settings.name) {
        case '/':
          return MaterialPageRoute(
            builder: (_) => state.status == AuthStatus.authenticated
                ? const SplashScreen()
                : const LoginScreen(),
          );
        case '/login':
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
        case '/home':
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          );
        default:
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
      }
    } catch (e, stack) {
      debugPrint('Error generating route: $e\n$stack');
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      );
    }
  }
}
