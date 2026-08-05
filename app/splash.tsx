// app/splash.tsx
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../src/context/AppStateContext';
import { ThemeColors } from '../src/constants/theme';

export default function SplashScreen() {
  const { state } = useAppState();
  const router = useRouter();
  const [progress] = useState(new Animated.Value(0));

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  useEffect(() => {
    // 1.2s minimum delay animation
    Animated.timing(progress, {
      toValue: 1,
      duration: 1200,
      useNativeDriver: false,
    }).start(() => {
      if (state.hasCompletedOnboarding) {
        router.replace('/(tabs)');
      } else {
        router.replace('/onboarding');
      }
    });
  }, [state.hasCompletedOnboarding]);

  const widthInterpolate = progress.interpolate({
    inputRange: [0, 1],
    outputRange: ['0%', '100%'],
  });

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.content}>
        {/* App Title */}
        <Text style={[styles.appTitle, { color: colors.textPrimary }]}>Smoke Timer</Text>
        <Text style={[styles.subtitle, { color: colors.textSecondary }]}>Warm Ritual Timer</Text>

        {/* Loading Bar */}
        <View style={[styles.progressTrack, { backgroundColor: colors.surfaceSecondary }]}>
          <Animated.View
            style={[
              styles.progressBar,
              { backgroundColor: colors.accent, width: widthInterpolate },
            ]}
          />
        </View>

        <Text style={[styles.statusText, { color: colors.textMuted }]}>
          안전하게 준비 중...
        </Text>
      </View>

      <Text style={[styles.footerText, { color: colors.textMuted }]}>
        Privacy First • 100% On-Device Storage
      </Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 40,
    paddingHorizontal: 24,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
  },
  appTitle: {
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: -0.5,
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 15,
    fontWeight: '500',
    marginBottom: 40,
  },
  progressTrack: {
    width: 180,
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
    marginBottom: 16,
  },
  progressBar: {
    height: '100%',
    borderRadius: 3,
  },
  statusText: {
    fontSize: 13,
    fontWeight: '500',
  },
  footerText: {
    fontSize: 12,
    fontWeight: '500',
  },
});
