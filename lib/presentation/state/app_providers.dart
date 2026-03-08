import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/smoking_repository.dart';
import '../../services/alert_scheduler.dart';
import '../../services/notification_service.dart';
import 'app_bootstrap_loader.dart';
import 'app_config.dart';
import 'app_controller.dart';
import 'app_notification_coordinator.dart';
import 'app_ports.dart';
import 'app_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden.');
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig();
});

final appLocaleProvider = Provider<Locale?>((ref) {
  return null;
});

final nowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FlutterNotificationService();
});

final smokingRepositoryProvider = Provider<SmokingRepository>((ref) {
  return SmokingRepository(ref.watch(sharedPreferencesProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPreferencesProvider));
});

final alertSchedulerProvider = Provider<AlertScheduler>((ref) {
  return const AlertScheduler();
});

final smokingRecordsStoreProvider = Provider<SmokingRecordsStore>((ref) {
  return ref.watch(smokingRepositoryProvider);
});

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return ref.watch(settingsRepositoryProvider);
});

final alertSchedulingPolicyProvider = Provider<AlertSchedulingPolicy>((ref) {
  return ref.watch(alertSchedulerProvider);
});

final appBootstrapLoaderProvider = Provider<AppBootstrapLoader>((ref) {
  return AppBootstrapLoader(
    smokingRepository: ref.watch(smokingRecordsStoreProvider),
    settingsRepository: ref.watch(settingsStoreProvider),
  );
});

final appNotificationCoordinatorProvider = Provider<AppNotificationCoordinator>(
  (ref) {
    return AppNotificationCoordinator(
      scheduler: ref.watch(alertSchedulingPolicyProvider),
      notificationService: ref.watch(notificationServiceProvider),
      config: ref.watch(appConfigProvider),
    );
  },
);

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  final controller = AppController(
    smokingRepository: ref.watch(smokingRecordsStoreProvider),
    settingsRepository: ref.watch(settingsStoreProvider),
    bootstrapLoader: ref.watch(appBootstrapLoaderProvider),
    notificationCoordinator: ref.watch(appNotificationCoordinatorProvider),
    notificationService: ref.watch(notificationServiceProvider),
    now: ref.watch(nowProvider),
    config: ref.watch(appConfigProvider),
  );

  controller.bootstrap();
  return controller;
});
