part of 'step1_screen.dart';

class _SettingsAlertSection extends StatelessWidget {
  const _SettingsAlertSection({
    required this.alertSummary,
    required this.onOpenAlertSettings,
  });

  final String alertSummary;
  final Future<void> Function() onOpenAlertSettings;

  /// Groups the alert shortcut row and its current summary.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '알림'),
        const SizedBox(height: SmokeUiSpacing.xs),
        SurfaceCard(
          child: _SettingRow(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            label: '알림 설정',
            labelStyle: TextStyle(
              color: ui.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            value: alertSummary,
            showChevron: true,
            onTap: onOpenAlertSettings,
          ),
        ),
      ],
    );
  }
}

class _SettingsCostSection extends StatelessWidget {
  const _SettingsCostSection({
    required this.isCostConfigured,
    required this.packPriceText,
    required this.cigarettesPerPack,
    required this.currencyLabel,
    required this.onEditPackPrice,
    required this.onEditCigarettesPerPack,
    required this.onEditCurrency,
  });

  final bool isCostConfigured;
  final String packPriceText;
  final int cigarettesPerPack;
  final String currencyLabel;
  final Future<void> Function() onEditPackPrice;
  final Future<void> Function() onEditCigarettesPerPack;
  final Future<void> Function() onEditCurrency;

  /// Groups price, pack-size, and currency settings for spend calculations.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '비용'),
        const SizedBox(height: SmokeUiSpacing.xs),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingRow(
                rowKey: const Key('cost_pack_price_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '갑당 가격',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: packPriceText,
                showChevron: true,
                onTap: onEditPackPrice,
              ),
              _SettingRow(
                rowKey: const Key('cost_cigarettes_per_pack_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '한 갑 개비 수',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: '${cigarettesPerPack.toString()}개비',
                withTopBorder: true,
                showChevron: true,
                onTap: onEditCigarettesPerPack,
              ),
              _SettingRow(
                rowKey: const Key('cost_currency_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '통화',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: currencyLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onEditCurrency,
              ),
              if (!isCostConfigured)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: Text(
                    '가격 정보를 설정하면 지출을 계산할 수 있어요.',
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsDisplaySection extends StatelessWidget {
  const _SettingsDisplaySection({
    required this.darkModeEnabled,
    required this.use24Hour,
    required this.ringReferenceLabel,
    required this.darkModeLabel,
    required this.onToggleDarkMode,
    required this.onToggle24Hour,
    required this.onCycleRingReference,
  });

  final bool darkModeEnabled;
  final bool use24Hour;
  final String ringReferenceLabel;
  final String darkModeLabel;
  final Future<void> Function() onToggleDarkMode;
  final Future<void> Function() onToggle24Hour;
  final Future<void> Function() onCycleRingReference;

  /// Groups display preferences such as clock format, theme, and ring basis.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '표시'),
        const SizedBox(height: SmokeUiSpacing.xs),
        SurfaceCard(
          child: Column(
            children: [
              _SettingRow(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '24시간 표기',
                labelStyle: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                trailing: TogglePill(isOn: use24Hour),
                onTap: onToggle24Hour,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: darkModeLabel,
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                withTopBorder: true,
                trailing: TogglePill(isOn: darkModeEnabled),
                onTap: onToggleDarkMode,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '홈 원형 기준',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: ringReferenceLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onCycleRingReference,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsFeedbackSection extends StatelessWidget {
  const _SettingsFeedbackSection({
    required this.vibrationEnabled,
    required this.soundTypeLabel,
    required this.onToggleVibration,
    required this.onCycleSoundType,
  });

  final bool vibrationEnabled;
  final String soundTypeLabel;
  final Future<void> Function() onToggleVibration;
  final Future<void> Function() onCycleSoundType;

  /// Groups tactile and sound feedback preferences.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '피드백'),
        const SizedBox(height: SmokeUiSpacing.xs),
        SurfaceCard(
          child: Column(
            children: [
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '진동',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                withTopBorder: true,
                trailing: TogglePill(isOn: vibrationEnabled),
                onTap: onToggleVibration,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '소리',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: soundTypeLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onCycleSoundType,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsDataSection extends StatelessWidget {
  const _SettingsDataSection({required this.onResetData});

  final Future<void> Function() onResetData;

  /// Isolates destructive data-reset affordances from normal preferences.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '데이터'),
        const SizedBox(height: SmokeUiSpacing.xs),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '데이터 초기화',
                labelStyle: const TextStyle(
                  color: Color(0xFFD95B57),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onTap: onResetData,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  '기록과 설정을 모두 지우는 작업입니다.',
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
