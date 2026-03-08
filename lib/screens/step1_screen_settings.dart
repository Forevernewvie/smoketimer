part of 'step1_screen.dart';

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.darkModeEnabled,
    required this.use24Hour,
    required this.ringReferenceLabel,
    required this.vibrationEnabled,
    required this.soundTypeLabel,
    required this.alertSummary,
    required this.isCostConfigured,
    required this.packPriceText,
    required this.cigarettesPerPack,
    required this.currencyLabel,
    required this.onToggleDarkMode,
    required this.onToggle24Hour,
    required this.onCycleRingReference,
    required this.onToggleVibration,
    required this.onCycleSoundType,
    required this.onOpenAlertSettings,
    required this.onEditPackPrice,
    required this.onEditCigarettesPerPack,
    required this.onEditCurrency,
    required this.onResetData,
  });

  final bool darkModeEnabled;
  final bool use24Hour;
  final String ringReferenceLabel;
  final bool vibrationEnabled;
  final String soundTypeLabel;
  final String alertSummary;
  final bool isCostConfigured;
  final String packPriceText;
  final int cigarettesPerPack;
  final String currencyLabel;
  final Future<void> Function() onToggleDarkMode;
  final Future<void> Function() onToggle24Hour;
  final Future<void> Function() onCycleRingReference;
  final Future<void> Function() onToggleVibration;
  final Future<void> Function() onCycleSoundType;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onEditPackPrice;
  final Future<void> Function() onEditCigarettesPerPack;
  final Future<void> Function() onEditCurrency;
  final Future<void> Function() onResetData;

  /// Builds the grouped settings screen for alert, cost, display, and data.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: ui.textPrimary,
            fontFamily: 'Sora',
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '알림, 비용, 표시 방식을 섹션별로 관리합니다.',
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsAlertSection(
          alertSummary: alertSummary,
          onOpenAlertSettings: onOpenAlertSettings,
        ),
        const SizedBox(height: 16),
        _SettingsCostSection(
          isCostConfigured: isCostConfigured,
          packPriceText: packPriceText,
          cigarettesPerPack: cigarettesPerPack,
          currencyLabel: currencyLabel,
          onEditPackPrice: onEditPackPrice,
          onEditCigarettesPerPack: onEditCigarettesPerPack,
          onEditCurrency: onEditCurrency,
        ),
        const SizedBox(height: 16),
        _SettingsDisplaySection(
          darkModeEnabled: darkModeEnabled,
          use24Hour: use24Hour,
          ringReferenceLabel: ringReferenceLabel,
          darkModeLabel: l10n.darkModeLabel,
          onToggleDarkMode: onToggleDarkMode,
          onToggle24Hour: onToggle24Hour,
          onCycleRingReference: onCycleRingReference,
        ),
        const SizedBox(height: 16),
        _SettingsFeedbackSection(
          vibrationEnabled: vibrationEnabled,
          soundTypeLabel: soundTypeLabel,
          onToggleVibration: onToggleVibration,
          onCycleSoundType: onCycleSoundType,
        ),
        const SizedBox(height: 16),
        _SettingsDataSection(onResetData: onResetData),
      ],
    );
  }
}
