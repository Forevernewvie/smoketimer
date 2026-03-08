part of 'step1_screen.dart';

extension _Step1ScreenAlertActions on _Step1ScreenState {
  /// Opens the dedicated alert settings route.
  Future<void> _openAlertSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) {
          final routeUi = SmokeUiTheme.of(routeContext);
          return Scaffold(
            backgroundColor: routeUi.background,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _Step1ScreenState._maxContentWidth,
                        ),
                        child: SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '뒤로',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () => Navigator.of(routeContext).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: routeUi.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _Step1ScreenState._maxContentWidth,
                          ),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final appState = ref.watch(appControllerProvider);
                              final controller = ref.read(
                                appControllerProvider.notifier,
                              );
                              final resolvedLastSmokingAt =
                                  SmokingStatsService.resolveLastSmokingAt(
                                    appState.meta.lastSmokingAt,
                                    appState.records,
                                  );
                              final presentation = AlertSettingsPresenter.build(
                                AlertSettingsInput(
                                  repeatEnabled:
                                      appState.settings.repeatEnabled,
                                  intervalMinutes:
                                      appState.settings.intervalMinutes,
                                  preAlertMinutes:
                                      appState.settings.preAlertMinutes,
                                  allowedStartMinutes:
                                      appState.settings.allowedStartMinutes,
                                  allowedEndMinutes:
                                      appState.settings.allowedEndMinutes,
                                  use24Hour: appState.settings.use24Hour,
                                  hasRingBaseTime:
                                      resolvedLastSmokingAt != null,
                                  activeWeekdayCount:
                                      appState.settings.activeWeekdays.length,
                                  now: appState.now,
                                  nextAlertAt: appState.nextAlertAt,
                                ),
                              );

                              return _AlertCard(
                                presentation: presentation,
                                activeWeekdays:
                                    appState.settings.activeWeekdays,
                                onToggleRepeat: () async {
                                  final ok = await controller
                                      .toggleRepeatEnabled();
                                  if (!ok) {
                                    _showFeedback(
                                      '알림 권한을 허용해야 반복 알림을 사용할 수 있어요.',
                                      backgroundColor: routeUi.criticalSoft,
                                      foregroundColor: routeUi.textPrimary,
                                    );
                                    return;
                                  }
                                  await HapticFeedback.selectionClick();
                                  _showFeedback(
                                    appState.settings.repeatEnabled
                                        ? '반복 알림을 껐어요.'
                                        : '반복 알림을 켰어요.',
                                  );
                                },
                                onPickInterval: () async {
                                  await _pickIntervalMinutes(
                                    context,
                                    initialMinutes:
                                        appState.settings.intervalMinutes,
                                    onSelected: (minutes) =>
                                        controller.setIntervalMinutes(minutes),
                                  );
                                },
                                onSetPreAlertMinutes: (minutes) =>
                                    controller.setPreAlertMinutes(minutes),
                                onPickRange: () =>
                                    _pickAllowedWindow(context, appState),
                                onToggleWeekday: (weekday) =>
                                    controller.toggleWeekday(weekday),
                                onRequestPermission: () async {
                                  final ok = await controller
                                      .requestNotificationPermission();
                                  if (ok) {
                                    await HapticFeedback.selectionClick();
                                  }
                                  _showFeedback(
                                    ok
                                        ? '알림 권한이 허용되었습니다.'
                                        : '알림 권한을 허용해주세요. (시스템 설정)',
                                    backgroundColor: ok
                                        ? null
                                        : routeUi.criticalSoft,
                                    foregroundColor: routeUi.textPrimary,
                                  );
                                },
                                onSendTest: () async {
                                  final ok = await controller
                                      .sendTestNotification();
                                  if (!ok) {
                                    _showFeedback(
                                      '알림 권한이 필요합니다. (시스템 설정)',
                                      backgroundColor: routeUi.criticalSoft,
                                      foregroundColor: routeUi.textPrimary,
                                    );
                                    return;
                                  }
                                  await HapticFeedback.lightImpact();
                                  _showFeedback('테스트 알림을 보냈어요.');
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Presents the interval picker sheet and applies the selected value.
  Future<void> _pickIntervalMinutes(
    BuildContext context, {
    required int initialMinutes,
    required Future<void> Function(int minutes) onSelected,
  }) async {
    final min = AppDefaults.minIntervalMinutes;
    final max = AppDefaults.maxIntervalMinutes;
    final step = AppDefaults.intervalStepMinutes;
    int minutes = initialMinutes.clamp(min, max).toInt();
    final picked = await showModalBottomSheet<int>(
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
            final label = AlertSettingsPresenter.formatIntervalLabel(minutes);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '간격',
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$label (${minutes.toString()}분)',
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SmokeUiPalette.accentDark,
                        inactiveTrackColor: ui.border,
                        thumbColor: SmokeUiPalette.accent,
                        overlayColor: SmokeUiPalette.accent.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Slider(
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: ((max - min) / step).round(),
                        value: minutes.toDouble(),
                        onChanged: (value) {
                          final normalized = ((value / step).round() * step)
                              .clamp(min, max);
                          setModalState(() => minutes = normalized.toInt());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AlertSettingsPresenter.formatIntervalLabel(min),
                          style: TextStyle(
                            color: ui.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AlertSettingsPresenter.formatIntervalLabel(max),
                          style: TextStyle(
                            color: ui.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: '적용',
                      onTap: () {
                        Navigator.of(context).pop(minutes);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
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

    if (picked == null || picked == initialMinutes) {
      return;
    }
    await onSelected(picked);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('알림 간격을 변경했어요.');
  }

  /// Opens the allowed time range sheet and persists the selected range.
  Future<void> _pickAllowedWindow(BuildContext context, AppState state) async {
    final picked = await showAllowedTimeWindowSheet(
      context,
      initialStartMinutes: state.settings.allowedStartMinutes,
      initialEndMinutes: state.settings.allowedEndMinutes,
      use24Hour: state.settings.use24Hour,
    );
    if (picked == null || !context.mounted) {
      return;
    }

    await ref
        .read(appControllerProvider.notifier)
        .updateAllowedTimeWindow(
          startMinutes: picked.startMinutes,
          endMinutes: picked.endMinutes,
        );
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('허용 시간대를 저장했어요.');
  }
}
