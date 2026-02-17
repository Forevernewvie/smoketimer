import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/smoking_record.dart';

class SmokingRepository {
  SmokingRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _recordsKey = 'smoking_records_json';

  Future<List<SmokingRecord>> loadRecords() async {
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
  }

  Future<void> saveRecords(List<SmokingRecord> records) async {
    final normalized = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final encoded = jsonEncode(
      normalized.map((item) => item.toJson()).toList(growable: false),
    );

    await _prefs.setString(_recordsKey, encoded);
  }

  Future<void> clear() async {
    await _prefs.remove(_recordsKey);
  }
}
