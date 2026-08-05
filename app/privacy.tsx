// app/privacy.tsx
import React from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../src/context/AppStateContext';
import { ThemeColors } from '../src/constants/theme';

export default function PrivacyPolicyScreen() {
  const { state } = useAppState();
  const router = useRouter();

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: colors.textPrimary }]}>개인정보 처리방침</Text>
        <Pressable onPress={() => router.back()} style={styles.closeBtn}>
          <Text style={{ color: colors.textSecondary, fontSize: 16, fontWeight: '700' }}>닫기</Text>
        </Pressable>
      </View>

      <ScrollView style={styles.body} showsVerticalScrollIndicator={false}>
        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text style={[styles.cardTitle, { color: colors.accent }]}>🔒 100% 온디바이스 개인정보 보호</Text>
          <Text style={[styles.paragraph, { color: colors.textPrimary }]}>
            Smoke Timer는 사용자의 민감한 건강 및 행동 데이터를 소중히 보호합니다.
          </Text>

          <Text style={[styles.sectionHeading, { color: colors.textPrimary }]}>1. 서버 수집 제로 (Privacy First)</Text>
          <Text style={[styles.paragraph, { color: colors.textSecondary }]}>
            Smoke Timer는 회원가입, 소셜 계정 로그인, 외부 서버 동기화 기능을 전혀 사용하지 않습니다. 모든 흡연 기록 및 지출 설정은 사용자 기기의 암호화된 온디바이스 저장소(AsyncStorage)에만 저장됩니다.
          </Text>

          <Text style={[styles.sectionHeading, { color: colors.textPrimary }]}>2. 타겟팅 광고 및 추적 제로</Text>
          <Text style={[styles.paragraph, { color: colors.textSecondary }]}>
            사용자의 개인 기록 데이터는 어떠한 제3자 플랫폼이나 타겟팅 광고 서버로 전송되지 않습니다.
          </Text>

          <Text style={[styles.sectionHeading, { color: colors.textPrimary }]}>3. 데이터의 완전 파기</Text>
          <Text style={[styles.paragraph, { color: colors.textSecondary }]}>
            앱을 삭제하거나 [설정] &gt; [데이터 전체 초기화]를 실행하시면 기기 내에 저장된 모든 기록이 즉시 영구적으로 파기됩니다.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 12,
  },
  title: {
    fontSize: 20,
    fontWeight: '800',
  },
  closeBtn: {
    padding: 6,
  },
  body: {
    paddingHorizontal: 16,
    paddingTop: 8,
  },
  card: {
    padding: 20,
    borderRadius: 20,
    borderWidth: 1,
    marginBottom: 24,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 12,
  },
  sectionHeading: {
    fontSize: 14,
    fontWeight: '700',
    marginTop: 14,
    marginBottom: 4,
  },
  paragraph: {
    fontSize: 13,
    lineHeight: 20,
  },
});
