import 'package:flutter/material.dart';

import '../domain/app_defaults.dart';
import '../services/time_formatter.dart';
import 'pen_design_widgets.dart';

class AllowedTimeWindow {
  const AllowedTimeWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;
}

Future<AllowedTimeWindow?> showAllowedTimeWindowSheet(
  BuildContext context, {
  required int initialStartMinutes,
  required int initialEndMinutes,
  required bool use24Hour,
}) async {
  final min = AppDefaults.allowedWindowMinMinutes;
  final max = AppDefaults.allowedWindowMaxMinutes;
  final step = AppDefaults.allowedWindowStepMinutes;

  int startMinutes = initialStartMinutes.clamp(min, max).toInt();
  int endMinutes = initialEndMinutes.clamp(min, max).toInt();

  startMinutes = _snapMinutes(startMinutes, step: step, min: min, max: max);
  endMinutes = _snapMinutes(endMinutes, step: step, min: min, max: max);

  final result = await showModalBottomSheet<AllowedTimeWindow>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: SmokeUiTheme.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final ui = SmokeUiTheme.of(context);
      return StatefulBuilder(
        builder: (context, setModalState) {
          final startLabel = TimeFormatter.formatMinutesToClock(
            startMinutes,
            use24Hour: use24Hour,
          );
          final endLabel = TimeFormatter.formatMinutesToClock(
            endMinutes,
            use24Hour: use24Hour,
          );
          final preview = TimeFormatter.formatRange(
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            use24Hour: use24Hour,
          );

          final isValid = endMinutes > startMinutes;
          final durationMinutes = endMinutes - startMinutes;
          final durationLabel = isValid
              ? _formatDuration(durationMinutes)
              : '시간 확인 필요';

          final sheetHeight = MediaQuery.sizeOf(context).height * 0.66;
          return SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SmokeUiSpacing.xl,
                SmokeUiSpacing.xs,
                SmokeUiSpacing.xl,
                SmokeUiSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '허용 시간대',
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: SmokeUiSpacing.xs),
                          Text(
                            '알림은 이 시간대 안에서만 예약돼요.',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: SmokeUiSpacing.sm),
                          Text(
                            preview,
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: SmokeUiSpacing.xs),
                          Wrap(
                            spacing: SmokeUiSpacing.xs,
                            runSpacing: SmokeUiSpacing.xs,
                            children: [
                              _WindowSummaryMetric(
                                label: '시작',
                                value: startLabel,
                              ),
                              _WindowSummaryMetric(
                                label: '종료',
                                value: endLabel,
                              ),
                              _WindowSummaryMetric(
                                label: '길이',
                                value: durationLabel,
                              ),
                            ],
                          ),
                          const SizedBox(height: SmokeUiSpacing.sm),
                          Text(
                            '$step분 단위로 조절할 수 있어요.',
                            style: TextStyle(
                              color: ui.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: SmokeUiSpacing.xs),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: SmokeUiPalette.accentDark,
                              inactiveTrackColor: ui.border,
                              thumbColor: SmokeUiPalette.accent,
                              overlayColor: SmokeUiPalette.accent.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            child: RangeSlider(
                              min: min.toDouble(),
                              max: max.toDouble(),
                              divisions: ((max - min) / step).round(),
                              values: RangeValues(
                                startMinutes.toDouble(),
                                endMinutes.toDouble(),
                              ),
                              labels: RangeLabels(startLabel, endLabel),
                              onChanged: (values) {
                                final nextStart = _snapMinutes(
                                  values.start.round(),
                                  step: step,
                                  min: min,
                                  max: max,
                                );
                                final nextEnd = _snapMinutes(
                                  values.end.round(),
                                  step: step,
                                  min: min,
                                  max: max,
                                );

                                setModalState(() {
                                  startMinutes = nextStart;
                                  endMinutes = nextEnd;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TimeFormatter.formatMinutesToClock(
                                  min,
                                  use24Hour: use24Hour,
                                ),
                                style: TextStyle(
                                  color: ui.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                TimeFormatter.formatMinutesToClock(
                                  max,
                                  use24Hour: use24Hour,
                                ),
                                style: TextStyle(
                                  color: ui.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SmokeUiSpacing.xs),
                          if (!isValid)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: SmokeUiSpacing.sm,
                                vertical: SmokeUiSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: SmokeUiPalette.riskSoft,
                                borderRadius: BorderRadius.circular(
                                  SmokeUiRadius.sm,
                                ),
                                border: Border.all(color: ui.criticalBorder),
                              ),
                              child: const Text(
                                '종료 시간은 시작 시간보다 뒤여야 합니다.',
                                style: TextStyle(
                                  color: SmokeUiPalette.risk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Text(
                              '선택한 시간대 안에서만 다음 알림을 계산합니다.',
                              style: TextStyle(
                                color: ui.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SmokeUiSpacing.sm),
                  Opacity(
                    key: const Key('allowed_window_apply_opacity'),
                    opacity: isValid ? 1 : 0.4,
                    child: PrimaryButton(
                      key: const Key('allowed_window_apply'),
                      text: '적용',
                      icon: Icons.check_rounded,
                      onTap: isValid
                          ? () {
                              Navigator.of(context).pop(
                                AllowedTimeWindow(
                                  startMinutes: startMinutes,
                                  endMinutes: endMinutes,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: SmokeUiSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('allowed_window_cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: ui.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return result;
}

class _WindowSummaryMetric extends StatelessWidget {
  const _WindowSummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ui.surfaceAlt,
        borderRadius: BorderRadius.circular(SmokeUiRadius.sm),
        border: Border.all(color: ui.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(
                  color: ui.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainderMinutes = minutes % 60;

  if (hours <= 0) {
    return '$remainderMinutes분 허용';
  }
  if (remainderMinutes == 0) {
    return '$hours시간 허용';
  }
  return '$hours시간 $remainderMinutes분 허용';
}

int _snapMinutes(
  int minutes, {
  required int step,
  required int min,
  required int max,
}) {
  if (step <= 1) {
    return minutes.clamp(min, max).toInt();
  }
  final snapped = ((minutes / step).round() * step).clamp(min, max);
  return snapped.toInt();
}
