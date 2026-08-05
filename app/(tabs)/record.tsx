// app/(tabs)/record.tsx
import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../../src/context/AppStateContext';
import { ThemeColors } from '../../src/constants/theme';
import { StatCard } from '../../src/components/StatCard';
import { formatCurrency } from '../../src/domain/defaults';
import { formatMinutes } from '../../src/services/alertScheduler';

type PeriodFilter = 'today' | 'weekly' | 'monthly';

export default function RecordScreen() {
  const { state, deleteSmokingLog } = useAppState();
  const [filter, setFilter] = useState<PeriodFilter>('today');

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  // Filter Logs based on Period Segment
  const getFilteredLogs = () => {
    const now = new Date();
    let startTime = 0;

    if (filter === 'today') {
      startTime = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    } else if (filter === 'weekly') {
      const dayOfWeek = now.getDay() === 0 ? 6 : now.getDay() - 1; // Mon=0
      startTime = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek).getTime();
    } else if (filter === 'monthly') {
      startTime = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    }

    return state.logs.filter((l) => l.timestamp >= startTime);
  };

  const filteredLogs = getFilteredLogs();

  // Pattern Insight Calculation (Non-judgmental)
  const getPatternInsight = () => {
    if (state.logs.length < 3) {
      return {
        peakHourStr: '기록 누적 중',
        bestDayStr: '기록 누적 중',
        body: '3건 이상의 기록이 누적되면 사용자님의 차분한 행동 패턴 분석 리포트가 생성됩니다.',
      };
    }

    // 1. Peak Hour Calculation
    const hourCounts: Record<number, number> = {};
    state.logs.forEach((log) => {
      const hour = new Date(log.timestamp).getHours();
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    });

    let peakHour = 14;
    let maxHourCount = 0;
    Object.entries(hourCounts).forEach(([h, count]) => {
      if (count > maxHourCount) {
        maxHourCount = count;
        peakHour = parseInt(h, 10);
      }
    });

    // 2. Best Weekday Interval
    const weekdayLabels = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    const now = new Date();
    const currentWeekday = weekdayLabels[now.getDay()];

    return {
      peakHourStr: `오후 ${peakHour > 12 ? peakHour - 12 : peakHour}시 ~ ${peakHour + 1 > 12 ? peakHour + 1 - 12 : peakHour + 1}시`,
      bestDayStr: currentWeekday,
      body: `가장 집중 기록되는 시간대는 [오후 ${peakHour > 12 ? peakHour - 12 : peakHour}시 대]이며, 현재 차분한 리듬이 일정하게 유지되고 있습니다.`,
    };
  };

  const patternInsight = getPatternInsight();

  // Statistics Calculation
  const calculateStats = () => {
    const totalCount = filteredLogs.length;
    const pricePerCig = state.costConfig.packPrice / state.costConfig.cigarettesPerPack;
    const periodSpend = totalCount * pricePerCig;

    let daysCount = 1;
    if (filter === 'weekly') daysCount = 7;
    if (filter === 'monthly') daysCount = 30;

    const dailyAvgSpend = periodSpend / daysCount;

    let avgIntervalStr = '-';
    let maxIntervalStr = '-';

    if (filteredLogs.length >= 2) {
      const sorted = [...filteredLogs].sort((a, b) => a.timestamp - b.timestamp);
      const intervals: number[] = [];

      for (let i = 1; i < sorted.length; i++) {
        const diffMins = Math.floor((sorted[i].timestamp - sorted[i - 1].timestamp) / (1000 * 60));
        intervals.push(diffMins);
      }

      if (intervals.length > 0) {
        const avgMins = Math.round(intervals.reduce((a, b) => a + b, 0) / intervals.length);
        const maxMins = Math.max(...intervals);

        avgIntervalStr = formatMinutes(avgMins);
        maxIntervalStr = formatMinutes(maxMins);
      }
    }

    return {
      totalCount: `${totalCount}개비`,
      avgInterval: avgIntervalStr,
      maxInterval: maxIntervalStr,
      periodSpend: formatCurrency(periodSpend, state.costConfig.currency),
      dailyAvgSpend: formatCurrency(dailyAvgSpend, state.costConfig.currency),
    };
  };

  const stats = calculateStats();
  const recentLogs = state.logs.slice(0, 20);

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: colors.textPrimary }]}>통계 및 기록</Text>
        <Text style={[styles.subTitle, { color: colors.textSecondary }]}>흡연 패턴과 지출 요약</Text>
      </View>

      {/* Period Filter Segment */}
      <View style={[styles.segmentContainer, { backgroundColor: colors.surfaceSecondary }]}>
        {(['today', 'weekly', 'monthly'] as PeriodFilter[]).map((p) => {
          const isActive = filter === p;
          const labels: Record<PeriodFilter, string> = {
            today: '오늘',
            weekly: '주간',
            monthly: '월간',
          };
          return (
            <Pressable
              key={p}
              style={[
                styles.segmentBtn,
                { backgroundColor: isActive ? colors.surface : 'transparent' },
              ]}
              onPress={() => setFilter(p)}
            >
              <Text
                style={[
                  styles.segmentText,
                  { color: isActive ? colors.accent : colors.textSecondary },
                ]}
              >
                {labels[p]}
              </Text>
            </Pressable>
          );
        })}
      </View>

      <ScrollView contentContainerStyle={styles.scrollBody} showsVerticalScrollIndicator={false}>
        {/* Metric Stat Cards Grid */}
        <View style={styles.statsGrid}>
          <StatCard label="기간 총 흡연" value={stats.totalCount} icon="🚬" />
          <StatCard label="평균 흡연 간격" value={stats.avgInterval} icon="⏱️" />
          <StatCard label="최장 흡연 간격" value={stats.maxInterval} icon="🏆" />
          <StatCard label="기간 누적 지출" value={stats.periodSpend} icon="💰" />
        </View>

        {/* Behavioral Pattern Insight Card */}
        <View style={[styles.insightCard, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <View style={styles.insightHeader}>
            <Text style={[styles.insightBadge, { backgroundColor: colors.accentLight, color: colors.accent }]}>
              💡 차분한 행동 트렌드 리포트
            </Text>
          </View>
          <Text style={[styles.insightBody, { color: colors.textPrimary }]}>{patternInsight.body}</Text>
          <View style={styles.insightStatsRow}>
            <Text style={[styles.insightSubText, { color: colors.textSecondary }]}>
              주요 시간대: <Text style={{ color: colors.accent, fontWeight: '700' }}>{patternInsight.peakHourStr}</Text>
            </Text>
          </View>
        </View>

        {/* Recent Logs List */}
        <View style={styles.logListHeader}>
          <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>최근 흡연 기록</Text>
          <Text style={[styles.sectionSub, { color: colors.textMuted }]}>최근 20건 (터치하여 삭제)</Text>
        </View>

        {recentLogs.length === 0 ? (
          <View style={[styles.emptyBox, { backgroundColor: colors.surface, borderColor: colors.border }]}>
            <Text style={[styles.emptyText, { color: colors.textMuted }]}>아직 기록이 없습니다.</Text>
          </View>
        ) : (
          recentLogs.map((log) => {
            const dateObj = new Date(log.timestamp);
            const timeStr = dateObj.toLocaleTimeString('ko-KR', {
              hour: '2-digit',
              minute: '2-digit',
              hour12: !state.displaySettings.is24HourFormat,
            });
            const dateStr = dateObj.toLocaleDateString('ko-KR', {
              month: 'short',
              day: 'numeric',
              weekday: 'short',
            });

            return (
              <View
                key={log.id}
                style={[styles.logRow, { backgroundColor: colors.surface, borderColor: colors.border }]}
              >
                <View style={styles.logTextCol}>
                  <Text style={[styles.logTime, { color: colors.textPrimary }]}>{timeStr}</Text>
                  <Text style={[styles.logDate, { color: colors.textSecondary }]}>{dateStr}</Text>
                </View>

                <Pressable
                  onPress={() => deleteSmokingLog(log.id)}
                  style={[styles.deleteBtn, { backgroundColor: colors.dangerLight }]}
                >
                  <Text style={[styles.deleteText, { color: colors.danger }]}>삭제</Text>
                </Pressable>
              </View>
            );
          })
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 12,
    marginBottom: 12,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  subTitle: {
    fontSize: 13,
    fontWeight: '500',
    marginTop: 2,
  },
  segmentContainer: {
    flexDirection: 'row',
    marginHorizontal: 16,
    padding: 4,
    borderRadius: 12,
    marginBottom: 16,
  },
  segmentBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  segmentText: {
    fontSize: 13,
    fontWeight: '700',
  },
  scrollBody: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginBottom: 14,
  },
  insightCard: {
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    marginBottom: 20,
  },
  insightHeader: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  insightBadge: {
    fontSize: 11,
    fontWeight: '700',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    overflow: 'hidden',
  },
  insightBody: {
    fontSize: 13,
    lineHeight: 19,
    fontWeight: '600',
    marginBottom: 6,
  },
  insightStatsRow: {
    marginTop: 4,
  },
  insightSubText: {
    fontSize: 12,
  },
  logListHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '800',
  },
  sectionSub: {
    fontSize: 11,
    fontWeight: '500',
  },
  emptyBox: {
    padding: 32,
    borderRadius: 16,
    borderWidth: 1,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    fontWeight: '500',
  },
  logRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    marginBottom: 8,
  },
  logTextCol: {
    flex: 1,
  },
  logTime: {
    fontSize: 16,
    fontWeight: '700',
  },
  logDate: {
    fontSize: 12,
    fontWeight: '500',
    marginTop: 2,
  },
  deleteBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  deleteText: {
    fontSize: 12,
    fontWeight: '700',
  },
});
