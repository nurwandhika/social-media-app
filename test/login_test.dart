import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimalsocialmedia/pages/login_page.dart';

void main() {
  // Set up a minimal test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login Page UI Test', (WidgetTester tester) async {
    // Create a mock auth instance
    final mockAuth = MockFirebaseAuth();

    // Build the LoginPage widget with the mock
    await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            onTap: () {},
            auth: mockAuth, // Pass the mock auth instance
          ),
        )
    );

    // Verify UI elements exist
    expect(find.text('Q U I C K T A L E'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text("Don't have an account ?"), findsOneWidget);
    expect(find.text("  Register Here"), findsOneWidget); // Two spaces at the beginning

    // Enter text into fields
    await tester.enterText(find.byType(TextField).at(0), 'nurwan12345@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'nurwan12345');

    // Don't tap the login button as it will trigger Firebase authentication
  });
}