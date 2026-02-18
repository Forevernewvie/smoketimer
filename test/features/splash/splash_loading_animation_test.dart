import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/screens/step0_splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash loading bar animates', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Step0SplashScreen()));

    final finder = find.byKey(const Key('splash_loading_segment'));
    expect(finder, findsOneWidget);

    final before = tester.getTopLeft(finder).dx;
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.getTopLeft(finder).dx;

    // Should move horizontally over time.
    expect(after, isNot(equals(before)));
  });
}
