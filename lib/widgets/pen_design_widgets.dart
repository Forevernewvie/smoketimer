import 'dart:math' as math;

import 'package:flutter/material.dart';

class FrameRouteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrameRouteAppBar({
    required this.title,
    required this.currentRoute,
    super.key,
  });

  final String title;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: const Color(0xFFE9EDF3),
      foregroundColor: const Color(0xFF111827),
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        PopupMenuButton<String>(
          tooltip: '화면 이동',
          onSelected: (route) {
            if (route != currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: '/step0-smoker-timer',
              child: Text('KM1Jk • Step 0 Smoker Timer'),
            ),
            PopupMenuItem(
              value: '/step0-splash',
              child: Text('DujVY • Step 0 Splash'),
            ),
            PopupMenuItem(value: '/step1', child: Text('cOnQP • Step 1')),
          ],
          icon: const Icon(Icons.dashboard_customize_outlined),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PhoneShell extends StatelessWidget {
  const PhoneShell({
    required this.child,
    this.gap = 16,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final double gap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 700,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: child,
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding,
    this.color = const Color(0xFFFFFFFF),
    this.strokeColor = const Color(0xFFDFE6EF),
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
    this.trackColor = const Color(0xFFD4DDE8),
    this.arcColor = const Color(0xFF2563EB),
    this.valueStyle = const TextStyle(
      color: Color(0xFF111827),
      fontSize: 34,
      fontWeight: FontWeight.w700,
    ),
    this.labelStyle = const TextStyle(
      color: Color(0xFF64748B),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, textAlign: TextAlign.center, style: valueStyle),
              Text(label, textAlign: TextAlign.center, style: labelStyle),
            ],
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
            color: active ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
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
        color: isOn ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
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
        color: active ? const Color(0xFF1D4ED8) : const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(8),
        border: active ? null : Border.all(color: const Color(0xFFD7DFEA)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF374151),
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
    this.color = const Color(0xFF2563EB),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(text, style: textStyle, textAlign: TextAlign.center),
      ),
    );
  }
}
