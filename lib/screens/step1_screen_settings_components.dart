part of 'step1_screen.dart';

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    this.rowKey,
    required this.height,
    required this.padding,
    required this.label,
    required this.labelStyle,
    this.value,
    this.valueMaxLines = 1,
    this.valueStyle,
    this.trailing,
    this.withTopBorder = false,
    this.showChevron = false,
    this.onTap,
  });

  static const _chevronSpacing = 8.0;
  static const _chevronSize = 14.0;

  final Key? rowKey;
  final double height;
  final EdgeInsetsGeometry padding;
  final String label;
  final TextStyle labelStyle;
  final String? value;
  final int valueMaxLines;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool withTopBorder;
  final bool showChevron;
  final Future<void> Function()? onTap;

  /// Renders a reusable interactive settings row with value and affordances.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final trailingWidgets = trailing == null
        ? const <Widget>[]
        : <Widget>[trailing!];
    final content = Container(
      key: rowKey,
      constraints: BoxConstraints(minHeight: height),
      padding: padding,
      decoration: BoxDecoration(
        border: withTopBorder
            ? Border(top: BorderSide(color: ui.border, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          if (value != null)
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                value!,
                maxLines: valueMaxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style:
                    valueStyle ??
                    TextStyle(
                      color: ui.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          if (value != null && showChevron)
            const SizedBox(width: _chevronSpacing),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              size: _chevronSize,
              color: ui.textMuted,
            ),
          ...trailingWidgets,
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onTap!();
        },
        child: content,
      ),
    );
  }
}
