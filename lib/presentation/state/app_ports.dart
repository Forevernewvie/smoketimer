import '../../domain/models/app_meta.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';

/// Contract for reading and writing smoking records.
abstract class SmokingRecordsStore {
  /// Loads all persisted smoking records.
  Future<List<SmokingRecord>> loadRecords();

  /// Persists the provided smoking records.
  Future<void> saveRecords(List<SmokingRecord> records);

  /// Clears every persisted smoking record.
  Future<void> clear();
}

/// Contract for reading and writing user settings and app metadata.
abstract class SettingsStore {
  /// Loads persisted user settings.
  Future<UserSettings> loadSettings();

  /// Persists the provided user settings.
  Future<void> saveSettings(UserSettings settings);

  /// Loads persisted application metadata.
  Future<AppMeta> loadMeta();

  /// Persists the provided application metadata.
  Future<void> saveMeta(AppMeta meta);

  /// Clears every persisted settings and metadata payload.
  Future<void> clear();
}

/// Contract for computing the next local notification schedule.
abstract class AlertSchedulingPolicy {
  /// Builds upcoming notification timestamps using the active scheduling policy.
  List<DateTime> buildUpcomingAlerts({
    required DateTime now,
    required DateTime? lastSmokingAt,
    required UserSettings settings,
    required int count,
  });
}
