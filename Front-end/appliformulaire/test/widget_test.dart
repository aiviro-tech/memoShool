import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appliformulaire/main.dart';

void main() {
  testWidgets('App starts with login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(home: Connexion(), debugShowCheckedModeBanner: false),
    );

    // Verify that the login page is shown.
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
