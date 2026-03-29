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

typedef _SettingsMutation = UserSettings? Function(UserSettings current);

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
      _applyBootstrapSnapshot(snapshot);
      _startTicker();
      await _rescheduleNotifications();
      await _finishBootstrap(snapshot);
    } catch (error, stackTrace) {
      _logger.error('bootstrap failed', error: error, stackTrace: stackTrace);
      if (_disposed) {
        return;
      }

      _enterFallbackBootstrapState();
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
    final now = _now();
    final mutation = AppRecordPolicy.addRecord(
      currentRecords: state.records,
      currentMeta: state.meta,
      now: now,
    );
    await _commitRecordMutation(
      mutation,
      operation: 'add_smoking_record',
      timestamp: now,
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

    await _commitRecordMutation(mutation, operation: 'undo_last_record');
  }

  /// Toggles repeat alerts after checking notification permission when enabling.
  Future<bool> toggleRepeatEnabled() async {
    if (!await _canEnableRepeatAlerts()) {
      return false;
    }

    await _applySettingsPolicy(AppSettingsPolicy.toggleRepeatEnabled);
    return true;
  }

  /// Cycles alert interval through the supported preset values.
  Future<void> cycleIntervalMinutes() async {
    await _applySettingsPolicy(AppSettingsPolicy.cycleIntervalMinutes);
  }

  /// Sets alert interval minutes within the supported policy range.
  Future<void> setIntervalMinutes(int minutes) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.setIntervalMinutes(current, minutes),
    );
  }

  /// Cycles pre-alert lead time through the supported preset values.
  Future<void> cyclePreAlertMinutes() async {
    await _applySettingsPolicy(AppSettingsPolicy.cyclePreAlertMinutes);
  }

  /// Sets pre-alert lead time within the supported policy range.
  Future<void> setPreAlertMinutes(int minutes) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.setPreAlertMinutes(current, minutes),
    );
  }

  /// Updates the allowed notification time window if the range is valid.
  Future<void> updateAllowedTimeWindow({
    required int startMinutes,
    required int endMinutes,
  }) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.updateAllowedTimeWindow(
        current,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
    );
  }

  /// Toggles active status of a weekday in the alert schedule.
  Future<void> toggleWeekday(int weekday) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.toggleWeekday(current, weekday),
    );
  }

  /// Requests notification permission and refreshes schedules when granted.
  Future<bool> requestNotificationPermission() async {
    return _requestPermissionAndRun(_rescheduleNotifications);
  }

  /// Applies loaded bootstrap data before reactive services start.
  void _applyBootstrapSnapshot(AppBootstrapSnapshot snapshot) {
    state = state.copyWith(
      isInitialized: true,
      now: _now(),
      records: snapshot.records,
      settings: snapshot.settings,
      meta: snapshot.meta,
      stage: AppStage.splash,
    );
  }

  /// Sends an immediate test notification using the current feedback settings.
  Future<bool> sendTestNotification() async {
    return _requestPermissionAndRun(() {
      return _notificationService.showTest(
        title: AppDefaults.testNotificationTitle,
        body: AppDefaults.testNotificationBody,
        vibrationEnabled: state.settings.vibrationEnabled,
        soundType: state.settings.soundType,
      );
    });
  }

  /// Toggles the 24-hour display preference without rescheduling alerts.
  Future<void> toggleUse24Hour() async {
    await _applySettingsPolicy(
      AppSettingsPolicy.toggleUse24Hour,
      reschedule: false,
    );
  }

  /// Cycles the ring reference mode used by the home progress gauge.
  Future<void> cycleRingReference() async {
    await _applySettingsPolicy(
      AppSettingsPolicy.cycleRingReference,
      reschedule: false,
    );
  }

  /// Toggles vibration feedback for alerts.
  Future<void> toggleVibration() async {
    await _applySettingsPolicy(AppSettingsPolicy.toggleVibration);
  }

  /// Cycles the sound type used for local notifications.
  Future<void> cycleSoundType() async {
    await _applySettingsPolicy(AppSettingsPolicy.cycleSoundType);
  }

  /// Toggles the explicit dark-mode preference without rescheduling alerts.
  Future<void> toggleDarkMode() async {
    await _applySettingsPolicy(
      AppSettingsPolicy.toggleDarkMode,
      reschedule: false,
    );
  }

  /// Updates the pack price used for cost tracking.
  Future<void> setPackPrice(double packPrice) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.setPackPrice(current, packPrice),
      reschedule: false,
    );
  }

  /// Updates the cigarettes-per-pack value used for cost tracking.
  Future<void> setCigarettesPerPack(int cigarettesPerPack) async {
    await _applySettingsPolicy(
      (current) =>
          AppSettingsPolicy.setCigarettesPerPack(current, cigarettesPerPack),
      reschedule: false,
    );
  }

  /// Updates the currency code and symbol used for cost formatting.
  Future<void> setCurrencyCode(String currencyCode) async {
    await _applySettingsPolicy(
      (current) => AppSettingsPolicy.setCurrencyCode(current, currencyCode),
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

  /// Applies a settings policy mutation and skips work when no change exists.
  Future<void> _applySettingsPolicy(
    _SettingsMutation mutate, {
    bool reschedule = true,
  }) async {
    final settings = mutate(state.settings);
    if (settings == null) {
      return;
    }
    await _persistSettings(settings, reschedule: reschedule);
  }

  /// Applies a record mutation optimistically and rolls it back on failure.
  Future<void> _commitRecordMutation(
    AppRecordMutationResult mutation, {
    required String operation,
    DateTime? timestamp,
  }) async {
    final previousState = state;
    state = state.copyWith(
      now: timestamp ?? state.now,
      records: mutation.records,
      meta: mutation.meta,
    );

    await _runGuarded(
      operation: operation,
      action: () => _persistRecordMutation(mutation),
      onError: () {
        state = previousState;
      },
    );
  }

  /// Persists smoking records/meta and refreshes the alert schedule.
  Future<void> _persistRecordMutation(AppRecordMutationResult mutation) async {
    await _smokingRepository.saveRecords(mutation.records);
    await _settingsRepository.saveMeta(mutation.meta);
    await _rescheduleNotifications();
  }

  /// Waits for the splash delay, then enters onboarding or the main shell.
  Future<void> _finishBootstrap(AppBootstrapSnapshot snapshot) async {
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
  }

  /// Falls back to defaults when bootstrap fails so the app remains interactive.
  void _enterFallbackBootstrapState() {
    state = state.copyWith(
      isInitialized: true,
      now: _now(),
      stage: AppStage.onboarding,
    );
    _startTicker();
  }

  /// Persists settings and optionally reschedules alerts.
  Future<void> _persistSettings(
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

  /// Requests permission only when enabling repeat alerts from an off state.
  Future<bool> _canEnableRepeatAlerts() async {
    final enabling = !state.settings.repeatEnabled;
    return !enabling || await _notificationService.requestPermission();
  }

  /// Requests notification permission and runs follow-up work on success.
  Future<bool> _requestPermissionAndRun(
    Future<void> Function() onGranted,
  ) async {
    final granted = await _notificationService.requestPermission();
    if (granted) {
      await onGranted();
    }
    return granted;
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
