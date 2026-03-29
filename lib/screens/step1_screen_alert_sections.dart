part of 'step1_screen.dart';

class _AlertBasicSection extends StatelessWidget {
  const _AlertBasicSection({
    required this.presentation,
    required this.onToggleRepeat,
    required this.onPickInterval,
    required this.onRequestPermission,
  });

  final AlertSettingsPresentation presentation;
  final Future<void> Function() onToggleRepeat;
  final Future<void> Function() onPickInterval;
  final Future<void> Function() onRequestPermission;

  /// Groups the core repeat, permission, interval, and next-alert settings.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return _buildSettingsSection(
      title: '기본',
      child: SurfaceCard(
        child: Column(
          children: [
            _buildSettingRow(
              label: '반복 알림',
              ui: ui,
              tone: _Step1SettingRowTone.primary,
              height: _prominentSettingRowHeight,
              trailing: TogglePill(isOn: presentation.repeatEnabled),
              onTap: onToggleRepeat,
            ),
            _buildSettingRow(
              label: '알림 권한',
              ui: ui,
              tone: _Step1SettingRowTone.secondary,
              value: '요청',
              withTopBorder: true,
              showChevron: true,
              onTap: onRequestPermission,
            ),
            _buildSettingRow(
              label: '간격',
              ui: ui,
              tone: _Step1SettingRowTone.secondary,
              value: presentation.intervalLabel,
              withTopBorder: true,
              showChevron: true,
              onTap: onPickInterval,
            ),
            _buildSettingRow(
              label: presentation.nextAlertRowLabel,
              ui: ui,
              tone: _Step1SettingRowTone.secondary,
              value: presentation.nextAlertPreviewText,
              valueMaxLines: 2,
              valueStyle: TextStyle(
                color: ui.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              withTopBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertScheduleSection extends StatelessWidget {
  const _AlertScheduleSection({
    required this.presentation,
    required this.activeWeekdays,
    required this.onPickRange,
    required this.onSetPreAlertMinutes,
    required this.onToggleWeekday,
  });

  final AlertSettingsPresentation presentation;
  final Set<int> activeWeekdays;
  final Future<void> Function() onPickRange;
  final Future<void> Function(int minutes) onSetPreAlertMinutes;
  final Future<void> Function(int weekday) onToggleWeekday;

  /// Groups allowed time range, pre-alert timing, and weekday selection.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final weekdayTonePalette = _AlertTonePalette.fromTone(
      presentation.weekdayTone,
    );

    return _buildSettingsSection(
      title: '시간과 요일',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(
              ui: ui,
              label: '허용 시간대',
              tone: _Step1SettingRowTone.secondary,
              value: presentation.rangeText,
              showChevron: true,
              onTap: onPickRange,
            ),
            _AlertPreAlertSliderSection(
              presentation: presentation,
              onSetPreAlertMinutes: onSetPreAlertMinutes,
            ),
            _AlertWeekdaySection(
              presentation: presentation,
              activeWeekdays: activeWeekdays,
              tonePalette: weekdayTonePalette,
              onToggleWeekday: onToggleWeekday,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertPreAlertSliderSection extends StatelessWidget {
  const _AlertPreAlertSliderSection({
    required this.presentation,
    required this.onSetPreAlertMinutes,
  });

  static const _sliderTrackHeight = 3.0;
  static const _sliderOverlayAlpha = 0.14;

  final AlertSettingsPresentation presentation;
  final Future<void> Function(int minutes) onSetPreAlertMinutes;

  /// Renders the pre-alert slider and keeps the selected value visible.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ui.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '미리 알림',
                  style: _settingRowLabelStyle(
                    ui,
                    _Step1SettingRowTone.secondary,
                  ),
                ),
              ),
              Text(
                presentation.preAlertValueText,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: _sliderTrackHeight,
              activeTrackColor: SmokeUiPalette.accent,
              inactiveTrackColor: ui.border,
              thumbColor: SmokeUiPalette.accent,
              overlayColor: SmokeUiPalette.accent.withValues(
                alpha: _sliderOverlayAlpha,
              ),
            ),
            child: Slider(
              key: const Key('pre_alert_slider'),
              min: AppDefaults.minPreAlertMinutes.toDouble(),
              max: AppDefaults.maxPreAlertMinutes.toDouble(),
              divisions:
                  AppDefaults.maxPreAlertMinutes -
                  AppDefaults.minPreAlertMinutes,
              value: presentation.preAlertMinutes.toDouble().clamp(
                AppDefaults.minPreAlertMinutes.toDouble(),
                AppDefaults.maxPreAlertMinutes.toDouble(),
              ),
              label: '${presentation.preAlertMinutes}분',
              onChanged: (value) {
                onSetPreAlertMinutes(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertWeekdaySection extends StatelessWidget {
  const _AlertWeekdaySection({
    required this.presentation,
    required this.activeWeekdays,
    required this.tonePalette,
    required this.onToggleWeekday,
  });

  static const _weekdayChipWidth = 38.0;

  final AlertSettingsPresentation presentation;
  final Set<int> activeWeekdays;
  final _AlertTonePalette tonePalette;
  final Future<void> Function(int weekday) onToggleWeekday;

  /// Renders weekday chips and explains why an empty selection blocks alerts.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeaderRow(
            leading: Text(
              '요일',
              style: _settingRowLabelStyle(ui, _Step1SettingRowTone.secondary),
            ),
            trailing: StatusChip(
              text: presentation.weekdayCountText,
              icon: Icons.calendar_month_outlined,
              foregroundColor: tonePalette.foregroundColor,
              backgroundColor: tonePalette.backgroundColor,
              borderColor: tonePalette.borderColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: Step1Screen._weekdayLabels.entries
                .map(
                  (entry) => GestureDetector(
                    onTap: () async {
                      await onToggleWeekday(entry.key);
                    },
                    child: SizedBox(
                      width: _weekdayChipWidth,
                      child: DayChip(
                        text: entry.value,
                        active: activeWeekdays.contains(entry.key),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          if (presentation.showWeekdayHint) ...[
            const SizedBox(height: SmokeUiSpacing.xs),
            Text(
              '반복할 요일을 하나 이상 선택해야 다음 알림을 만들 수 있어요.',
              style: _settingCaptionStyle(ui.textMuted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertTestSection extends StatelessWidget {
  const _AlertTestSection({
    required this.compact,
    required this.onRequestPermission,
    required this.onSendTest,
  });

  static const _actionFontSize = 14.0;

  final bool compact;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;

  /// Renders alert permission and test actions in a responsive layout.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return _buildSettingsSection(
      title: '테스트',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            SecondaryButton(
              text: '알림 권한',
              icon: Icons.shield_outlined,
              foregroundColor: ui.textPrimary,
              backgroundColor: ui.surfaceAlt,
              borderColor: ui.border,
              onTap: () async {
                await onRequestPermission();
              },
            ),
            const SizedBox(height: SmokeUiSpacing.xs),
            PrimaryButton(
              text: '테스트 알림 보내기',
              icon: Icons.notifications_active_rounded,
              color: SmokeUiPalette.accent,
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: _actionFontSize,
                fontWeight: FontWeight.w700,
              ),
              onTap: () async {
                await onSendTest();
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: '알림 권한',
                    icon: Icons.shield_outlined,
                    foregroundColor: ui.textPrimary,
                    backgroundColor: ui.surfaceAlt,
                    borderColor: ui.border,
                    onTap: () async {
                      await onRequestPermission();
                    },
                  ),
                ),
                const SizedBox(width: SmokeUiSpacing.xs),
                Expanded(
                  child: PrimaryButton(
                    text: '테스트 알림 보내기',
                    icon: Icons.notifications_active_rounded,
                    color: SmokeUiPalette.accent,
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: _actionFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                    onTap: () async {
                      await onSendTest();
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: SmokeUiSpacing.sm),
          Text(
            '알림이 예상과 다르면 권한, 요일, 허용 시간대 순서로 확인해 주세요.',
            style: _settingCaptionStyle(ui.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
