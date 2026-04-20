import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic MaterialApp renders provided title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Idea Organizer Test Harness'),
        ),
      ),
    );

    expect(find.text('Idea Organizer Test Harness'), findsOneWidget);
  });
}
