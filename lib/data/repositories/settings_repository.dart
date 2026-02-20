import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/app_defaults.dart';
import '../../domain/errors/app_exceptions.dart';
import '../../domain/models/app_meta.dart';
import '../../domain/models/user_settings.dart';
import '../../services/logging/app_logger.dart';

class SettingsRepository {
  /// Creates repository that persists settings/meta into shared preferences.
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _logger = AppLogger(namespace: 'settings-repo');

  static const _settingsKey = 'user_settings_json';
  static const _metaKey = 'app_meta_json';

  /// Loads user settings from local storage.
  ///
  /// Returns default settings when storage is empty or payload is invalid.
  Future<UserSettings> loadSettings() async {
    try {
      final raw = _prefs.getString(_settingsKey);
      if (raw == null || raw.isEmpty) {
        return AppDefaults.defaultSettings();
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserSettings.fromJson(
        decoded,
        defaults: AppDefaults.defaultSettings(),
      );
    } catch (error, stackTrace) {
      _logger.warning('Invalid settings payload. Falling back to defaults.');
      _logger.error(
        'loadSettings failed',
        error: error,
        stackTrace: stackTrace,
      );
      return AppDefaults.defaultSettings();
    }
  }

  /// Persists user settings as JSON.
  Future<void> saveSettings(UserSettings settings) async {
    final success = await _prefs.setString(
      _settingsKey,
      jsonEncode(settings.toJson()),
    );
    if (!success) {
      throw const RepositoryException(
        code: 'settings_save_failed',
        message: 'Failed to save user settings.',
      );
    }
  }

  /// Loads app metadata from local storage.
  ///
  /// Returns defaults when storage is empty or payload is invalid.
  Future<AppMeta> loadMeta() async {
    try {
      final raw = _prefs.getString(_metaKey);
      if (raw == null || raw.isEmpty) {
        return AppDefaults.defaultMeta();
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppMeta.fromJson(decoded);
    } catch (error, stackTrace) {
      _logger.warning('Invalid app meta payload. Falling back to defaults.');
      _logger.error('loadMeta failed', error: error, stackTrace: stackTrace);
      return AppDefaults.defaultMeta();
    }
  }

  /// Persists app metadata as JSON.
  Future<void> saveMeta(AppMeta meta) async {
    final success = await _prefs.setString(_metaKey, jsonEncode(meta.toJson()));
    if (!success) {
      throw const RepositoryException(
        code: 'meta_save_failed',
        message: 'Failed to save app metadata.',
      );
    }
  }

  /// Clears settings and metadata payloads from local storage.
  Future<void> clear() async {
    final removeSettings = await _prefs.remove(_settingsKey);
    final removeMeta = await _prefs.remove(_metaKey);
    if (!removeSettings || !removeMeta) {
      throw const RepositoryException(
        code: 'settings_clear_failed',
        message: 'Failed to clear settings repository keys.',
      );
    }
  }
}
