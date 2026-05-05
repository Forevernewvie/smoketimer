part of 'step1_screen.dart';

const _defaultSettingRowHeight = 52.0;
const _prominentSettingRowHeight = 56.0;
const _settingRowPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
const _step1SheetCornerRadius = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
);

enum _Step1SettingRowTone { primary, secondary, danger }

Widget _buildSettingsSection({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(text: title),
      const SizedBox(height: SmokeUiSpacing.xs),
      child,
    ],
  );
}

_SettingRow _buildSettingRow({
  Key? rowKey,
  required SmokeUiTheme ui,
  required String label,
  required _Step1SettingRowTone tone,
  double height = _defaultSettingRowHeight,
  String? value,
  int valueMaxLines = 1,
  TextStyle? valueStyle,
  Widget? trailing,
  bool withTopBorder = false,
  bool showChevron = false,
  Future<void> Function()? onTap,
}) {
  return _SettingRow(
    rowKey: rowKey,
    height: height,
    padding: _settingRowPadding,
    label: label,
    labelStyle: _settingRowLabelStyle(ui, tone),
    value: value,
    valueMaxLines: valueMaxLines,
    valueStyle: valueStyle,
    trailing: trailing,
    withTopBorder: withTopBorder,
    showChevron: showChevron,
    onTap: onTap,
  );
}

TextStyle _settingRowLabelStyle(SmokeUiTheme ui, _Step1SettingRowTone tone) {
  return switch (tone) {
    _Step1SettingRowTone.primary => TextStyle(
      color: ui.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    _Step1SettingRowTone.secondary => TextStyle(
      color: ui.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    _Step1SettingRowTone.danger => const TextStyle(
      color: SmokeUiPalette.risk,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  };
}

TextStyle _settingValueStyle(SmokeUiTheme ui, {double fontSize = 14}) {
  return TextStyle(
    color: ui.textPrimary,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _settingCaptionStyle(Color color, {double height = 1.0}) {
  return TextStyle(
    color: color,
    fontSize: 12,
    height: height,
    fontWeight: FontWeight.w500,
  );
}

TextStyle _sheetTitleTextStyle(SmokeUiTheme ui) {
  return TextStyle(
    color: ui.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}

TextStyle _sheetSubtitleTextStyle(SmokeUiTheme ui) {
  return TextStyle(
    color: ui.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

class _Step1SubscreenScaffold extends StatelessWidget {
  const _Step1SubscreenScaffold({required this.child});

  final Widget child;

  /// Reuses the app shell spacing for secondary full-screen routes.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Scaffold(
      backgroundColor: ui.background,
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
                  child: const SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Step1BackButton(),
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
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1BackButton extends StatelessWidget {
  const _Step1BackButton();

  /// Returns to the previous route using the compact icon treatment.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return IconButton(
      tooltip: '뒤로',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: ui.textPrimary,
      ),
    );
  }
}
