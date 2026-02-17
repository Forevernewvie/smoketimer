import 'package:flutter/material.dart';

import '../widgets/pen_design_widgets.dart';

class Step0SplashScreen extends StatelessWidget {
  const Step0SplashScreen({super.key});

  static const routeName = '/step0-splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      appBar: const FrameRouteAppBar(
        title: 'DujVY · Step 0 Splash',
        currentRoute: routeName,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_SplashA3Card()],
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
    return PhoneShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restart_alt_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '흡연 타이머',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '마지막 흡연 후 경과 시간 표시',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 120,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD9E1EC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                Container(
                  width: 58,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '시작 준비 중',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
