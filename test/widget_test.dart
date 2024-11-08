// test/widget_test.dart

import 'package:WorkoutAI/models/exercise_completion_model.dart';
import 'package:WorkoutAI/models/exercise_stats_model.dart';
import 'package:WorkoutAI/models/push_up_model.dart';
import 'package:WorkoutAI/models/sit_up_model.dart';
import 'package:WorkoutAI/models/user_manager.dart';
import 'package:WorkoutAI/models/weight_manager.dart';
import 'package:WorkoutAI/views/auth/login_screen.dart';
import 'package:WorkoutAI/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WorkoutAI/main.dart';
import 'package:WorkoutAI/models/auth_state.dart';
import 'package:WorkoutAI/services/auth_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Initialize auth service
    final authService = AuthService();
    final isAuthenticated = await authService.initializeAuth();

    // Build app with authentication state
    await tester.pumpWidget(MyApp(isAuthenticated: isAuthenticated));

    // Verify basic app structure
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MultiBlocProvider), findsOneWidget);
    expect(find.byType(AppWithAuth), findsOneWidget);

    // Verify bloc providers are initialized
    final context = tester.element(find.byType(AppWithAuth));
    expect(context.read<AuthCubit>(), isNotNull);
    expect(context.read<UserManager>(), isNotNull);
    expect(context.read<WeightManager>(), isNotNull);
    expect(context.read<PushUpCounter>(), isNotNull);
    expect(context.read<SitUpCounter>(), isNotNull);
    expect(context.read<ExerciseCompletion>(), isNotNull);
    expect(context.read<ExerciseStatsModel>(), isNotNull);

    // Verify initial route based on auth state
    final authState = context.read<AuthCubit>().state;
    if (authState.status == AuthStatus.authenticated) {
      expect(find.byType(SplashScreen), findsOneWidget);
    } else {
      expect(find.byType(LoginScreen), findsOneWidget);
    }
  });
}
