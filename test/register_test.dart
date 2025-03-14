import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimalsocialmedia/pages/register_page.dart';
import 'package:mockito/mockito.dart';

// Mock Firestore class
class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  // Set up a minimal test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Register Page UI Test', (WidgetTester tester) async {
    // Create mock instances
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = MockFirestore();

    // Build the RegisterPage widget with the mocks
    await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(
            onTap: () {},
            auth: mockAuth,
            firestore: mockFirestore,
          ),
        )
    );

    // Verify UI elements exist with exact text matches
    expect(find.text('Q U I C K T A L E'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text("Already have an account ?"), findsOneWidget);
    expect(find.text("  Login Here"), findsOneWidget); // Two spaces at the beginning

    // Enter text into fields
    await tester.enterText(find.byType(TextField).at(0), 'testuser');
    await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');

    // Don't tap the register button as it will trigger Firebase operations
  });
}