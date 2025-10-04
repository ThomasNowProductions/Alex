// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alex/main.dart';

void main() {
  testWidgets('Alex app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FraintedApp());

    // Verify that the Alex title is displayed.
    expect(find.text('Alex'), findsOneWidget);

    // Verify that the welcome message is present.
    expect(find.text('Ask me anything'), findsOneWidget);

    // Verify that the message input field is present.
    expect(find.byType(TextField), findsOneWidget);

    // Verify that the send button is present.
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Verify that the glowing icon is present.
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
