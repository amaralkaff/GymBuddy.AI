import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_1/models/exercise_completion_model.dart';
import 'package:test_1/models/exercise_stats_model.dart';
import 'package:test_1/models/push_up_model.dart';
import 'package:test_1/models/sit_up_model.dart';
import 'package:test_1/models/user_manager.dart';
import 'package:test_1/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserManager>(
          create: (context) => UserManager(),
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
      child: MaterialApp(
        title: 'Workout AI',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
