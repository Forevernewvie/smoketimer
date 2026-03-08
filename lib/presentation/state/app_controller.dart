import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_defaults.dart';
import '../../domain/errors/app_exceptions.dart';
import '../../domain/models/record_period.dart';
import '../../domain/models/user_settings.dart';
import '../../services/logging/app_logger.dart';
import '../../services/notification_service.dart';
import 'app_bootstrap_loader.dart';
import 'app_config.dart';
import 'app_notification_coordinator.dart';
import 'app_ports.dart';
import 'app_record_policy.dart';
import 'app_settings_policy.dart';
import 'app_state.dart';

class AppController extends StateNotifier<AppState> {
  /// Creates application controller coordinating state, persistence and alerts.
  AppController({
    required SmokingRecordsStore smokingRepository,
    required SettingsStore settingsRepository,
    required AppBootstrapLoader bootstrapLoader,
    required AppNotificationCoordinator notificationCoordinator,
    required NotificationService notificationService,
    required DateTime Function() now,
    required AppConfig config,
  }) : _smokingRepository = smokingRepository,
       _settingsRepository = settingsRepository,
       _bootstrapLoader = bootstrapLoader,
       _notificationCoordinator = notificationCoordinator,
       _notificationService = notificationService,
       _now = now,
       _config = config,
       super(AppState.initial(now()));

  final SmokingRecordsStore _smokingRepository;
  final SettingsStore _settingsRepository;
  final AppBootstrapLoader _bootstrapLoader;
  final AppNotificationCoordinator _notificationCoordinator;
  final NotificationService _notificationService;
  final DateTime Function() _now;
  final AppConfig _config;
  static const _logger = AppLogger(namespace: 'app-controller');

  Timer? _ticker;
  bool _disposed = false;
  bool _didBootstrap = false;

  /// Bootstraps persisted data and transitions splash to onboarding or main.
  Future<void> bootstrap() async {
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    try {
      await _notificationService.initialize();
      final snapshot = await _bootstrapLoader.load();

      state = state.copyWith(
        isInitialized: true,
        now: _now(),
        records: snapshot.records,
        settings: snapshot.settings,
        meta: snapshot.meta,
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
        stage: snapshot.meta.hasCompletedOnboarding
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

  /// Starts a one-second ticker that refreshes the reactive current time.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(now: _now());
    });
  }

  /// Marks onboarding complete and persists the onboarding flag.
  Future<void> completeOnboarding() async {
    final updatedMeta = state.meta.copyWith(hasCompletedOnboarding: true);
    state = state.copyWith(meta: updatedMeta, stage: AppStage.main);
    await _runGuarded(
      operation: 'save_onboarding_meta',
      action: () => _settingsRepository.saveMeta(updatedMeta),
    );
  }

  /// Updates the selected record-period filter used by the history tab.
  void setRecordPeriod(RecordPeriod period) {
    state = state.copyWith(recordPeriod: period);
  }

  /// Adds a smoking record, persists it, and refreshes alert schedules.
  Future<void> addSmokingRecord() async {
    final previousState = state;
    final now = _now();
    final mutation = AppRecordPolicy.addRecord(
      currentRecords: state.records,
      currentMeta: state.meta,
      now: now,
    );

    state = state.copyWith(
      now: now,
      records: mutation.records,
      meta: mutation.meta,
    );

    await _runGuarded(
      operation: 'add_smoking_record',
      action: () async {
        await _smokingRepository.saveRecords(mutation.records);
        await _settingsRepository.saveMeta(mutation.meta);
        await _rescheduleNotifications();
      },
      onError: () {
        state = previousState;
      },
    );
  }

  /// Removes the latest smoking record, persists the rollback, and reschedules.
  Future<void> undoLastRecord() async {
    final mutation = AppRecordPolicy.undoLastRecord(
      currentRecords: state.records,
      currentMeta: state.meta,
    );
    if (mutation == null) {
      return;
    }

    final previousState = state;
    state = state.copyWith(records: mutation.records, meta: mutation.meta);

    await _runGuarded(
      operation: 'undo_last_record',
      action: () async {
        await _smokingRepository.saveRecords(mutation.records);
        await _settingsRepository.saveMeta(mutation.meta);
        await _rescheduleNotifications();
      },
      onError: () {
        state = previousState;
      },
    );
  }

