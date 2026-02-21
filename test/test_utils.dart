import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/main.dart';
import 'package:smoke_timer/presentation/state/ads_providers.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/services/ads/ad_service.dart';
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
  AdService? adService,
  bool autoDispose = true,
  Locale? locale = const Locale('ko'),
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
      adServiceProvider.overrideWithValue(adService ?? NoopAdService()),
      appConfigProvider.overrideWithValue(config),
      appLocaleProvider.overrideWithValue(locale),
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
  int permissionRequests = 0;
  bool permissionGranted = true;
  final List<List<ScheduledAlert>> scheduledBatches = [];
  final List<Map<String, Object?>> shownTests = [];

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted;
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

class TestAdService implements AdService {
  TestAdService({
    BannerAdState initialState = const BannerAdState(
      status: AdBannerStatus.idle,
    ),
  }) : _state = ValueNotifier<BannerAdState>(initialState);

  final ValueNotifier<BannerAdState> _state;
  int loadCalls = 0;
  int disposeBannerCalls = 0;

  @override
  ValueListenable<BannerAdState> get bannerState => _state;

  @override
  void loadMainBanner() {
    loadCalls += 1;
  }

  @override
  void disposeBanner() {
    disposeBannerCalls += 1;
  }

  @override
  void disposeService() {
    _state.dispose();
  }

  void setState(BannerAdState state) {
    _state.value = state;
  }
}
