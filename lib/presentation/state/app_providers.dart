import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/smoking_repository.dart';
import '../../services/alert_scheduler.dart';
import '../../services/notification_service.dart';
import 'app_config.dart';
import 'app_controller.dart';
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

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  final controller = AppController(
    smokingRepository: ref.watch(smokingRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(alertSchedulerProvider),
    notificationService: ref.watch(notificationServiceProvider),
    now: ref.watch(nowProvider),
    config: ref.watch(appConfigProvider),
  );

  controller.bootstrap();
  return controller;
});
