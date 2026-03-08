import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/presentation/state/app_notification_coordinator.dart';
import 'package:smoke_timer/presentation/state/app_ports.dart';

import '../../test_utils.dart';

/// Fake scheduler that records reschedule inputs for coordinator tests.
class FakeAlertSchedulingPolicy implements AlertSchedulingPolicy {
  /// Creates a fake scheduler with deterministic timestamps.
  FakeAlertSchedulingPolicy(this.result);

  /// Next timestamps returned by the fake scheduling policy.
  final List<DateTime> result;

  /// Last count requested by the coordinator.
  int? requestedCount;

  @override
  List<DateTime> buildUpcomingAlerts({
    required DateTime now,
    required DateTime? lastSmokingAt,
    required UserSettings settings,
    required int count,
  }) {
    requestedCount = count;
    return result;
  }
}

void main() {
  test(
    'coordinator maps scheduler timestamps into notification payloads',
    () async {
      final notifications = CapturingNotificationService();
      final scheduler = FakeAlertSchedulingPolicy([
        DateTime(2026, 3, 8, 10, 0),
        DateTime(2026, 3, 8, 11, 0),
      ]);
      final coordinator = AppNotificationCoordinator(
        scheduler: scheduler,
        notificationService: notifications,
        config: const AppConfig(scheduleCount: 3),
      );

      final result = await coordinator.reschedule(
        now: DateTime(2026, 3, 8, 9, 0),
        lastSmokingAt: DateTime(2026, 3, 8, 8, 0),
        records: [
          SmokingRecord(
            id: 'seed',
            timestamp: DateTime(2026, 3, 8, 8, 0),
            count: 1,
          ),
        ],
        settings: AppDefaults.defaultSettings(),
      );

      expect(scheduler.requestedCount, 3);
      expect(result.nextAlertAt, DateTime(2026, 3, 8, 10, 0));
      expect(result.alerts.length, 2);
      expect(result.alerts.first.id, AppDefaults.scheduledAlertIdBase);
      expect(
        notifications.scheduledBatches.single.map((alert) => alert.at).toList(),
        [DateTime(2026, 3, 8, 10, 0), DateTime(2026, 3, 8, 11, 0)],
      );
    },
  );

  test(
    'coordinator clears notifications when scheduler returns no alerts',
    () async {
      final notifications = CapturingNotificationService();
      final coordinator = AppNotificationCoordinator(
        scheduler: FakeAlertSchedulingPolicy(const []),
        notificationService: notifications,
        config: const AppConfig(scheduleCount: 2),
      );

      final result = await coordinator.reschedule(
        now: DateTime(2026, 3, 8, 9, 0),
        lastSmokingAt: null,
        records: <SmokingRecord>[],
        settings: AppDefaults.defaultSettings(),
      );

      expect(result.nextAlertAt, isNull);
      expect(result.alerts, isEmpty);
      expect(notifications.scheduledBatches.single, isEmpty);
    },
  );
}
