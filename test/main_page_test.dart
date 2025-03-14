import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimalsocialmedia/pages/home_page.dart';

void main() {
  testWidgets('Main Page Test', (WidgetTester tester) async {
    // Build the HomePage widget.
    await tester.pumpWidget(MaterialApp(home: HomePage()));

    // Verify that the HomePage contains the necessary widgets.
    // Add your specific widgets and assertions here.
    expect(find.text('Home'), findsOneWidget);

    // Add more assertions as needed.
  });
}