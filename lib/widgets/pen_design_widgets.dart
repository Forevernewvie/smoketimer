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
  static const risk = Color(0xFFD95B57);
  static const neutralSoft = Color(0xFFEEF2F7);
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding,
    this.color = SmokeUiPalette.surface,
    this.strokeColor = SmokeUiPalette.surfaceBorder,
    this.strokeWidth = 1,
    this.cornerRadius = 16,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final border = strokeWidth == 0
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(color: strokeColor, width: strokeWidth);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: border,
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
    return Container(
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: isOn ? SmokeUiPalette.accent : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
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
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? SmokeUiPalette.accentDark : SmokeUiPalette.neutralSoft,
        borderRadius: BorderRadius.circular(8),
        border: active ? null : Border.all(color: SmokeUiPalette.surfaceBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : SmokeUiPalette.textSecondary,
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
  final VoidCallback? onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
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
            child: Text(
              text,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
