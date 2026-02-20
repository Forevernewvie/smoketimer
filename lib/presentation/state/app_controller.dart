import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/smoking_repository.dart';
import '../../domain/app_defaults.dart';
import '../../domain/errors/app_exceptions.dart';
import '../../domain/models/app_meta.dart';
import '../../domain/models/record_period.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';
import '../../services/alert_scheduler.dart';
import '../../services/cost_stats_service.dart';
import '../../services/logging/app_logger.dart';
import '../../services/notification_service.dart';
import '../../services/smoking_stats_service.dart';
import 'app_config.dart';
import 'app_state.dart';

class AppController extends StateNotifier<AppState> {
  /// Creates application controller coordinating state, persistence and alerts.
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
  static const _logger = AppLogger(namespace: 'app-controller');

  Timer? _ticker;
  bool _disposed = false;
  bool _didBootstrap = false;

  /// Bootstraps persisted data and transitions splash to onboarding/main.
  Future<void> bootstrap() async {
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    try {
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
    } catch (error, stackTrace) {
      _logger.error('bootstrap failed', error: error, stackTrace: stackTrace);
      if (_disposed) {
        return;
      }
      // Fail-safe: keep app interactive with defaults instead of crashing.
      state = state.copyWith(
        isInitialized: true,
        now: _now(),
        stage: AppStage.onboarding,
      );
      _startTicker();
    }
  }

