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
    return _buildSettingsSection(
      title: '알림',
      child: SurfaceCard(
        child: _buildSettingRow(
          label: '알림 설정',
          ui: ui,
          tone: _Step1SettingRowTone.primary,
          value: alertSummary,
          showChevron: true,
          onTap: onOpenAlertSettings,
        ),
      ),
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
    return _buildSettingsSection(
      title: '비용',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(
              rowKey: const Key('cost_pack_price_row'),
              ui: ui,
              label: '갑당 가격',
              tone: _Step1SettingRowTone.secondary,
              value: packPriceText,
              showChevron: true,
              onTap: onEditPackPrice,
            ),
            _buildSettingRow(
              rowKey: const Key('cost_cigarettes_per_pack_row'),
              ui: ui,
              label: '한 갑 개비 수',
              tone: _Step1SettingRowTone.secondary,
              value: '${cigarettesPerPack.toString()}개비',
              withTopBorder: true,
              showChevron: true,
              onTap: onEditCigarettesPerPack,
            ),
            _buildSettingRow(
              rowKey: const Key('cost_currency_row'),
              ui: ui,
              label: '통화',
              tone: _Step1SettingRowTone.secondary,
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
                  style: _settingCaptionStyle(ui.textSecondary),
                ),
              ),
          ],
        ),
      ),
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
    return _buildSettingsSection(
      title: '표시',
      child: SurfaceCard(
        child: Column(
          children: [
            _buildSettingRow(
              ui: ui,
              label: '24시간 표기',
              tone: _Step1SettingRowTone.primary,
              height: 56,
              trailing: TogglePill(isOn: use24Hour),
              onTap: onToggle24Hour,
            ),
            _buildSettingRow(
              ui: ui,
              label: darkModeLabel,
              tone: _Step1SettingRowTone.secondary,
              withTopBorder: true,
              trailing: TogglePill(isOn: darkModeEnabled),
              onTap: onToggleDarkMode,
            ),
            _buildSettingRow(
              ui: ui,
              label: '홈 원형 기준',
              tone: _Step1SettingRowTone.secondary,
              value: ringReferenceLabel,
              withTopBorder: true,
              showChevron: true,
              onTap: onCycleRingReference,
            ),
          ],
        ),
      ),
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
    return _buildSettingsSection(
      title: '피드백',
      child: SurfaceCard(
        child: Column(
          children: [
            _buildSettingRow(
              ui: ui,
              label: '진동',
              tone: _Step1SettingRowTone.secondary,
              withTopBorder: true,
              trailing: TogglePill(isOn: vibrationEnabled),
              onTap: onToggleVibration,
            ),
            _buildSettingRow(
              ui: ui,
              label: '소리',
              tone: _Step1SettingRowTone.secondary,
              value: soundTypeLabel,
              withTopBorder: true,
              showChevron: true,
              onTap: onCycleSoundType,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDataSection extends StatelessWidget {
  const _SettingsDataSection({
    required this.onOpenPrivacyPolicy,
    required this.onResetData,
  });

  final Future<void> Function() onOpenPrivacyPolicy;
  final Future<void> Function() onResetData;

  /// Isolates destructive data-reset affordances from normal preferences.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return _buildSettingsSection(
      title: '데이터',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(
              ui: ui,
              label: '개인정보처리방침',
              tone: _Step1SettingRowTone.primary,
              value: '광고 및 로컬 저장 정보 안내',
              valueMaxLines: 2,
              withTopBorder: false,
              showChevron: true,
              onTap: onOpenPrivacyPolicy,
            ),
            _buildSettingRow(
              ui: ui,
              label: '데이터 초기화',
              tone: _Step1SettingRowTone.danger,
              withTopBorder: true,
              onTap: onResetData,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AdMob 사용 시 공개 정책 문서가 필요할 수 있습니다.',
                    style: _settingCaptionStyle(ui.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '기록과 설정을 모두 지우는 작업입니다.',
                    style: _settingCaptionStyle(ui.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
