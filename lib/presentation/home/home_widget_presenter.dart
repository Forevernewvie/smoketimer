import '../../domain/models/home_widget_snapshot.dart';
import '../../domain/models/record_period.dart';
import '../../presentation/state/app_state.dart';
import '../../services/cost_stats_service.dart';
import '../../services/smoking_stats_service.dart';
import 'home_status_presenter.dart';

/// Builds the platform-neutral payload used by Android and iOS home widgets.
class HomeWidgetPresenter {
  /// Prevents accidental instantiation of this pure utility class.
  const HomeWidgetPresenter._();

  /// Builds a widget snapshot once the application bootstrap is complete.
  static HomeWidgetSnapshot? buildIfReady(AppState state) {
    if (!state.isInitialized) {
      return null;
    }
    return build(state);
  }

  /// Converts the current app state into a render-ready widget snapshot.
  static HomeWidgetSnapshot build(AppState state) {
    final lastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      state.meta.lastSmokingAt,
      state.records,
    );
    final hasRecord = lastSmokingAt != null;
    final elapsedMinutes = SmokingStatsService.elapsedMinutes(
      now: state.now,
      ringBaseTime: lastSmokingAt,
    );
    final intervalPresentation = HomeStatusPresenter.buildIntervalStatus(
      HomeIntervalStatusInput(
        hasRingBaseTime: hasRecord,
        elapsedMinutes: elapsedMinutes,
        intervalMinutes: state.settings.intervalMinutes,
      ),
    );
    final alertPresentation = HomeStatusPresenter.buildAlertStatus(
      HomeAlertStatusInput(
        hasRingBaseTime: hasRecord,
        repeatEnabled: state.settings.repeatEnabled,
        hasSelectedWeekdays: state.settings.activeWeekdays.isNotEmpty,
        preAlertMinutes: state.settings.preAlertMinutes,
        now: state.now,
        nextAlertAt: state.nextAlertAt,
        use24Hour: state.settings.use24Hour,
      ),
    );
    final todayRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.today,
      state.now,
    );
    final todayCount = SmokingStatsService.totalCount(todayRecords);
    final todaySpendLabel = CostStatsService.isConfigured(state.settings)
        ? '지출 ${CostStatsService.formatCurrency(CostStatsService.computeSpendForRecords(records: todayRecords, settings: state.settings), state.settings)}'
        : '가격 설정 필요';

    return HomeWidgetSnapshot(
      hasRecord: hasRecord,
      primaryValue: hasRecord ? '$elapsedMinutes분' : '첫 기록 전',
      statusTitle: intervalPresentation.title,
      statusDetail: intervalPresentation.detail,
      nextAlertLabel: alertPresentation.chipText,
      nextAlertValue: alertPresentation.title,
      todayCountLabel: '오늘 $todayCount개비',
      todaySpendLabel: todaySpendLabel,
      lastSmokingAtIso: lastSmokingAt?.toIso8601String() ?? '',
      nextAlertAtIso: state.nextAlertAt?.toIso8601String() ?? '',
      updatedAtIso: state.now.toIso8601String(),
    );
  }
}
