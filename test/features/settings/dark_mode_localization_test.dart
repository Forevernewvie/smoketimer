import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/l10n/app_localizations.dart';

import '../../test_utils.dart';

Future<ProviderContainer> _openSettingsWithLocale(
  WidgetTester tester, {
  required Locale locale,
}) async {
  setTestViewport(tester, size: const Size(390, 844));

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();

  final container = createTestContainer(
    prefs: prefs,
    now: () => DateTime(2026, 2, 20, 9, 0),
    autoDispose: false,
    locale: locale,
  );

  await pumpApp(tester, container);
  await tester.tap(find.text('건너뛰기'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing localization key falls back safely to key text', () {
    const l10n = AppLocalizations(Locale('en'));
    expect(l10n.lookup('unknown_key'), 'unknown_key');
  });

  testWidgets('shows Korean dark mode label for ko locale', (tester) async {
    final container = await _openSettingsWithLocale(
      tester,
      locale: const Locale('ko'),
    );

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('다크 모드'), findsOneWidget);
    expect(find.text('Dark Mode'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });

  testWidgets('shows English dark mode label for en locale', (tester) async {
    final container = await _openSettingsWithLocale(
      tester,
      locale: const Locale('en'),
    );

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('다크 모드'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });

  testWidgets('falls back safely for unsupported locale', (tester) async {
    final container = await _openSettingsWithLocale(
      tester,
      locale: const Locale('ja'),
    );

    expect(find.text('다크 모드'), findsOneWidget);
    expect(find.text('Dark Mode'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
