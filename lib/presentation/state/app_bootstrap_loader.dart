import '../../domain/models/app_meta.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';
import '../../services/logging/app_logger.dart';
import '../../services/smoking_stats_service.dart';
import 'app_ports.dart';

/// Immutable snapshot returned after loading persisted application state.
class AppBootstrapSnapshot {
  /// Creates a normalized bootstrap snapshot.
  const AppBootstrapSnapshot({
    required this.records,
    required this.settings,
    required this.meta,
  });

  /// Persisted smoking records available at startup.
  final List<SmokingRecord> records;

  /// Persisted user settings available at startup.
  final UserSettings settings;

  /// Persisted app metadata normalized against stored records.
  final AppMeta meta;
}

/// Loads persisted app state and normalizes metadata before the UI consumes it.
class AppBootstrapLoader {
  /// Creates a bootstrap loader with explicit persistence dependencies.
  const AppBootstrapLoader({
    required SmokingRecordsStore smokingRepository,
    required SettingsStore settingsRepository,
    AppLogger logger = const AppLogger(namespace: 'bootstrap-loader'),
  }) : _smokingRepository = smokingRepository,
       _settingsRepository = settingsRepository,
       _logger = logger;

  final SmokingRecordsStore _smokingRepository;
  final SettingsStore _settingsRepository;
  final AppLogger _logger;

  /// Loads records, settings, and metadata, then reconciles stale last-smoking state.
  Future<AppBootstrapSnapshot> load() async {
    final recordsFuture = _smokingRepository.loadRecords();
    final settingsFuture = _settingsRepository.loadSettings();
    final metaFuture = _settingsRepository.loadMeta();

    final loadedRecords = await recordsFuture;
    final loadedSettings = await settingsFuture;
    var loadedMeta = await metaFuture;

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
      _logger.info('normalized bootstrap meta against persisted records');
    }

    return AppBootstrapSnapshot(
      records: List<SmokingRecord>.unmodifiable(loadedRecords),
      settings: loadedSettings,
      meta: loadedMeta,
    );
  }
}
