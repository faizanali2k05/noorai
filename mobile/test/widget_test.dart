// Smoke test for the NoorAI app.
//
// Verifies the root widget builds and the splash screen renders without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noorai/main.dart';

void main() {
  testWidgets('NoorAIApp builds and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const NoorAIApp());

    // The MaterialApp root is present.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the first frame settle (splash uses animations/timers).
    await tester.pump(const Duration(milliseconds: 100));
  });
}
