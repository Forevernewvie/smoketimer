import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/models/home_widget_snapshot.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/services/home_screen_widget_service.dart';
import 'package:smoke_timer/services/home_widget_platform_adapter.dart';

class FakeHomeWidgetPlatformAdapter implements HomeWidgetPlatformAdapter {
  final List<String> appGroupIds = [];
  final Map<String, String> storedValues = {};
  int updateCalls = 0;

  @override
  Future<void> saveString(String key, String value) async {
    storedValues[key] = value;
  }

  @override
  Future<void> setAppGroupId(String appGroupId) async {
    appGroupIds.add(appGroupId);
  }

  @override
  Future<void> updateWidget({
    required String androidName,
    required String qualifiedAndroidName,
    required String iOSName,
  }) async {
    updateCalls += 1;
  }
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('initialize registers app group only once on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final adapter = FakeHomeWidgetPlatformAdapter();
    final service = HomeScreenWidgetService(
      platformAdapter: adapter,
      config: const AppConfig(),
    );

    await service.initialize();
    await service.initialize();

    expect(adapter.appGroupIds, [const AppConfig().homeWidget.iOSAppGroupId]);
  });

  test('syncSnapshot stores values and skips duplicate payloads', () async {
    final adapter = FakeHomeWidgetPlatformAdapter();
    final service = HomeScreenWidgetService(
      platformAdapter: adapter,
      config: const AppConfig(),
    );
    const snapshot = HomeWidgetSnapshot(
      hasRecord: true,
      primaryValue: '45분',
      statusTitle: '15분 남았어요',
      statusDetail: '간격 60분 기준',
      nextAlertLabel: '다음 알림',
      nextAlertValue: '오전 10:00 예정',
      todayCountLabel: '오늘 2개비',
      todaySpendLabel: '지출 ₩600',
      lastSmokingAtIso: '2026-03-08T08:15:00.000',
      nextAlertAtIso: '2026-03-08T10:00:00.000',
      updatedAtIso: '2026-03-08T09:00:00.000',
    );

    await service.syncSnapshot(snapshot);
    await service.syncSnapshot(snapshot);

    expect(adapter.storedValues['primary_value'], '45분');
    expect(adapter.storedValues['status_detail'], '간격 60분 기준');
    expect(adapter.updateCalls, 1);
  });
}
