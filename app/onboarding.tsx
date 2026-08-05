// app/onboarding.tsx
import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  FlatList,
  Dimensions,
  NativeSyntheticEvent,
  NativeScrollEvent,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../src/context/AppStateContext';
import { ThemeColors } from '../src/constants/theme';

const { width } = Dimensions.get('window');

const onboardingPages = [
  {
    id: '1',
    icon: '⏱️',
    title: '시간 확인',
    headline: '지금 얼마나 지났는지 바로 확인',
    description:
      '강박적인 단번에 끊기 대신, 마지막 흡연으로부터 경과된 시간을 직관적인 타이머 아크로 한눈에 확인하세요.',
  },
  {
    id: '2',
    icon: '📊',
    title: '기록과 통계',
    headline: '기록은 빠르게, 흐름은 자동으로',
    description:
      '원터치로 흡연을 기록하고 실수 시 되돌리기(Undo)로 죄책감 없이 빠르게 상태를 보정하세요.',
  },
  {
    id: '3',
    icon: '🔔',
    title: '맞춤형 알림',
    headline: '알림은 생활 리듬에 맞게',
    description:
      '원하는 간격, 허용 시간대, 요일에 따라 나만의 맞춤형 알림 스케줄을 손쉽게 설정해 보세요.',
  },
];

export default function OnboardingScreen() {
  const { state, completeOnboarding } = useAppState();
  const router = useRouter();
  const [activeIndex, setActiveIndex] = useState(0);
  const flatListRef = useRef<FlatList>(null);

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const handleScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const slide = Math.round(event.nativeEvent.contentOffset.x / width);
    if (slide !== activeIndex) {
      setActiveIndex(slide);
    }
  };

  const handleFinish = async () => {
    await completeOnboarding();
    router.replace('/(tabs)');
  };

  const handleNext = () => {
    if (activeIndex < onboardingPages.length - 1) {
      flatListRef.current?.scrollToIndex({ index: activeIndex + 1 });
    } else {
      handleFinish();
    }
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header Skip Button */}
      <View style={styles.header}>
        <Pressable onPress={handleFinish} style={styles.skipBtn}>
          <Text style={[styles.skipText, { color: colors.textSecondary }]}>건너뛰기</Text>
        </Pressable>
      </View>

      {/* Pages Carousel */}
      <FlatList
        ref={flatListRef}
        data={onboardingPages}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onScroll={handleScroll}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={[styles.pageContainer, { width }]}>
            <View style={[styles.iconCircle, { backgroundColor: colors.surfaceSecondary }]}>
              <Text style={styles.icon}>{item.icon}</Text>
            </View>

            <Text style={[styles.badge, { backgroundColor: colors.accentLight, color: colors.accent }]}>
              {item.title}
            </Text>
            <Text style={[styles.headline, { color: colors.textPrimary }]}>{item.headline}</Text>
            <Text style={[styles.description, { color: colors.textSecondary }]}>
              {item.description}
            </Text>
          </View>
        )}
      />

      {/* Footer Controls */}
      <View style={styles.footer}>
        {/* Page Dots Indicator (16px active, 8px inactive) */}
        <View style={styles.dotsRow}>
          {onboardingPages.map((_, idx) => (
            <View
              key={idx}
              style={[
                styles.dot,
                {
                  backgroundColor: idx === activeIndex ? colors.accent : colors.border,
                  width: idx === activeIndex ? 16 : 8,
                },
              ]}
            />
          ))}
        </View>

        {/* Action Button */}
        <Pressable
          style={[styles.nextBtn, { backgroundColor: colors.accent }]}
          onPress={handleNext}
        >
          <Text style={styles.nextBtnText}>
            {activeIndex === onboardingPages.length - 1 ? '시작하기' : '다음'}
          </Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'space-between',
  },
  header: {
    paddingHorizontal: 24,
    paddingTop: 12,
    alignItems: 'flex-end',
  },
  skipBtn: {
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  skipText: {
    fontSize: 14,
    fontWeight: '600',
  },
  pageContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  iconCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 32,
  },
  icon: {
    fontSize: 44,
  },
  badge: {
    fontSize: 12,
    fontWeight: '700',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 10,
    overflow: 'hidden',
    marginBottom: 12,
  },
  headline: {
    fontSize: 24,
    fontWeight: '800',
    textAlign: 'center',
    marginBottom: 14,
    letterSpacing: -0.5,
  },
  description: {
    fontSize: 14,
    lineHeight: 22,
    textAlign: 'center',
  },
  footer: {
    paddingHorizontal: 24,
    paddingBottom: 32,
    alignItems: 'center',
  },
  dotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 24,
  },
  dot: {
    height: 8,
    borderRadius: 4,
  },
  nextBtn: {
    width: '100%',
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
  },
  nextBtnText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FFFFFF',
  },
});
