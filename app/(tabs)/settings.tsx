// app/(tabs)/settings.tsx
import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, Switch, Alert, Share } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAppState } from '../../src/context/AppStateContext';
import { ThemeColors } from '../../src/constants/theme';
import { AlertSettingsModal } from '../../src/components/AlertSettingsModal';
import { CostSettingsModal } from '../../src/components/CostSettingsModal';
import { formatMinutes } from '../../src/services/alertScheduler';
import { formatCurrency } from '../../src/domain/defaults';

export default function SettingsScreen() {
  const { state, updateDisplaySettings, updateAlertConfig, resetAllData } = useAppState();
  const router = useRouter();

  const [showAlertModal, setShowAlertModal] = useState(false);
  const [showCostModal, setShowCostModal] = useState(false);

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const handleExportData = async () => {
    try {
      const exportObject = {
        app: 'Smoke Timer (Warm Ritual Timer)',
        version: '2.0.0',
        exportedAt: new Date().toISOString(),
        logs: state.logs,
        costConfig: state.costConfig,
        alertConfig: state.alertConfig,
      };

      const jsonString = JSON.stringify(exportObject, null, 2);

      await Share.share({
        title: 'Smoke Timer Local Backup Data',
        message: jsonString,
      });
    } catch (error) {
      Alert.alert('내보내기 오류', '데이터 내보내기 중 문제가 발생했습니다.');
    }
  };

  const handleResetData = () => {
    Alert.alert(
      '데이터 전체 초기화',
      '저장된 모든 흡연 기록 및 설정이 삭제됩니다. 초기화하시겠습니까?',
      [
        { text: '취소', style: 'cancel' },
        {
          text: '초기화',
          style: 'destructive',
          onPress: async () => {
            await resetAllData();
            router.replace('/splash');
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: colors.textPrimary }]}>앱 설정</Text>
        <Text style={[styles.subTitle, { color: colors.textSecondary }]}>화면, 알림, 비용 및 백업 관리</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollBody} showsVerticalScrollIndicator={false}>
        {/* Display Settings Section */}
        <View style={styles.sectionHeader}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>화면 및 표시 설정</Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <View style={[styles.row, { borderColor: colors.border }]}>
            <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>다크 모드 테마</Text>
            <Switch
              value={state.displaySettings.isDarkMode}
              onValueChange={(val) => updateDisplaySettings({ isDarkMode: val })}
              trackColor={{ false: colors.border, true: colors.accent }}
            />
          </View>

          <View style={[styles.row, { borderColor: colors.border }]}>
            <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>24시간 시간 표기</Text>
            <Switch
              value={state.displaySettings.is24HourFormat}
              onValueChange={(val) => updateDisplaySettings({ is24HourFormat: val })}
              trackColor={{ false: colors.border, true: colors.accent }}
            />
          </View>
        </View>

        {/* Schedule & Cost Entry Points */}
        <View style={styles.sectionHeader}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>스케줄 & 비용 설정</Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          {/* Alert Settings */}
          <Pressable
            style={[styles.navigationRow, { borderColor: colors.border }]}
            onPress={() => setShowAlertModal(true)}
          >
            <View>
              <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>알림 스케줄 설정</Text>
              <Text style={[styles.rowSub, { color: colors.textSecondary }]}>
                {state.alertConfig.enabled ? `켜짐 • ${formatMinutes(state.alertConfig.intervalMinutes)} 간격` : '꺼짐'}
              </Text>
            </View>
            <Text style={[styles.chevron, { color: colors.textMuted }]}>›</Text>
          </Pressable>

          {/* Cost Settings */}
          <Pressable
            style={styles.navigationRow}
            onPress={() => setShowCostModal(true)}
          >
            <View>
              <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>담배 가격 및 통화 설정</Text>
              <Text style={[styles.rowSub, { color: colors.textSecondary }]}>
                {formatCurrency(state.costConfig.packPrice, state.costConfig.currency)} ({state.costConfig.cigarettesPerPack}개비/갑)
              </Text>
            </View>
            <Text style={[styles.chevron, { color: colors.textMuted }]}>›</Text>
          </Pressable>
        </View>

        {/* Data & Privacy */}
        <View style={styles.sectionHeader}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>데이터 및 약관</Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Pressable
            style={[styles.navigationRow, { borderColor: colors.border }]}
            onPress={handleExportData}
          >
            <View>
              <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>100% 로컬 데이터 백업 / 내보내기</Text>
              <Text style={[styles.rowSub, { color: colors.textSecondary }]}>
                서버 전송 없이 내 기기에 안전하게 JSON 데이터 공유 및 보관
              </Text>
            </View>
            <Text style={[styles.chevron, { color: colors.accent }]}>📦</Text>
          </Pressable>

          <Pressable
            style={[styles.navigationRow, { borderColor: colors.border }]}
            onPress={() => router.push('/privacy')}
          >
            <Text style={[styles.rowLabel, { color: colors.textPrimary }]}>개인정보 처리방침 (Privacy Policy)</Text>
            <Text style={[styles.chevron, { color: colors.textMuted }]}>›</Text>
          </Pressable>

          <Pressable style={styles.navigationRow} onPress={handleResetData}>
            <Text style={[styles.rowLabel, { color: colors.danger }]}>데이터 전체 초기화</Text>
            <Text style={[styles.chevron, { color: colors.danger }]}>›</Text>
          </Pressable>
        </View>
      </ScrollView>

      {/* Modals */}
      <AlertSettingsModal
        visible={showAlertModal}
        onClose={() => setShowAlertModal(false)}
      />
      <CostSettingsModal
        visible={showCostModal}
        onClose={() => setShowCostModal(false)}
      />
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
  scrollBody: {
    paddingHorizontal: 16,
    paddingBottom: 32,
  },
  sectionHeader: {
    marginTop: 14,
    marginBottom: 6,
    paddingHorizontal: 4,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
  },
  card: {
    borderRadius: 16,
    borderWidth: 1,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  navigationRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  rowLabel: {
    fontSize: 15,
    fontWeight: '600',
  },
  rowSub: {
    fontSize: 12,
    marginTop: 2,
  },
  chevron: {
    fontSize: 18,
    fontWeight: '600',
  },
});
