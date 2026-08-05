// src/components/RhythmCoachCard.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';

export const RhythmCoachCard: React.FC = () => {
  const { state } = useAppState();
  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const lastSmokingAt = state.logs.length > 0 ? state.logs[0].timestamp : null;

  const getCoachMessage = () => {
    if (!lastSmokingAt) {
      return {
        title: '차분한 시각의 시작',
        body: '첫 흡연을 기록하면 목표 알림 간격에 맞춘 리듬 가이드가 시작됩니다.',
      };
    }

    const elapsedMinutes = (Date.now() - lastSmokingAt) / (1000 * 60);
    const targetMinutes = state.alertConfig.intervalMinutes;

    if (elapsedMinutes < targetMinutes * 0.5) {
      return {
        title: '여유로운 시간',
        body: '목표 간격의 절반도 지나지 않았습니다. 차분하게 현재 할 일에 집중해 보세요.',
      };
    } else if (elapsedMinutes < targetMinutes - state.alertConfig.preAlertMinutes) {
      return {
        title: '순조로운 흐름',
        body: '목표 시점에 가까워지고 있습니다. 편안한 마음으로 리듬을 유지해 보세요.',
      };
    } else if (elapsedMinutes <= targetMinutes) {
      return {
        title: '미리 준비하는 시점',
        body: '다음 알림 예정 시각이 다가옵니다. 마시는 물 한 잔이나 깊은 호흡이 도움이 될 수 있습니다.',
      };
    }
    return {
      title: '목표 간격 달성',
      body: `설정한 ${targetMinutes}분 간격을 충족했습니다. 유저님의 차분한 리듬을 지지합니다.`,
    };
  };

  const message = getCoachMessage();

  return (
    <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
      <View style={styles.headerRow}>
        <Text style={[styles.badge, { backgroundColor: colors.accentLight, color: colors.accent }]}>
          Warm Rhythm Coach
        </Text>
      </View>
      <Text style={[styles.title, { color: colors.textPrimary }]}>{message.title}</Text>
      <Text style={[styles.body, { color: colors.textSecondary }]}>{message.body}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    marginHorizontal: 16,
    marginVertical: 8,
  },
  headerRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  badge: {
    fontSize: 11,
    fontWeight: '700',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    overflow: 'hidden',
  },
  title: {
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 4,
  },
  body: {
    fontSize: 13,
    lineHeight: 19,
  },
});
