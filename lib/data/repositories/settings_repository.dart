import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/app_defaults.dart';
import '../../domain/models/app_meta.dart';
import '../../domain/models/user_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'user_settings_json';
  static const _metaKey = 'app_meta_json';

  Future<UserSettings> loadSettings() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppDefaults.defaultSettings();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return UserSettings.fromJson(
      decoded,
      defaults: AppDefaults.defaultSettings(),
    );
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<AppMeta> loadMeta() async {
    final raw = _prefs.getString(_metaKey);
    if (raw == null || raw.isEmpty) {
      return AppDefaults.defaultMeta();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppMeta.fromJson(decoded);
  }

  Future<void> saveMeta(AppMeta meta) async {
    await _prefs.setString(_metaKey, jsonEncode(meta.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_metaKey);
  }
}
