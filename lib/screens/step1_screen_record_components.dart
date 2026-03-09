part of 'step1_screen.dart';

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  static const _tabRadius = 12.0;
  static const _tabMinHeight = 42.0;
  static const _selectedBorderWidth = 1.4;

  final String text;
  final bool selected;
  final VoidCallback onTap;

  /// Renders one record-period filter tab.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Material(
      color: selected ? SmokeUiPalette.accentSoft : ui.surface,
      borderRadius: BorderRadius.circular(_tabRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_tabRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: _tabMinHeight),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_tabRadius),
            border: Border.all(
              color: selected ? SmokeUiPalette.accentDark : ui.border,
              width: selected ? _selectedBorderWidth : 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? SmokeUiPalette.accentDark : ui.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    this.cardKey,
    required this.label,
    required this.value,
    this.detail,
    required this.valueFontSize,
    this.emphasized = false,
  });

  final Key? cardKey;
  final String label;
  final String value;
  final String? detail;
  final double valueFontSize;
  final bool emphasized;

  /// Renders a summary metric tile used across record and cost insights.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      key: cardKey,
      cornerRadius: 12,
      strokeColor: ui.border,
      color: emphasized ? ui.surfaceAlt : ui.surface,
      padding: const EdgeInsets.all(SmokeUiSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: SmokeUiSpacing.xxs),
            Text(
              detail!,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.now,
    required this.records,
    required this.use24Hour,
    required this.onOpenHomeTab,
  });

  static const _maxVisibleRecords = 20;
  static const _emptyIconSize = 26.0;
  static const _emptyTopSpacing = 10.0;
  static const _listHeaderTopPadding = 14.0;
  static const _listHeaderBottomPadding = 6.0;

  final DateTime now;
  final List<SmokingRecord> records;
  final bool use24Hour;
  final Future<void> Function() onOpenHomeTab;

  /// Renders recent records or an empty state with a route back to home.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(SmokeUiSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: SmokeUiSpacing.xs),
            Icon(
              Icons.receipt_long_outlined,
              size: _emptyIconSize,
              color: ui.textMuted,
            ),
            const SizedBox(height: _emptyTopSpacing),
            Text(
              '기록이 없습니다',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Home 탭에서 지금 흡연 기록을 누르면 여기에 쌓여요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            SecondaryButton(
              text: 'Home로 이동',
              icon: Icons.timer_outlined,
              foregroundColor: ui.textPrimary,
              backgroundColor: ui.surfaceAlt,
              borderColor: ui.border,
              onTap: () async {
                await onOpenHomeTab();
              },
            ),
          ],
        ),
      );
    }

    final visibleCount = min(records.length, _maxVisibleRecords);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _listHeaderTopPadding,
            _listHeaderTopPadding,
            _listHeaderTopPadding,
            _listHeaderBottomPadding,
          ),
          child: Text(
            '최근 기록',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...List.generate(visibleCount, (index) {
          final record = records[index];
          final time = TimeFormatter.formatDayAwareClock(
            now,
            record.timestamp,
            use24Hour: use24Hour,
          );

          return _RecordListRow(
            time: time,
            amount: '${record.count}개비',
            sameDay: DateUtils.isSameDay(now, record.timestamp),
            withTopBorder: index > 0,
          );
        }),
      ],
    );
  }
}

class _RecordListRow extends StatelessWidget {
  const _RecordListRow({
    required this.time,
    required this.amount,
    required this.sameDay,
    required this.withTopBorder,
  });

  static const _rowMinHeight = 48.0;
  static const _amountPillHorizontalPadding = 10.0;
  static const _amountPillVerticalPadding = 6.0;

  final String time;
  final String amount;
  final bool sameDay;
  final bool withTopBorder;

  /// Renders one smoking history row with day-aware labeling.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: SmokeUiSpacing.sm,
        vertical: SmokeUiSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: withTopBorder
            ? Border(top: BorderSide(color: ui.border, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sameDay ? '오늘 기록' : '이전 기록',
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SmokeUiSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _amountPillHorizontalPadding,
              vertical: _amountPillVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: ui.surfaceAlt,
              borderRadius: BorderRadius.circular(SmokeUiRadius.pill),
              border: Border.all(color: ui.border),
            ),
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
