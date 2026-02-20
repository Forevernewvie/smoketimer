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
    backgroundColor: SmokeUiPalette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final preview = TimeFormatter.formatRange(
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            use24Hour: use24Hour,
          );

          final isValid = endMinutes > startMinutes;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '허용 시간대',
                    style: TextStyle(
                      color: SmokeUiPalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    style: const TextStyle(
                      color: SmokeUiPalette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: SmokeUiPalette.accentDark,
                      inactiveTrackColor: const Color(0xFFD9E1EC),
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
                      labels: RangeLabels(
                        TimeFormatter.formatMinutesToClock(
                          startMinutes,
                          use24Hour: use24Hour,
                        ),
                        TimeFormatter.formatMinutesToClock(
                          endMinutes,
                          use24Hour: use24Hour,
                        ),
                      ),
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
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        TimeFormatter.formatMinutesToClock(
                          max,
                          use24Hour: use24Hour,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isValid)
                    const Text(
                      '종료 시간은 시작 시간보다 커야 합니다.',
                      style: TextStyle(
                        color: SmokeUiPalette.risk,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Opacity(
                    key: const Key('allowed_window_apply_opacity'),
                    opacity: isValid ? 1 : 0.4,
                    child: PrimaryButton(
                      key: const Key('allowed_window_apply'),
                      text: '적용',
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('allowed_window_cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: SmokeUiPalette.textSecondary,
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
