part of 'step1_screen.dart';

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.presentation,
    required this.activeWeekdays,
    required this.onToggleRepeat,
    required this.onPickInterval,
    required this.onSetPreAlertMinutes,
    required this.onPickRange,
    required this.onToggleWeekday,
    required this.onRequestPermission,
    required this.onSendTest,
  });

  final AlertSettingsPresentation presentation;
  final Set<int> activeWeekdays;
  final Future<void> Function() onToggleRepeat;
  final Future<void> Function() onPickInterval;
  final Future<void> Function(int minutes) onSetPreAlertMinutes;
  final Future<void> Function() onPickRange;
  final Future<void> Function(int weekday) onToggleWeekday;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;

  /// Builds the alert-settings detail screen content.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 400 || textScale > 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 설정',
          style: TextStyle(
            color: ui.textPrimary,
            fontFamily: 'Sora',
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '흡연 루틴에 맞는 로컬 알림 스케줄을 설정합니다.',
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _AlertOverviewCard(presentation: presentation, compact: compact),
        const SizedBox(height: 16),
        _AlertBasicSection(
          presentation: presentation,
          onToggleRepeat: onToggleRepeat,
          onPickInterval: onPickInterval,
          onRequestPermission: onRequestPermission,
        ),
        const SizedBox(height: 16),
        _AlertScheduleSection(
          presentation: presentation,
          activeWeekdays: activeWeekdays,
          onPickRange: onPickRange,
          onSetPreAlertMinutes: onSetPreAlertMinutes,
          onToggleWeekday: onToggleWeekday,
        ),
        const SizedBox(height: 16),
        _AlertTestSection(
          compact: compact,
          onRequestPermission: onRequestPermission,
          onSendTest: onSendTest,
        ),
      ],
    );
  }
}
