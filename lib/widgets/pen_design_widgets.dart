import 'dart:math' as math;

import 'package:flutter/material.dart';

class SmokeUiPalette {
  const SmokeUiPalette._();

  static const background = Color(0xFFF4F6FA);
  static const backgroundElevated = Color(0xFFECEFF4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBorder = Color(0xFFD8DEE8);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF5A6472);
  static const accent = Color(0xFFFF8A3D);
  static const accentDark = Color(0xFFE7792F);
  static const accentSoft = Color(0xFFFFE9D8);
  static const mint = Color(0xFF14B88F);
  static const mintSoft = Color(0xFFDDF8F0);
  static const info = Color(0xFF0891B2);
  static const infoSoft = Color(0xFFDDF4FA);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFFEDD5);
  static const risk = Color(0xFFD95B57);
  static const riskSoft = Color(0xFFFEE2E2);
  static const neutralSoft = Color(0xFFEEF2F7);
}

class SmokeUiSpacing {
  const SmokeUiSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

class SmokeUiRadius {
  const SmokeUiRadius._();

  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class SmokeUiTheme {
  const SmokeUiTheme._({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.neutralSoft,
    required this.criticalSoft,
    required this.criticalBorder,
    required this.ringTrack,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color neutralSoft;
  final Color criticalSoft;
  final Color criticalBorder;
  final Color ringTrack;

  static const SmokeUiTheme light = SmokeUiTheme._(
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF8FAFC),
    border: Color(0xFFD8DEE8),
    textPrimary: Color(0xFF121417),
    textSecondary: Color(0xFF5A6472),
    textMuted: Color(0xFF6B7280),
    neutralSoft: Color(0xFFEEF2F7),
    criticalSoft: Color(0xFFFEE2E2),
    criticalBorder: Color(0xFFFCA5A5),
    ringTrack: Color(0xFFD8DEE8),
  );

  static const SmokeUiTheme dark = SmokeUiTheme._(
    background: Color(0xFF111315),
    surface: Color(0xFF1B1F24),
    surfaceAlt: Color(0xFF192028),
    border: Color(0xFF2D3540),
    textPrimary: Color(0xFFF2F4F8),
    textSecondary: Color(0xFFA2ACBA),
    textMuted: Color(0xFF8994A3),
    neutralSoft: Color(0xFF27313C),
    criticalSoft: Color(0xFF3B1F23),
    criticalBorder: Color(0xFF8A3A44),
    ringTrack: Color(0xFF2D3540),
  );

  static SmokeUiTheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding,
    this.color,
    this.strokeColor,
    this.strokeWidth = 1,
    this.cornerRadius = 16,
    this.boxShadow,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? strokeColor;
  final double strokeWidth;
  final double cornerRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final resolvedColor = color ?? ui.surface;
    final resolvedStroke = strokeColor ?? ui.border;
    final border = strokeWidth == 0
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(color: resolvedStroke, width: strokeWidth);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

class RingGauge extends StatelessWidget {
  const RingGauge({
    required this.size,
    required this.strokeWidth,
    required this.sweepAngle,
    required this.value,
    required this.label,
    this.trackColor = const Color(0xFFCDD6E2),
    this.arcColor = SmokeUiPalette.accent,
    this.valueStyle = const TextStyle(
      color: SmokeUiPalette.textPrimary,
      fontSize: 36,
      fontWeight: FontWeight.w700,
    ),
    this.labelStyle = const TextStyle(
      color: SmokeUiPalette.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    super.key,
  });

  final double size;
  final double strokeWidth;
  final double sweepAngle;
  final String value;
  final String label;
  final Color trackColor;
  final Color arcColor;
  final TextStyle valueStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingGaugePainter(
              trackColor: trackColor,
              arcColor: arcColor,
              strokeWidth: strokeWidth,
              sweepAngle: sweepAngle,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(strokeWidth),
            child: SizedBox(
              width: size - (strokeWidth * 2),
              height: size - (strokeWidth * 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, textAlign: TextAlign.center, style: valueStyle),
                    Text(label, textAlign: TextAlign.center, style: labelStyle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  const _RingGaugePainter({
    required this.trackColor,
    required this.arcColor,
    required this.strokeWidth,
    required this.sweepAngle,
  });

  final Color trackColor;
  final Color arcColor;
  final double strokeWidth;
  final double sweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw both track and arc with the same deflated rect so they share
    // the exact same radius/stroke centerline (no visible gap).
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = trackColor
      ..isAntiAlias = true;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = arcColor
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.sweepAngle != sweepAngle;
  }
}

class PageDots extends StatelessWidget {
  const PageDots({required this.activeIndex, super.key});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 16 : 8,
          height: 8,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
          decoration: BoxDecoration(
            color: active ? SmokeUiPalette.accent : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class TogglePill extends StatelessWidget {
  const TogglePill({required this.isOn, super.key});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Container(
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: isOn ? SmokeUiPalette.accent : ui.neutralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: isOn ? 22 : 2,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DayChip extends StatelessWidget {
  const DayChip({required this.text, required this.active, super.key});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1D4ED8) : ui.neutralSoft,
        borderRadius: BorderRadius.circular(8),
        border: active ? null : Border.all(color: ui.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : ui.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    this.height = 48,
    this.color = SmokeUiPalette.accent,
    this.radius = 12,
    this.icon,
    this.onTap,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    super.key,
  });

  final String text;
  final double height;
  final Color color;
  final double radius;
  final IconData? icon;
  final VoidCallback? onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = enabled ? color : color.withValues(alpha: 0.45);
    final foreground = enabled
        ? textStyle.color ?? Colors.white
        : (textStyle.color ?? Colors.white).withValues(alpha: 0.72);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: Colors.white.withValues(alpha: 0.16),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: SmokeUiSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: textStyle.copyWith(color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.text,
    this.height = 44,
    this.radius = SmokeUiRadius.md,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.onTap,
    super.key,
  });

  final String text;
  final double height;
  final double radius;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final enabled = onTap != null;
    final foreground = enabled
        ? (foregroundColor ?? ui.textPrimary)
        : (foregroundColor ?? ui.textPrimary).withValues(alpha: 0.45);
    final background = enabled
        ? (backgroundColor ?? ui.surfaceAlt)
        : (backgroundColor ?? ui.surfaceAlt).withValues(alpha: 0.6);
    final stroke = enabled
        ? (borderColor ?? ui.border)
        : (borderColor ?? ui.border).withValues(alpha: 0.45);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: SmokeUiSpacing.xs),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.text,
    this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    this.borderColor,
    super.key,
  });

  final String text;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SmokeUiRadius.pill),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: SmokeUiSpacing.xxs),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: ui.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
