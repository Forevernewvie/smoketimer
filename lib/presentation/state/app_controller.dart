import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/smoking_repository.dart';
import '../../domain/app_defaults.dart';
import '../../domain/models/app_meta.dart';
import '../../domain/models/record_period.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';
import '../../services/alert_scheduler.dart';
import '../../services/notification_service.dart';
import '../../services/smoking_stats_service.dart';
import 'app_config.dart';
import 'app_state.dart';

class AppController extends StateNotifier<AppState> {
  AppController({
    required SmokingRepository smokingRepository,
    required SettingsRepository settingsRepository,
    required AlertScheduler scheduler,
    required NotificationService notificationService,
    required DateTime Function() now,
    required AppConfig config,
  }) : _smokingRepository = smokingRepository,
       _settingsRepository = settingsRepository,
       _scheduler = scheduler,
       _notificationService = notificationService,
       _now = now,
       _config = config,
       super(AppState.initial(now()));

  final SmokingRepository _smokingRepository;
  final SettingsRepository _settingsRepository;
  final AlertScheduler _scheduler;
  final NotificationService _notificationService;
  final DateTime Function() _now;
  final AppConfig _config;

  Timer? _ticker;
  bool _disposed = false;
  bool _didBootstrap = false;

  Future<void> bootstrap() async {
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    await _notificationService.initialize();

    final results = await Future.wait<dynamic>([
      _smokingRepository.loadRecords(),
      _settingsRepository.loadSettings(),
      _settingsRepository.loadMeta(),
    ]);

    final loadedRecords = results[0] as List<SmokingRecord>;
    final loadedSettings = results[1] as UserSettings;
    var loadedMeta = results[2] as AppMeta;

    final normalizedLastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      loadedMeta.lastSmokingAt,
      loadedRecords,
    );

    if (normalizedLastSmokingAt != loadedMeta.lastSmokingAt) {
      loadedMeta = loadedMeta.copyWith(
        lastSmokingAt: normalizedLastSmokingAt,
        clearLastSmokingAt: normalizedLastSmokingAt == null,
      );
      await _settingsRepository.saveMeta(loadedMeta);
    }

    state = state.copyWith(
      isInitialized: true,
      now: _now(),
      records: loadedRecords,
      settings: loadedSettings,
      meta: loadedMeta,
      stage: AppStage.splash,
    );

    _startTicker();
    await _rescheduleNotifications();

    if (_config.splashDuration > Duration.zero) {
      await Future<void>.delayed(_config.splashDuration);
    }

    if (_disposed) {
      return;
    }

