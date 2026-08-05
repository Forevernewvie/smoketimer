// src/components/HeroTimerGauge.tsx
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';

interface HeroTimerGaugeProps {
  size?: number;
  strokeWidth?: number;
}

export const HeroTimerGauge: React.FC<HeroTimerGaugeProps> = ({
  size = 220,
  strokeWidth = 12,
}) => {
  const { state } = useAppState();
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const lastSmokingTimestamp = state.logs.length > 0 ? state.logs[0].timestamp : null;

  // 1-second interval ticker
  useEffect(() => {
    const updateElapsed = () => {
      if (!lastSmokingTimestamp) {
        setElapsedSeconds(0);
        return;
      }
      const now = Date.now();
      const diffSec = Math.max(0, Math.floor((now - lastSmokingTimestamp) / 1000));
      setElapsedSeconds(diffSec);
    };

    updateElapsed();
    const interval = setInterval(updateElapsed, 1000);
    return () => clearInterval(interval);
  }, [lastSmokingTimestamp]);

  // Calculations for Arc Progress
  const targetMinutes = state.alertConfig.intervalMinutes;
  const targetSeconds = targetMinutes * 60;
  const progressRatio = targetSeconds > 0 ? Math.min(1, elapsedSeconds / targetSeconds) : 0;

  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progressRatio);

  // Time Formatter
  const formatTime = (totalSec: number) => {
    if (!lastSmokingTimestamp) return { main: '첫 기록 전', sub: '기록을 남기면 타이머가 시작돼요' };
    const hours = Math.floor(totalSec / 3600);
    const minutes = Math.floor((totalSec % 3600) / 60);
    const seconds = totalSec % 60;

    if (hours > 0) {
      return {
        main: `${hours}시간 ${minutes}분`,
        sub: `${String(seconds).padStart(2, '0')}초`,
      };
    }
    return {
      main: `${minutes}분`,
      sub: `${String(seconds).padStart(2, '0')}초`,
    };
  };

  // Status Badge Logic
  const getStatusInfo = () => {
    if (!lastSmokingTimestamp) return { label: '대기 중', bg: colors.surfaceSecondary, color: colors.textSecondary };
    const elapsedMinutes = elapsedSeconds / 60;
    if (elapsedMinutes < targetMinutes - state.alertConfig.preAlertMinutes) {
      return { label: '진행 중', bg: colors.accentLight, color: colors.accent };
    } else if (elapsedMinutes <= targetMinutes) {
      return { label: '확인 시점', bg: colors.warningLight, color: colors.warning };
    }
    return { label: '간격 초과', bg: colors.successLight, color: colors.success };
  };

  const { main, sub } = formatTime(elapsedSeconds);
  const status = getStatusInfo();

  return (
    <View style={[styles.container, { width: size, height: size }]}>
      <Svg width={size} height={size} style={styles.svg}>
        {/* Background Track Circle */}
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={colors.border}
          strokeWidth={strokeWidth}
          fill="none"
        />
        {/* Animated Progress Arc Circle */}
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={colors.accent}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          fill="none"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>

      <View style={styles.content}>
        {/* Status Badge */}
        <View style={[styles.statusBadge, { backgroundColor: status.bg }]}>
          <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
        </View>

        {/* Hero Time Display */}
        <Text style={[styles.mainTimeText, { color: colors.textPrimary }]}>{main}</Text>
        <Text style={[styles.subTimeText, { color: colors.textSecondary }]}>{sub}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center',
    marginVertical: 16,
  },
  svg: {
    position: 'absolute',
  },
  content: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
    marginBottom: 8,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '700',
  },
  mainTimeText: {
    fontSize: 32,
    fontWeight: '800',
    textAlign: 'center',
    letterSpacing: -0.5,
  },
  subTimeText: {
    fontSize: 14,
    fontWeight: '500',
    marginTop: 2,
  },
});
