import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/state/app_providers.dart';
import 'presentation/state/app_state.dart';
import 'screens/step0_smoker_timer_screen.dart';
import 'screens/step0_splash_screen.dart';
import 'screens/step1_screen.dart';
import 'services/logging/app_logger.dart';
import 'widgets/pen_design_widgets.dart';

/// Bootstraps dependencies and starts the root app widget.
Future<void> main() async {
  const logger = AppLogger(namespace: 'bootstrap');

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
  } catch (error, stackTrace) {
    logger.error(
      'MobileAds initialization failed. The app will continue without ads.',
      error: error,
      stackTrace: stackTrace,
    );
  }
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

  /// Builds app-level theme and route graph.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeEnabled = ref.watch(
      appControllerProvider.select((state) => state.settings.darkModeEnabled),
    );
    final themeMode = darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smoke Timer UI',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: SmokeUiTheme.light.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SmokeUiPalette.accent,
          primary: SmokeUiPalette.accentDark,
          secondary: SmokeUiPalette.mint,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SmokeUiTheme.dark.background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8A3D),
          secondary: Color(0xFF1D4ED8),
          surface: Color(0xFF1B1F24),
        ),
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

  /// Selects the current app stage screen from centralized state.
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
