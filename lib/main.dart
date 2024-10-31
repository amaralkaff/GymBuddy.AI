// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout_ai/models/auth_state.dart';
import 'package:workout_ai/models/exercise_completion_model.dart';
import 'package:workout_ai/models/exercise_stats_model.dart';
import 'package:workout_ai/models/push_up_model.dart';
import 'package:workout_ai/models/sit_up_model.dart';
import 'package:workout_ai/models/user_manager.dart';
import 'package:workout_ai/models/weight_manager.dart';
import 'package:workout_ai/services/auth_service.dart';
import 'package:workout_ai/views/auth/login_screen.dart';
import 'package:workout_ai/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final isAuthenticated = await authService.initializeAuth();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(MyApp(isAuthenticated: isAuthenticated));
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
      providers: [
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
      ],
      child: const AppWithAuth(),
    );
  }
}

class AppWithAuth extends StatefulWidget {
  const AppWithAuth({super.key});

  @override
  State<AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends State<AppWithAuth> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Workout AI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          navigatorKey: GlobalKey<NavigatorState>(),
          onGenerateRoute: (settings) {
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
          },
        );
      },
    );
  }
}