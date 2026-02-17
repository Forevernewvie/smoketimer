import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/state/app_providers.dart';
import 'presentation/state/app_state.dart';
import 'screens/step0_smoker_timer_screen.dart';
import 'screens/step0_splash_screen.dart';
import 'screens/step1_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SmokeTimerApp(),
    ),
  );
}

class SmokeTimerApp extends ConsumerWidget {
  const SmokeTimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smoke Timer UI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE9EDF3),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        fontFamily: 'Inter',
      ),
      home: const RootStageScreen(),
      routes: {
        Step0SmokerTimerScreen.routeName: (context) =>
            const Step0SmokerTimerScreen(),
        Step0SplashScreen.routeName: (context) => const Step0SplashScreen(),
        Step1Screen.routeName: (context) => const Step1Screen(),
      },
    );
  }
}

class RootStageScreen extends ConsumerWidget {
  const RootStageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return switch (state.stage) {
      AppStage.splash => const Step0SplashScreen(),
      AppStage.onboarding => const Step0SmokerTimerScreen(),
      AppStage.main => const Step1Screen(),
    };
  }
}
