import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/data/repositories/settings_repository.dart';
import 'package:smoke_timer/data/repositories/smoking_repository.dart';
import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/presentation/state/app_controller.dart';
import 'package:smoke_timer/services/alert_scheduler.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing alert settings triggers reschedule registration', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime(2026, 2, 17, 9, 0); // Tue
    final lastSmokingAt = DateTime(2026, 2, 17, 8, 0);

    final smokingRepo = SmokingRepository(prefs);
    final settingsRepo = SettingsRepository(prefs);

    await smokingRepo.saveRecords([
      SmokingRecord(id: 'seed', timestamp: lastSmokingAt, count: 1),
    ]);
    await settingsRepo.saveMeta(
      AppMeta(hasCompletedOnboarding: true, lastSmokingAt: lastSmokingAt),
    );
    await settingsRepo.saveSettings(AppDefaults.defaultSettings());

    final notifications = CapturingNotificationService();
    final controller = AppController(
      smokingRepository: smokingRepo,
      settingsRepository: settingsRepo,
      scheduler: const AlertScheduler(),
      notificationService: notifications,
      now: () => now,
      config: const AppConfig(splashDuration: Duration.zero, scheduleCount: 3),
    );

    await controller.bootstrap();
    expect(controller.state.isInitialized, isTrue);
    expect(controller.state.nextAlertAt, DateTime(2026, 2, 17, 9, 25));

    expect(notifications.scheduledBatches, isNotEmpty);
    expect(notifications.scheduledBatches.last.length, 3);

    final toggled = await controller.toggleRepeatEnabled();
    expect(toggled, isTrue);
    expect(controller.state.settings.repeatEnabled, isFalse);
    expect(controller.state.nextAlertAt, isNull);
    expect(notifications.scheduledBatches.last, isEmpty);

    controller.dispose();
  });
}
