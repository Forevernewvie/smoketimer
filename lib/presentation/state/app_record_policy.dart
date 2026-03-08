import '../../domain/models/app_meta.dart';
import '../../domain/models/smoking_record.dart';
import '../../services/smoking_stats_service.dart';

/// Immutable result returned after a smoking-record mutation.
class AppRecordMutationResult {
  /// Creates a normalized smoking-record mutation result.
  const AppRecordMutationResult({required this.records, required this.meta});

  /// Updated smoking records sorted by timestamp descending.
  final List<SmokingRecord> records;

  /// Updated metadata synchronized with the smoking record set.
  final AppMeta meta;
}

/// Pure policy object that owns smoking-record mutation rules.
class AppRecordPolicy {
  /// Prevents accidental instantiation of this pure utility class.
  const AppRecordPolicy._();

  /// Returns the next record/meta snapshot after adding a single record.
  static AppRecordMutationResult addRecord({
    required List<SmokingRecord> currentRecords,
    required AppMeta currentMeta,
    required DateTime now,
  }) {
    final newRecord = SmokingRecord(
      id: 'record_${now.microsecondsSinceEpoch}',
      timestamp: now,
      count: 1,
    );

    final updatedRecords = [...currentRecords, newRecord]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final updatedMeta = currentMeta.copyWith(lastSmokingAt: now);

    return AppRecordMutationResult(
      records: List<SmokingRecord>.unmodifiable(updatedRecords),
      meta: updatedMeta,
    );
  }

  /// Returns the next record/meta snapshot after removing the latest record.
  static AppRecordMutationResult? undoLastRecord({
    required List<SmokingRecord> currentRecords,
    required AppMeta currentMeta,
  }) {
    if (currentRecords.isEmpty) {
      return null;
    }

    final updatedRecords = currentRecords.sublist(1);
    final updatedLastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      null,
      updatedRecords,
    );
    final updatedMeta = currentMeta.copyWith(
      lastSmokingAt: updatedLastSmokingAt,
      clearLastSmokingAt: updatedLastSmokingAt == null,
    );

    return AppRecordMutationResult(
      records: List<SmokingRecord>.unmodifiable(updatedRecords),
      meta: updatedMeta,
    );
  }
}
