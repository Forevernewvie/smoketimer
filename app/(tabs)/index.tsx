// app/(tabs)/index.tsx
import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../../src/context/AppStateContext';
import { ThemeColors } from '../../src/constants/theme';
import { HeroTimerGauge } from '../../src/components/HeroTimerGauge';
import { RhythmCoachCard } from '../../src/components/RhythmCoachCard';
import { CravingPauseModal } from '../../src/components/CravingPauseModal';
import { formatCurrency } from '../../src/domain/defaults';

export default function HomeScreen() {
  const { state, addSmokingLog, undoLastLog } = useAppState();
  const [showCravingModal, setShowCravingModal] = useState(false);

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  // Calculate Today's Cigarettes & Cost
  const getTodayStats = () => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const todayLogs = state.logs.filter((l) => l.timestamp >= startOfDay);

    const count = todayLogs.length;
    const pricePerCig = state.costConfig.packPrice / state.costConfig.cigarettesPerPack;
    const spend = count * pricePerCig;

    return { count, spend };
  };

  const todayStats = getTodayStats();

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.appTitle, { color: colors.textPrimary }]}>Smoke Timer</Text>
          <Text style={[styles.dateText, { color: colors.textSecondary }]}>
            {new Date().toLocaleDateString('ko-KR', {
              month: 'long',
              day: 'numeric',
              weekday: 'short',
            })}
          </Text>
        </View>

        {/* Hero Timer Arc Gauge */}
        <HeroTimerGauge size={240} strokeWidth={14} />

        {/* Quick Actions (CTA & Undo) */}
        <View style={styles.actionsRow}>
          {/* Main CTA: Record Smoking Now */}
          <Pressable
            style={[styles.mainActionBtn, { backgroundColor: colors.accent }]}
            onPress={() => addSmokingLog()}
          >
            <Text style={styles.mainActionText}>지금 흡연 기록</Text>
          </Pressable>

          {/* Secondary CTA: Undo Last Record */}
          <Pressable
            style={[
              styles.undoBtn,
              {
                backgroundColor: colors.surfaceSecondary,
                opacity: state.logs.length > 0 ? 1 : 0.5,
              },
            ]}
            onPress={() => undoLastLog()}
            disabled={state.logs.length === 0}
          >
            <Text style={[styles.undoText, { color: colors.textPrimary }]}>↺ 되돌리기</Text>
          </Pressable>
        </View>

        {/* Rhythm Coach Card */}
        <RhythmCoachCard />

        {/* 3-Minute Craving Pause Routine Card */}
        <Pressable
          style={[styles.cravingCard, { backgroundColor: colors.surface, borderColor: colors.border }]}
          onPress={() => setShowCravingModal(true)}
        >
          <View style={styles.cravingHeader}>
            <Text style={styles.cravingIcon}>🧘</Text>
            <View style={styles.cravingTextCol}>
              <Text style={[styles.cravingTitle, { color: colors.textPrimary }]}>
                3분 대기 루틴 (Craving Pause)
              </Text>
              <Text style={[styles.cravingSub, { color: colors.textSecondary }]}>
                흡연 욕구가 일 때 깊은 호흡과 대기 루틴을 시작해보세요
              </Text>
            </View>
          </View>
        </Pressable>

        {/* Today Summary Card */}
        <View style={[styles.todayCard, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text style={[styles.todayTitle, { color: colors.textSecondary }]}>오늘의 일일 요약</Text>
          <View style={styles.todayMetricsRow}>
            <View style={styles.metricCol}>
              <Text style={[styles.metricValue, { color: colors.textPrimary }]}>
                {todayStats.count} <Text style={styles.unitText}>개비</Text>
              </Text>
              <Text style={[styles.metricLabel, { color: colors.textMuted }]}>오늘 총 흡연</Text>
            </View>

            <View style={[styles.divider, { backgroundColor: colors.border }]} />

            <View style={styles.metricCol}>
              <Text style={[styles.metricValue, { color: colors.accent }]}>
                {formatCurrency(todayStats.spend, state.costConfig.currency)}
              </Text>
              <Text style={[styles.metricLabel, { color: colors.textMuted }]}>오늘 지출 금액</Text>
            </View>
          </View>
        </View>
      </ScrollView>

      {/* Craving Pause Modal */}
      <CravingPauseModal
        visible={showCravingModal}
        onClose={() => setShowCravingModal(false)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 24,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
  },
  appTitle: {
    fontSize: 24,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  dateText: {
    fontSize: 13,
    fontWeight: '600',
  },
  actionsRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    gap: 10,
    marginVertical: 12,
  },
  mainActionBtn: {
    flex: 2,
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  mainActionText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
  },
  undoBtn: {
    flex: 1,
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  undoText: {
    fontSize: 14,
    fontWeight: '700',
  },
  cravingCard: {
    marginHorizontal: 16,
    marginVertical: 6,
    padding: 14,
    borderRadius: 16,
    borderWidth: 1,
  },
  cravingHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  cravingIcon: {
    fontSize: 24,
  },
  cravingTextCol: {
    flex: 1,
  },
  cravingTitle: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 2,
  },
  cravingSub: {
    fontSize: 12,
  },
  todayCard: {
    marginHorizontal: 16,
    marginTop: 8,
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
  },
  todayTitle: {
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 12,
  },
  todayMetricsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metricCol: {
    flex: 1,
    alignItems: 'center',
  },
  metricValue: {
    fontSize: 22,
    fontWeight: '800',
    marginBottom: 2,
  },
  unitText: {
    fontSize: 13,
    fontWeight: '600',
  },
  metricLabel: {
    fontSize: 11,
    fontWeight: '600',
  },
  divider: {
    width: 1,
    height: 32,
  },
});
