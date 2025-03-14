import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimalsocialmedia/pages/register_page.dart';

void main() {
  testWidgets('Register Page Test', (WidgetTester tester) async {
    // Build the RegisterPage widget.
    await tester.pumpWidget(MaterialApp(home: RegisterPage(onTap: () {})));

    // Verify that the RegisterPage contains the necessary widgets.
    expect(find.text('Q U I C K T A L E'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4)); // Username, Email, Password, Confirm Password
    expect(find.text('Register'), findsOneWidget);

    // Enter text into the text fields.
    await tester.enterText(find.byType(TextField).at(0), 'testuser');
    await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');

    // Tap the Register button.
    await tester.tap(find.text('Register'));
    await tester.pump();

    // Add more assertions as needed.
  });
}