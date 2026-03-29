import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/widgets/pen_design_widgets.dart';

import '../../test_utils.dart';

const _baseChipText = '기록 후 시작';
const _longChipText = '다음 알림 다시 시작';

Widget _buildStatusCard({required String label, required String chipText}) {
  return Builder(
    builder: (context) {
      final ui = SmokeUiTheme.of(context);
      return SurfaceCard(
        color: ui.surfaceAlt,
        strokeColor: ui.border,
        padding: const EdgeInsets.all(10),
        cornerRadius: SmokeUiRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveHeaderRow(
              leading: Text(
                label,
                style: TextStyle(
                  color: ui.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: StatusChip(
                text: chipText,
                icon: Icons.notifications_paused_outlined,
                foregroundColor: SmokeUiPalette.info,
                backgroundColor: SmokeUiPalette.infoSoft,
                borderColor: Color(0xFF9BD9E8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '첫 기록 후 타이머가 시작돼요',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCardColumn() {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _buildStatusCard(label: '지금 상태', chipText: _baseChipText),
      const SizedBox(height: SmokeUiSpacing.sm),
      Builder(
        builder: (context) {
          final ui = SmokeUiTheme.of(context);
          return SurfaceCard(
            color: ui.surfaceAlt,
            strokeColor: ui.border,
            padding: const EdgeInsets.all(10),
            cornerRadius: SmokeUiRadius.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveHeaderRow(
                  leading: Text(
                    '다음 알림',
                    style: TextStyle(
                      color: ui.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const StatusChip(
                    text: _longChipText,
                    icon: Icons.notifications_active_outlined,
                    foregroundColor: SmokeUiPalette.info,
                    backgroundColor: SmokeUiPalette.infoSoft,
                    borderColor: Color(0xFF9BD9E8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '카드 본문과 trailing action이 서로 겹치지 않아야 해요.',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Size viewport,
  required double textScale,
  required Brightness brightness,
}) async {
  setTestViewport(tester, size: viewport);
  tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: SmokeUiTheme.light.background,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SmokeUiTheme.dark.background,
      ),
      home: Scaffold(body: _buildCardColumn()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chipFinder(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(StatusChip));
}

double _expectedChipWidth(String text, {required double textScale}) {
  const iconWidth = 14.0;
  const gapWidth = SmokeUiSpacing.xxs;
  const horizontalPadding = 20.0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(textScale),
    maxLines: 1,
  )..layout();
  return horizontalPadding + iconWidth + gapWidth + painter.width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'home status headers stack long chips on narrow width with large text scale',
    (tester) async {
      await _pumpHarness(
        tester,
        viewport: const Size(320, 690),
        textScale: 1.6,
        brightness: Brightness.light,
      );

      expect(tester.takeException(), isNull);

      final firstLabel = find.text('지금 상태');
      final firstChipText = find.text(_baseChipText);
      final secondLabel = find.text('다음 알림');
      final secondChipText = find.text(_longChipText);

      expect(
        tester.getTopLeft(firstChipText).dy,
        greaterThan(tester.getBottomLeft(firstLabel).dy),
      );
      expect(
        tester.getTopLeft(secondChipText).dy,
        greaterThan(tester.getBottomLeft(secondLabel).dy),
      );

      expect(
        tester.getSize(_chipFinder(_baseChipText)).width,
        greaterThanOrEqualTo(_expectedChipWidth(_baseChipText, textScale: 1.6)),
      );
      expect(
        tester.getSize(_chipFinder(_longChipText)).width,
        greaterThanOrEqualTo(_expectedChipWidth(_longChipText, textScale: 1.6)),
      );
    },
  );

  testWidgets(
    'home status headers keep chips on the same row on standard width in dark mode',
    (tester) async {
      await _pumpHarness(
        tester,
        viewport: const Size(390, 844),
        textScale: 1.0,
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);

      final firstLabel = find.text('지금 상태');
      final firstChipText = find.text(_baseChipText);

      expect(
        tester.getTopLeft(firstChipText).dx,
        greaterThan(tester.getTopRight(firstLabel).dx),
      );
      expect(
        (tester.getTopLeft(firstChipText).dy - tester.getTopLeft(firstLabel).dy)
            .abs(),
        lessThan(8),
      );
      expect(
        tester.getSize(_chipFinder(_baseChipText)).width,
        greaterThanOrEqualTo(_expectedChipWidth(_baseChipText, textScale: 1.0)),
      );
    },
  );
}
