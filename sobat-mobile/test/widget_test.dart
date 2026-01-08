// This is a basic Flutter widget test for SOBAT HR app.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sobat_hr/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login screen elements are present.
    expect(find.text('SOBAT HR'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
  });
}
