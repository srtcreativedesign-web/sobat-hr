// This is a basic Flutter widget test for SOBAT HR app.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sobat_hr/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final Map<String, Object> values = <String, Object>{'language_code': 'en'};
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(MyApp(prefs: prefs));

    // Verify that login screen elements are present.
    expect(find.text('SOBAT HR'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
  });
}
