import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/screens/step0_smoker_timer_screen.dart';
import 'package:smoke_timer/widgets/pen_design_widgets.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const MaterialApp(home: Step0SmokerTimerScreen()));

    // Allow first layout/paint.
    await tester.pump();
  }

  testWidgets('Onboarding page 1 ring is horizontally centered in hero card', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    final surfaceCard = find.byType(SurfaceCard).first;
    final ringGauge = find.byType(RingGauge).first;

    final cardCenter = tester.getCenter(surfaceCard);
    final ringCenter = tester.getCenter(ringGauge);

    expect((cardCenter.dx - ringCenter.dx).abs(), lessThanOrEqualTo(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding page 1 has no overflow on common viewports', (
    tester,
  ) async {
    for (final size in <Size>[
      const Size(360, 800),
      const Size(390, 844),
      const Size(411, 915),
    ]) {
      await pumpAtSize(tester, size);
      expect(tester.takeException(), isNull);
    }
  });
}