  /// Starts one-second ticker that updates reactive "now" state.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(now: _now());
    });
  }

  /// Marks onboarding complete and persists metadata.
  Future<void> completeOnboarding() async {
    final updatedMeta = state.meta.copyWith(hasCompletedOnboarding: true);
    state = state.copyWith(meta: updatedMeta, stage: AppStage.main);
    await _runGuarded(
      operation: 'save_onboarding_meta',
      action: () => _settingsRepository.saveMeta(updatedMeta),
    );
  }

  /// Updates selected record period filter.
  void setRecordPeriod(RecordPeriod period) {
    state = state.copyWith(recordPeriod: period);
  }

  /// Adds a smoking record and re-registers next alert schedules.
  Future<void> addSmokingRecord() async {
    final previousState = state;
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

    await _runGuarded(
      operation: 'add_smoking_record',
      action: () async {
        await _smokingRepository.saveRecords(updatedRecords);
        await _settingsRepository.saveMeta(updatedMeta);
        await _rescheduleNotifications();
      },
      onError: () {
        state = previousState;
      },
    );
  }

  /// Removes latest smoking record and re-registers next alert schedules.
  Future<void> undoLastRecord() async {
    if (state.records.isEmpty) {
      return;
    }

    final previousState = state;
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

    await _runGuarded(
      operation: 'undo_last_record',
      action: () async {
        await _smokingRepository.saveRecords(updatedRecords);
        await _settingsRepository.saveMeta(updatedMeta);
        await _rescheduleNotifications();
      },
      onError: () {
        state = previousState;
      },
    );
  }

  /// Toggles repeat alert setting with permission gate when enabling.
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

  /// Cycles interval through predefined options.
  Future<void> cycleIntervalMinutes() async {
    final current = state.settings.intervalMinutes;
    final options = AppDefaults.intervalOptions;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];

    final updated = state.settings.copyWith(intervalMinutes: next);
    await _updateSettings(updated);
  }

  /// Sets interval minutes within policy range.
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

  /// Cycles pre-alert minute options.
  Future<void> cyclePreAlertMinutes() async {
    final current = state.settings.preAlertMinutes;
    final options = AppDefaults.preAlertOptions;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];

    final updated = state.settings.copyWith(preAlertMinutes: next);
    await _updateSettings(updated);
  }

  /// Updates allowed notification time window.
  Future<void> updateAllowedTimeWindow({
    required int startMinutes,
    required int endMinutes,
  }) async {
    if (startMinutes < AppDefaults.allowedWindowMinMinutes ||
        endMinutes > AppDefaults.allowedWindowMaxMinutes ||
        endMinutes <= startMinutes) {
      return;
    }

    final updated = state.settings.copyWith(
      allowedStartMinutes: startMinutes,
      allowedEndMinutes: endMinutes,
    );

    await _updateSettings(updated);
  }

  /// Toggles active status of a weekday in alert schedule.
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

  /// Requests permission and refreshes schedules when granted.
  Future<bool> requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    if (granted) {
      // Re-register schedules after permission is granted so users don't have to
      // "toggle" any settings to start receiving alerts.
      await _rescheduleNotifications();
    }
    return granted;
  }

  /// Sends immediate test notification with current sound/vibration settings.
  Future<bool> sendTestNotification() async {
    final granted = await _notificationService.requestPermission();
    if (!granted) {
      return false;
    }

    await _notificationService.showTest(
      title: AppDefaults.testNotificationTitle,
      body: AppDefaults.testNotificationBody,
      vibrationEnabled: state.settings.vibrationEnabled,
      soundType: state.settings.soundType,
    );
    return true;
  }

  /// Toggles 24-hour display preference.
  Future<void> toggleUse24Hour() async {
    final updated = state.settings.copyWith(
      use24Hour: !state.settings.use24Hour,
    );
    await _updateSettings(updated, reschedule: false);
  }

  /// Cycles ring reference mode for home progress gauge.
  Future<void> cycleRingReference() async {
    final updated = state.settings.copyWith(
      ringReference: state.settings.ringReference == RingReference.lastSmoking
          ? RingReference.dayStart
          : RingReference.lastSmoking,
    );

    await _updateSettings(updated, reschedule: false);
  }

  /// Toggles vibration preference.
  Future<void> toggleVibration() async {
    final updated = state.settings.copyWith(
      vibrationEnabled: !state.settings.vibrationEnabled,
    );

    await _updateSettings(updated);
  }

  /// Cycles sound type preference.
  Future<void> cycleSoundType() async {
    final options = AppDefaults.soundTypeOptions;
    final index = options.indexOf(state.settings.soundType);
    final next = options[(index + 1) % options.length];
    final updated = state.settings.copyWith(soundType: next);

    await _updateSettings(updated);
  }

  /// Updates pack price for cost tracking calculations.
  Future<void> setPackPrice(double packPrice) async {
    final normalized = CostStatsService.normalizePackPrice(packPrice);
    if (normalized == state.settings.packPrice) {
      return;
    }

    final updated = state.settings.copyWith(packPrice: normalized);
    await _updateSettings(updated, reschedule: false);
  }

  /// Updates cigarettes-per-pack for cost tracking calculations.
  Future<void> setCigarettesPerPack(int cigarettesPerPack) async {
    final normalized = CostStatsService.normalizeCigarettesPerPack(
      cigarettesPerPack,
    );
    if (normalized == state.settings.cigarettesPerPack) {
      return;
    }

    final updated = state.settings.copyWith(cigarettesPerPack: normalized);
    await _updateSettings(updated, reschedule: false);
  }

  /// Updates currency code and symbol used in cost display formatting.
  Future<void> setCurrencyCode(String currencyCode) async {
    final normalized = currencyCode.trim().toUpperCase();
    final nextCode = normalized.isEmpty
        ? AppDefaults.defaultCurrencyCode
        : normalized;
    final nextSymbol = CostStatsService.resolveCurrencySymbol(nextCode);

    if (nextCode == state.settings.currencyCode &&
        nextSymbol == state.settings.currencySymbol) {
      return;
    }

    final updated = state.settings.copyWith(
      currencyCode: nextCode,
      currencySymbol: nextSymbol,
    );
    await _updateSettings(updated, reschedule: false);
  }

  /// Clears all app data and resets app state to onboarding stage.
  Future<void> resetAllData() async {
    await _runGuarded(
      operation: 'reset_all_data',
      action: () async {
        await _smokingRepository.clear();
        await _settingsRepository.clear();
        await _notificationService.cancelAll();
      },
      rethrowErrors: true,
    );

    final now = _now();
    state = AppState.initial(
      now,
    ).copyWith(isInitialized: true, stage: AppStage.onboarding);
  }

  /// Persists settings and optionally reschedules alerts.
  Future<void> _updateSettings(
    UserSettings settings, {
    bool reschedule = true,
  }) async {
    final previousSettings = state.settings;
    state = state.copyWith(settings: settings);
    await _runGuarded(
      operation: 'update_settings',
      action: () async {
        await _settingsRepository.saveSettings(settings);
        if (reschedule) {
          await _rescheduleNotifications();
        }
      },
      onError: () {
        state = state.copyWith(settings: previousSettings);
      },
    );
  }

  /// Rebuilds and re-registers upcoming alerts from current state.
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
          id: AppDefaults.scheduledAlertIdBase + index,
          at: upcoming[index],
          title: AppDefaults.alertNotificationTitle,
          body: AppDefaults.alertNotificationBody,
        ),
      );
    }

    await _notificationService.scheduleAlerts(
      alerts: alerts,
      vibrationEnabled: state.settings.vibrationEnabled,
      soundType: state.settings.soundType,
    );
  }

  /// Executes a stateful async operation with standardized logging and fallback.
  Future<void> _runGuarded({
    required String operation,
    required Future<void> Function() action,
    void Function()? onError,
    bool rethrowErrors = false,
  }) async {
    try {
      await action();
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'operation failed: $operation',
        error: error,
        stackTrace: stackTrace,
      );
      onError?.call();
      if (rethrowErrors) {
        rethrow;
      }
    } catch (error, stackTrace) {
      _logger.error(
        'unexpected failure: $operation',
        error: error,
        stackTrace: stackTrace,
      );
      onError?.call();
      if (rethrowErrors) {
        rethrow;
      }
    }
  }

  /// Disposes ticker and marks controller disposed to stop async updates.
  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
