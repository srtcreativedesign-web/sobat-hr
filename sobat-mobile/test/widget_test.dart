// This is a basic Flutter widget test for SOBAT HR app.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobat_hr/main.dart';

void main() {
  testWidgets('App loads onboarding on first launch', (
    WidgetTester tester,
  ) async {
    // Set up fresh install state
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(prefs: prefs));

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify onboarding screen appears on first launch
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('App skips onboarding after completion', (
    WidgetTester tester,
  ) async {
    // Set up state as if onboarding was completed
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});

    final prefs = await SharedPreferences.getInstance();

    // Build our app
    await tester.pumpWidget(MyApp(prefs: prefs));

    // Wait for async operations
    await tester.pumpAndSettle();

    // Onboarding should not appear - should show login or home
    expect(find.text('Skip'), findsNothing);
  });
}
