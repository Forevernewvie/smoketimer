import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/errors/app_exceptions.dart';
import '../../domain/models/smoking_record.dart';
import '../../services/logging/app_logger.dart';

class SmokingRepository {
  /// Creates repository that persists smoking records in shared preferences.
  SmokingRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _logger = AppLogger(namespace: 'smoking-repo');

  static const _recordsKey = 'smoking_records_json';

  /// Loads all stored smoking records sorted by timestamp (desc).
  ///
  /// Returns empty list when storage is empty or payload is invalid.
  Future<List<SmokingRecord>> loadRecords() async {
    try {
      final raw = _prefs.getString(_recordsKey);
      if (raw == null || raw.isEmpty) {
        return <SmokingRecord>[];
      }

      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = decoded
          .map((item) => SmokingRecord.fromJson(item as Map<String, dynamic>))
          .toList();

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (error, stackTrace) {
      _logger.warning('Invalid smoking records payload. Returning empty list.');
      _logger.error('loadRecords failed', error: error, stackTrace: stackTrace);
      return <SmokingRecord>[];
    }
  }

  /// Saves smoking records after normalizing order by timestamp (desc).
  Future<void> saveRecords(List<SmokingRecord> records) async {
    final normalized = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final encoded = jsonEncode(
      normalized.map((item) => item.toJson()).toList(growable: false),
    );

    final success = await _prefs.setString(_recordsKey, encoded);
    if (!success) {
      throw const RepositoryException(
        code: 'records_save_failed',
        message: 'Failed to save smoking records.',
      );
    }
  }

  /// Clears all smoking records from local storage.
  Future<void> clear() async {
    final success = await _prefs.remove(_recordsKey);
    if (!success) {
      throw const RepositoryException(
        code: 'records_clear_failed',
        message: 'Failed to clear smoking records.',
      );
    }
  }
}