  /// Toggles repeat alerts after checking notification permission when enabling.
  Future<bool> toggleRepeatEnabled() async {
    final enabling = !state.settings.repeatEnabled;
    if (enabling) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        return false;
      }
    }

    await _applySettingsUpdate(
      AppSettingsPolicy.toggleRepeatEnabled(state.settings),
    );
    return true;
  }

  /// Cycles alert interval through the supported preset values.
  Future<void> cycleIntervalMinutes() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.cycleIntervalMinutes(state.settings),
    );
  }

  /// Sets alert interval minutes within the supported policy range.
  Future<void> setIntervalMinutes(int minutes) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.setIntervalMinutes(state.settings, minutes),
    );
  }

  /// Cycles pre-alert lead time through the supported preset values.
  Future<void> cyclePreAlertMinutes() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.cyclePreAlertMinutes(state.settings),
    );
  }

  /// Sets pre-alert lead time within the supported policy range.
  Future<void> setPreAlertMinutes(int minutes) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.setPreAlertMinutes(state.settings, minutes),
    );
  }

  /// Updates the allowed notification time window if the range is valid.
  Future<void> updateAllowedTimeWindow({
    required int startMinutes,
    required int endMinutes,
  }) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.updateAllowedTimeWindow(
        state.settings,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
    );
  }

  /// Toggles active status of a weekday in the alert schedule.
  Future<void> toggleWeekday(int weekday) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.toggleWeekday(state.settings, weekday),
    );
  }

  /// Requests notification permission and refreshes schedules when granted.
  Future<bool> requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    if (granted) {
      await _rescheduleNotifications();
    }
    return granted;
  }

  /// Sends an immediate test notification using the current feedback settings.
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

  /// Toggles the 24-hour display preference without rescheduling alerts.
  Future<void> toggleUse24Hour() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.toggleUse24Hour(state.settings),
      reschedule: false,
    );
  }

  /// Cycles the ring reference mode used by the home progress gauge.
  Future<void> cycleRingReference() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.cycleRingReference(state.settings),
      reschedule: false,
    );
  }

  /// Toggles vibration feedback for alerts.
  Future<void> toggleVibration() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.toggleVibration(state.settings),
    );
  }

  /// Cycles the sound type used for local notifications.
  Future<void> cycleSoundType() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.cycleSoundType(state.settings),
    );
  }

  /// Toggles the explicit dark-mode preference without rescheduling alerts.
  Future<void> toggleDarkMode() async {
    await _applySettingsUpdate(
      AppSettingsPolicy.toggleDarkMode(state.settings),
      reschedule: false,
    );
  }

  /// Updates the pack price used for cost tracking.
  Future<void> setPackPrice(double packPrice) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.setPackPrice(state.settings, packPrice),
      reschedule: false,
    );
  }

  /// Updates the cigarettes-per-pack value used for cost tracking.
  Future<void> setCigarettesPerPack(int cigarettesPerPack) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.setCigarettesPerPack(state.settings, cigarettesPerPack),
      reschedule: false,
    );
  }

  /// Updates the currency code and symbol used for cost formatting.
  Future<void> setCurrencyCode(String currencyCode) async {
    await _applySettingsUpdate(
      AppSettingsPolicy.setCurrencyCode(state.settings, currencyCode),
      reschedule: false,
    );
  }

  /// Clears all app data and resets the app to the onboarding stage.
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

  /// Persists a possibly-null settings update and skips work for invalid input.
  Future<void> _applySettingsUpdate(
    UserSettings? settings, {
    bool reschedule = true,
  }) async {
    if (settings == null) {
      return;
    }
    await _updateSettings(settings, reschedule: reschedule);
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

  /// Rebuilds and re-registers upcoming alerts from the current state snapshot.
  Future<void> _rescheduleNotifications() async {
    final result = await _notificationCoordinator.reschedule(
      now: state.now,
      lastSmokingAt: state.meta.lastSmokingAt,
      records: state.records,
      settings: state.settings,
    );

    state = result.nextAlertAt == null
        ? state.copyWith(clearNextAlertAt: true)
        : state.copyWith(nextAlertAt: result.nextAlertAt);
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
