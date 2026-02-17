import 'package:flutter/material.dart';

class Step0SplashScreen extends StatelessWidget {
  const Step0SplashScreen({super.key});

  static const routeName = '/step0-splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: const _SplashA3Card(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashA3Card extends StatelessWidget {
  const _SplashA3Card();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restart_alt_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 14),
        Text(
          '흡연 타이머',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14),
        Text(
          '마지막 흡연 후 경과 시간 표시',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: 120,
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFD9E1EC),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 58,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 14),
        Text(
          '시작 준비 중',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
