import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings opens the bundled privacy policy screen', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const assetText = '# Smoke Timer 개인정보처리방침\n\n광고 및 로컬 저장 정보 안내';
    binding.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'docs/privacy_policy_ko.md') {
        final bytes = utf8.encode(assetText);
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      }
      return null;
    });
    addTearDown(() {
      binding.setMockMessageHandler('flutter/assets', null);
    });

    final container = createTestContainer(
      prefs: prefs,
      now: () => DateTime(2026, 3, 8, 9, 0),
      autoDispose: false,
    );

    await pumpApp(tester, container);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('개인정보처리방침'));
    await tester.tap(find.text('개인정보처리방침'));
    await tester.pumpAndSettle();

    expect(find.text('개인정보처리방침'), findsWidgets);
    expect(find.textContaining('Smoke Timer 개인정보처리방침'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
