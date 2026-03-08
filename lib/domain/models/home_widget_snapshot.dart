class HomeWidgetSnapshot {
  /// Creates an immutable payload used to render native home screen widgets.
  const HomeWidgetSnapshot({
    required this.hasRecord,
    required this.primaryValue,
    required this.statusTitle,
    required this.statusDetail,
    required this.nextAlertLabel,
    required this.nextAlertValue,
    required this.todayCountLabel,
    required this.todaySpendLabel,
    required this.lastSmokingAtIso,
    required this.nextAlertAtIso,
    required this.updatedAtIso,
  });

  /// Whether at least one smoking record exists.
  final bool hasRecord;

  /// Primary value shown as the largest metric in the widget.
  final String primaryValue;

  /// Primary status headline derived from interval policy.
  final String statusTitle;

  /// Supporting explanation for the current status.
  final String statusDetail;

  /// Short label for the next-alert row.
  final String nextAlertLabel;

  /// Human-readable value for the next-alert row.
  final String nextAlertValue;

  /// Today count summary shown in the widget footer.
  final String todayCountLabel;

  /// Today spend summary shown in the widget footer.
  final String todaySpendLabel;

  /// Last smoking timestamp in ISO-8601 format for native refresh logic.
  final String lastSmokingAtIso;

  /// Next alert timestamp in ISO-8601 format for native refresh logic.
  final String nextAlertAtIso;

  /// Widget payload generation timestamp in ISO-8601 format.
  final String updatedAtIso;

  /// Converts the payload into a flat string map for native widget storage.
  Map<String, String> toStorageMap() {
    return {
      'has_record': hasRecord ? 'true' : 'false',
      'primary_value': primaryValue,
      'status_title': statusTitle,
      'status_detail': statusDetail,
      'next_alert_label': nextAlertLabel,
      'next_alert_value': nextAlertValue,
      'today_count_label': todayCountLabel,
      'today_spend_label': todaySpendLabel,
      'last_smoking_at_iso': lastSmokingAtIso,
      'next_alert_at_iso': nextAlertAtIso,
      'updated_at_iso': updatedAtIso,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is HomeWidgetSnapshot &&
        other.hasRecord == hasRecord &&
        other.primaryValue == primaryValue &&
        other.statusTitle == statusTitle &&
        other.statusDetail == statusDetail &&
        other.nextAlertLabel == nextAlertLabel &&
        other.nextAlertValue == nextAlertValue &&
        other.todayCountLabel == todayCountLabel &&
        other.todaySpendLabel == todaySpendLabel &&
        other.lastSmokingAtIso == lastSmokingAtIso &&
        other.nextAlertAtIso == nextAlertAtIso &&
        other.updatedAtIso == updatedAtIso;
  }

  @override
  int get hashCode => Object.hash(
    hasRecord,
    primaryValue,
    statusTitle,
    statusDetail,
    nextAlertLabel,
    nextAlertValue,
    todayCountLabel,
    todaySpendLabel,
    lastSmokingAtIso,
    nextAlertAtIso,
    updatedAtIso,
  );
}
