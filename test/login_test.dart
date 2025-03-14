import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimalsocialmedia/pages/login_page.dart';

void main() {
  testWidgets('Login Page Test', (WidgetTester tester) async {
    // Build the LoginPage widget.
    await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

    // Verify that the LoginPage contains the necessary widgets.
    expect(find.text('Q U I C K T A L E'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email, Password
    expect(find.text('Login'), findsOneWidget);

    // Enter text into the text fields.
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    // Tap the Login button.
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Add more assertions as needed.
  });
}