    state = state.copyWith(
      now: _now(),
      stage: loadedMeta.hasCompletedOnboarding
          ? AppStage.main
          : AppStage.onboarding,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(now: _now());
    });
  }

  Future<void> completeOnboarding() async {
    final updatedMeta = state.meta.copyWith(hasCompletedOnboarding: true);
    state = state.copyWith(meta: updatedMeta, stage: AppStage.main);
    await _settingsRepository.saveMeta(updatedMeta);
  }

  void setRecordPeriod(RecordPeriod period) {
    state = state.copyWith(recordPeriod: period);
  }

  Future<void> addSmokingRecord() async {
    final now = _now();
    final newRecord = SmokingRecord(
      id: 'record_${now.microsecondsSinceEpoch}',
      timestamp: now,
      count: 1,
    );

    final updatedRecords = [newRecord, ...state.records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final updatedMeta = state.meta.copyWith(lastSmokingAt: now);

    state = state.copyWith(
      now: now,
      records: updatedRecords,
      meta: updatedMeta,
    );

    await _smokingRepository.saveRecords(updatedRecords);
    await _settingsRepository.saveMeta(updatedMeta);
    await _rescheduleNotifications();
  }

  Future<void> undoLastRecord() async {
    if (state.records.isEmpty) {
      return;
    }

    final updatedRecords = state.records.sublist(1);
    final updatedLastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      null,
      updatedRecords,
    );

    final updatedMeta = state.meta.copyWith(
      lastSmokingAt: updatedLastSmokingAt,
      clearLastSmokingAt: updatedLastSmokingAt == null,
    );

    state = state.copyWith(records: updatedRecords, meta: updatedMeta);

    await _smokingRepository.saveRecords(updatedRecords);
    await _settingsRepository.saveMeta(updatedMeta);
    await _rescheduleNotifications();
  }

  Future<bool> toggleRepeatEnabled() async {
    final enabling = !state.settings.repeatEnabled;
    if (enabling) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        return false;
      }
    }

    final updated = state.settings.copyWith(repeatEnabled: enabling);
    await _updateSettings(updated);
    return true;
  }

  Future<void> cycleIntervalMinutes() async {
    final current = state.settings.intervalMinutes;
    final options = AppDefaults.intervalOptions;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];

    final updated = state.settings.copyWith(intervalMinutes: next);
    await _updateSettings(updated);
  }

  Future<void> setIntervalMinutes(int minutes) async {
    final normalized = minutes
        .clamp(AppDefaults.minIntervalMinutes, AppDefaults.maxIntervalMinutes)
        .toInt();

    if (normalized == state.settings.intervalMinutes) {
      return;
    }

    final updated = state.settings.copyWith(intervalMinutes: normalized);
    await _updateSettings(updated);
  }

  Future<void> cyclePreAlertMinutes() async {
    final current = state.settings.preAlertMinutes;
    final options = AppDefaults.preAlertOptions;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];

    final updated = state.settings.copyWith(preAlertMinutes: next);
    await _updateSettings(updated);
  }

  Future<void> updateAllowedTimeWindow({
    required int startMinutes,
    required int endMinutes,
  }) async {
    if (startMinutes < 0 || endMinutes > 1440 || endMinutes <= startMinutes) {
      return;
    }

    final updated = state.settings.copyWith(
      allowedStartMinutes: startMinutes,
      allowedEndMinutes: endMinutes,
    );

    await _updateSettings(updated);
  }

  Future<void> toggleWeekday(int weekday) async {
    final updatedWeekdays = {...state.settings.activeWeekdays};
    if (updatedWeekdays.contains(weekday)) {
      updatedWeekdays.remove(weekday);
    } else {
      updatedWeekdays.add(weekday);
    }

    final updated = state.settings.copyWith(activeWeekdays: updatedWeekdays);
    await _updateSettings(updated);
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    if (granted) {
      // Re-register schedules after permission is granted so users don't have to
      // "toggle" any settings to start receiving alerts.
      await _rescheduleNotifications();
    }
    return granted;
  }

  Future<bool> sendTestNotification() async {
    final granted = await _notificationService.requestPermission();
    if (!granted) {
      return false;
    }

    await _notificationService.showTest(
      title: '흡연 타이머 테스트',
      body: '테스트 알림이 정상 동작했습니다.',
      vibrationEnabled: state.settings.vibrationEnabled,
      soundType: state.settings.soundType,
    );
    return true;
  }

  Future<void> toggleUse24Hour() async {
    final updated = state.settings.copyWith(
      use24Hour: !state.settings.use24Hour,
    );
    await _updateSettings(updated, reschedule: false);
  }

  Future<void> cycleRingReference() async {
    final updated = state.settings.copyWith(
      ringReference: state.settings.ringReference == RingReference.lastSmoking
          ? RingReference.dayStart
          : RingReference.lastSmoking,
    );

    await _updateSettings(updated, reschedule: false);
  }

  Future<void> toggleVibration() async {
    final updated = state.settings.copyWith(
      vibrationEnabled: !state.settings.vibrationEnabled,
    );

    await _updateSettings(updated);
  }

  Future<void> cycleSoundType() async {
    final options = AppDefaults.soundTypeOptions;
    final index = options.indexOf(state.settings.soundType);
    final next = options[(index + 1) % options.length];
    final updated = state.settings.copyWith(soundType: next);

    await _updateSettings(updated);
  }

  Future<void> resetAllData() async {
    await _smokingRepository.clear();
    await _settingsRepository.clear();
    await _notificationService.cancelAll();

    final now = _now();
    state = AppState.initial(
      now,
    ).copyWith(isInitialized: true, stage: AppStage.onboarding);
  }

  Future<void> _updateSettings(
    UserSettings settings, {
    bool reschedule = true,
  }) async {
    state = state.copyWith(settings: settings);
    await _settingsRepository.saveSettings(settings);
    if (reschedule) {
      await _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    final lastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      state.meta.lastSmokingAt,
      state.records,
    );

    final upcoming = _scheduler.buildUpcomingAlerts(
      now: state.now,
      lastSmokingAt: lastSmokingAt,
      settings: state.settings,
      count: _config.scheduleCount,
    );

    if (upcoming.isEmpty) {
      state = state.copyWith(clearNextAlertAt: true);
    } else {
      state = state.copyWith(nextAlertAt: upcoming.first);
    }

    final alerts = <ScheduledAlert>[];
    for (var index = 0; index < upcoming.length; index += 1) {
      alerts.add(
        ScheduledAlert(
          id: 10_000 + index,
          at: upcoming[index],
          title: '흡연 타이머',
          body: '다음 흡연 간격 알림입니다.',
        ),
      );
    }

    await _notificationService.scheduleAlerts(
      alerts: alerts,
      vibrationEnabled: state.settings.vibrationEnabled,
      soundType: state.settings.soundType,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
