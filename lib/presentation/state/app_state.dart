import '../../domain/app_defaults.dart';
import '../../domain/models/app_meta.dart';
import '../../domain/models/record_period.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';

enum AppStage { splash, onboarding, main }

class AppState {
  const AppState({
    required this.stage,
    required this.isInitialized,
    required this.now,
    required this.records,
    required this.settings,
    required this.meta,
    required this.recordPeriod,
    required this.nextAlertAt,
  });

  final AppStage stage;
  final bool isInitialized;
  final DateTime now;
  final List<SmokingRecord> records;
  final UserSettings settings;
  final AppMeta meta;
  final RecordPeriod recordPeriod;
  final DateTime? nextAlertAt;

  factory AppState.initial(DateTime now) {
    return AppState(
      stage: AppStage.splash,
      isInitialized: false,
      now: now,
      records: const <SmokingRecord>[],
      settings: AppDefaults.defaultSettings(),
      meta: AppDefaults.defaultMeta(),
      recordPeriod: RecordPeriod.today,
      nextAlertAt: null,
    );
  }

  AppState copyWith({
    AppStage? stage,
    bool? isInitialized,
    DateTime? now,
    List<SmokingRecord>? records,
    UserSettings? settings,
    AppMeta? meta,
    RecordPeriod? recordPeriod,
    DateTime? nextAlertAt,
    bool clearNextAlertAt = false,
  }) {
    return AppState(
      stage: stage ?? this.stage,
      isInitialized: isInitialized ?? this.isInitialized,
      now: now ?? this.now,
      records: records ?? this.records,
      settings: settings ?? this.settings,
      meta: meta ?? this.meta,
      recordPeriod: recordPeriod ?? this.recordPeriod,
      nextAlertAt: clearNextAlertAt ? null : (nextAlertAt ?? this.nextAlertAt),
    );
  }
}
