import 'package:WorkoutAI/main.dart';
import 'package:WorkoutAI/views/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isAuthenticated: false));
    await tester.pumpAndSettle();

    // Verify basic app structure
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MultiBlocProvider), findsOneWidget);
    expect(find.byType(AppWithAuth), findsOneWidget);

    // Verify initial route shows login screen when not authenticated
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('App shows LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isAuthenticated: false));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
