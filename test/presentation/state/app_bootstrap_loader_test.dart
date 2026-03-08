import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/data/repositories/settings_repository.dart';
import 'package:smoke_timer/data/repositories/smoking_repository.dart';
import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/state/app_bootstrap_loader.dart';

void main() {
  test(
    'loader normalizes stale meta lastSmokingAt against persisted records',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final smokingRepo = SmokingRepository(prefs);
      final settingsRepo = SettingsRepository(prefs);

      await smokingRepo.saveRecords([
        SmokingRecord(
          id: 'seed',
          timestamp: DateTime(2026, 3, 8, 8, 0),
          count: 1,
        ),
      ]);
      await settingsRepo.saveMeta(
        const AppMeta(hasCompletedOnboarding: true, lastSmokingAt: null),
      );

      final loader = AppBootstrapLoader(
        smokingRepository: smokingRepo,
        settingsRepository: settingsRepo,
      );

      final snapshot = await loader.load();

      expect(snapshot.records.length, 1);
      expect(snapshot.meta.lastSmokingAt, DateTime(2026, 3, 8, 8, 0));
    },
  );
}
