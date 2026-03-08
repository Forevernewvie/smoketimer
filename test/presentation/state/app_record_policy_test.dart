import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/state/app_record_policy.dart';

void main() {
  test('addRecord inserts a latest record and updates lastSmokingAt', () {
    final now = DateTime(2026, 3, 8, 12, 0);

    final result = AppRecordPolicy.addRecord(
      currentRecords: [
        SmokingRecord(
          id: 'older',
          timestamp: DateTime(2026, 3, 8, 11, 0),
          count: 1,
        ),
      ],
      currentMeta: AppMeta(
        hasCompletedOnboarding: true,
        lastSmokingAt: DateTime(2026, 3, 8, 11, 0),
      ),
      now: now,
    );

    expect(result.records.first.timestamp, now);
    expect(result.meta.lastSmokingAt, now);
  });

  test('undoLastRecord removes latest record and clears meta when empty', () {
    final result = AppRecordPolicy.undoLastRecord(
      currentRecords: [
        SmokingRecord(
          id: 'latest',
          timestamp: DateTime(2026, 3, 8, 12, 0),
          count: 1,
        ),
      ],
      currentMeta: AppMeta(
        hasCompletedOnboarding: true,
        lastSmokingAt: DateTime(2026, 3, 8, 12, 0),
      ),
    );

    expect(result, isNotNull);
    expect(result!.records, isEmpty);
    expect(result.meta.lastSmokingAt, isNull);
  });
}
