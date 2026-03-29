part of 'step1_screen.dart';

extension _Step1ScreenAlertActions on _Step1ScreenState {
  /// Opens the dedicated alert settings route.
  Future<void> _openAlertSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _Step1SubscreenScaffold(
          child: Consumer(
            builder: (context, ref, _) {
              final ui = SmokeUiTheme.of(context);
              final appState = ref.watch(appControllerProvider);
              final controller = ref.read(appControllerProvider.notifier);
              final presentation = _buildAlertPresentation(appState);

              return _AlertCard(
                presentation: presentation,
                activeWeekdays: appState.settings.activeWeekdays,
                onToggleRepeat: () => _handleToggleRepeat(
                  controller: controller,
                  appState: appState,
                  ui: ui,
                ),
                onPickInterval: () => _pickIntervalMinutes(
                  context,
                  initialMinutes: appState.settings.intervalMinutes,
                  onSelected: controller.setIntervalMinutes,
                ),
                onSetPreAlertMinutes: controller.setPreAlertMinutes,
                onPickRange: () => _pickAllowedWindow(context, appState),
                onToggleWeekday: controller.toggleWeekday,
                onRequestPermission: () =>
                    _handleRequestPermission(controller: controller, ui: ui),
                onSendTest: () =>
                    _handleSendTestNotification(controller: controller, ui: ui),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Maps app state into the alert-settings presentation model.
  AlertSettingsPresentation _buildAlertPresentation(AppState appState) {
    final resolvedLastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      appState.meta.lastSmokingAt,
      appState.records,
    );

    return AlertSettingsPresenter.build(
      AlertSettingsInput(
        repeatEnabled: appState.settings.repeatEnabled,
        intervalMinutes: appState.settings.intervalMinutes,
        preAlertMinutes: appState.settings.preAlertMinutes,
        allowedStartMinutes: appState.settings.allowedStartMinutes,
        allowedEndMinutes: appState.settings.allowedEndMinutes,
        use24Hour: appState.settings.use24Hour,
        hasRingBaseTime: resolvedLastSmokingAt != null,
        activeWeekdayCount: appState.settings.activeWeekdays.length,
        now: appState.now,
        nextAlertAt: appState.nextAlertAt,
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
      shape: _step1SheetCornerRadius,
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
                    Text('간격', style: _sheetTitleTextStyle(ui)),
                    const SizedBox(height: 6),
                    Text(
                      '$label (${minutes.toString()}분)',
                      style: _sheetSubtitleTextStyle(ui),
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
                          style: _settingCaptionStyle(ui.textMuted),
                        ),
                        Text(
                          AlertSettingsPresenter.formatIntervalLabel(max),
                          style: _settingCaptionStyle(ui.textMuted),
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

  Future<void> _handleToggleRepeat({
    required AppController controller,
    required AppState appState,
    required SmokeUiTheme ui,
  }) async {
    final ok = await controller.toggleRepeatEnabled();
    if (!ok) {
      _showFeedback(
        '알림 권한을 허용해야 반복 알림을 사용할 수 있어요.',
        backgroundColor: ui.criticalSoft,
        foregroundColor: ui.textPrimary,
      );
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback(
      appState.settings.repeatEnabled ? '반복 알림을 껐어요.' : '반복 알림을 켰어요.',
    );
  }

  Future<void> _handleRequestPermission({
    required AppController controller,
    required SmokeUiTheme ui,
  }) async {
    final ok = await controller.requestNotificationPermission();
    if (ok) {
      await HapticFeedback.selectionClick();
    }
    _showFeedback(
      ok ? '알림 권한이 허용되었습니다.' : '알림 권한을 허용해주세요. (시스템 설정)',
      backgroundColor: ok ? null : ui.criticalSoft,
      foregroundColor: ui.textPrimary,
    );
  }

  Future<void> _handleSendTestNotification({
    required AppController controller,
    required SmokeUiTheme ui,
  }) async {
    final ok = await controller.sendTestNotification();
    if (!ok) {
      _showFeedback(
        '알림 권한이 필요합니다. (시스템 설정)',
        backgroundColor: ui.criticalSoft,
        foregroundColor: ui.textPrimary,
      );
      return;
    }
    await HapticFeedback.lightImpact();
    _showFeedback('테스트 알림을 보냈어요.');
  }
}
