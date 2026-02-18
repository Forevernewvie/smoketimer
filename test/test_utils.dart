import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/main.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/services/notification_service.dart';

void setTestViewport(
  WidgetTester tester, {
  Size size = const Size(1200, 2200),
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ProviderContainer createTestContainer({
  required SharedPreferences prefs,
  required DateTime Function() now,
  NotificationService? notificationService,
  bool autoDispose = true,
  AppConfig config = const AppConfig(
    splashDuration: Duration.zero,
    scheduleCount: 3,
  ),
}) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(
        notificationService ?? NoopNotificationService(),
      ),
      appConfigProvider.overrideWithValue(config),
      nowProvider.overrideWithValue(now),
    ],
  );
  if (autoDispose) {
    addTearDown(container.dispose);
  }
  return container;
}

Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SmokeTimerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class CapturingNotificationService implements NotificationService {
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  final List<List<ScheduledAlert>> scheduledBatches = [];
  final List<Map<String, Object?>> shownTests = [];

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
  }

  @override
  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  }) async {
    scheduledBatches.add(List<ScheduledAlert>.unmodifiable(alerts));
  }

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  }) async {
    shownTests.add({
      'title': title,
      'body': body,
      'vibrationEnabled': vibrationEnabled,
      'soundType': soundType,
    });
  }
}
