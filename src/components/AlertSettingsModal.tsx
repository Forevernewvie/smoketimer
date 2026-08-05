// src/components/AlertSettingsModal.tsx
import React, { useState } from 'react';
import { Modal, View, Text, StyleSheet, Pressable, ScrollView, Switch } from 'react-native';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';
import { formatMinutes, formatMinutesToTimeString } from '../services/alertScheduler';

interface AlertSettingsModalProps {
  visible: boolean;
  onClose: () => void;
}

export const AlertSettingsModal: React.FC<AlertSettingsModalProps> = ({ visible, onClose }) => {
  const { state, updateAlertConfig } = useAppState();
  const config = state.alertConfig;

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const weekdays = [
    { id: 1, label: '월' },
    { id: 2, label: '화' },
    { id: 3, label: '수' },
    { id: 4, label: '목' },
    { id: 5, label: '금' },
    { id: 6, label: '토' },
    { id: 7, label: '일' },
  ];

  const toggleWeekday = (id: number) => {
    let updated = [...config.activeWeekdays];
    if (updated.includes(id)) {
      if (updated.length > 1) {
        updated = updated.filter((w) => w !== id);
      }
    } else {
      updated.push(id);
    }
    updateAlertConfig({ activeWeekdays: updated });
  };

  const adjustInterval = (delta: number) => {
    const next = Math.max(30, Math.min(240, config.intervalMinutes + delta));
    updateAlertConfig({ intervalMinutes: next });
  };

  const adjustPreAlert = (delta: number) => {
    const next = Math.max(0, Math.min(15, config.preAlertMinutes + delta));
    updateAlertConfig({ preAlertMinutes: next });
  };

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={[styles.container, { backgroundColor: colors.surface }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: colors.textPrimary }]}>알림 세부 설정</Text>
            <Pressable onPress={onClose} style={styles.closeIcon}>
              <Text style={{ color: colors.textSecondary, fontSize: 18, fontWeight: '700' }}>✕</Text>
            </Pressable>
          </View>

          <ScrollView style={styles.scrollBody} showsVerticalScrollIndicator={false}>
            {/* Enable Alert Switch */}
            <View style={[styles.row, { borderColor: colors.border }]}>
              <Text style={[styles.label, { color: colors.textPrimary }]}>알림 스케줄 가동</Text>
              <Switch
                value={config.enabled}
                onValueChange={(val) => updateAlertConfig({ enabled: val })}
                trackColor={{ false: colors.border, true: colors.accent }}
              />
            </View>

            {/* Interval Setting */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>목표 알림 간격</Text>
              <Text style={[styles.sectionSub, { color: colors.textSecondary }]}>
                흡연 후 다음 알림까지의 시간을 설정합니다 (30분~4시간)
              </Text>

              <View style={styles.stepperRow}>
                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustInterval(-5)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>- 5분</Text>
                </Pressable>

                <Text style={[styles.valueText, { color: colors.accent }]}>
                  {formatMinutes(config.intervalMinutes)}
                </Text>

                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustInterval(5)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>+ 5분</Text>
                </Pressable>
              </View>
            </View>

            {/* Pre-Alert Setting */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>미리 알림 (인지적 완충)</Text>
              <Text style={[styles.sectionSub, { color: colors.textSecondary }]}>
                목표 시간 정각 전 마음의 준비를 위한 사전 알림 (0~15분)
              </Text>

              <View style={styles.stepperRow}>
                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustPreAlert(-1)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>- 1분</Text>
                </Pressable>

                <Text style={[styles.valueText, { color: colors.accent }]}>
                  {config.preAlertMinutes === 0 ? '미사용 (0분)' : `${config.preAlertMinutes}분 전`}
                </Text>

                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustPreAlert(1)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>+ 1분</Text>
                </Pressable>
              </View>
            </View>

            {/* Active Weekdays */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>알림 수신 요일</Text>
              <View style={styles.weekdayRow}>
                {weekdays.map((w) => {
                  const isActive = config.activeWeekdays.includes(w.id);
                  return (
                    <Pressable
                      key={w.id}
                      style={[
                        styles.chip,
                        {
                          backgroundColor: isActive ? colors.accent : colors.surfaceSecondary,
                        },
                      ]}
                      onPress={() => toggleWeekday(w.id)}
                    >
                      <Text
                        style={[
                          styles.chipText,
                          { color: isActive ? '#FFFFFF' : colors.textSecondary },
                        ]}
                      >
                        {w.label}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
            </View>

            {/* Allowed Window */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>하루 알림 허용 시간대</Text>
              <Text style={[styles.sectionSub, { color: colors.textSecondary }]}>
                취침 시간을 배려하여 알림을 수신할 하루 시간대를 설정합니다
              </Text>
              <View style={styles.timeWindowBox}>
                <Text style={[styles.timeWindowText, { color: colors.textPrimary }]}>
                  {formatMinutesToTimeString(config.allowedStartMinutes)} ~ {formatMinutesToTimeString(config.allowedEndMinutes)}
                </Text>
              </View>
            </View>
          </ScrollView>

          <Pressable style={[styles.confirmBtn, { backgroundColor: colors.accent }]} onPress={onClose}>
            <Text style={styles.confirmBtnText}>설정 완료</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  container: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '85%',
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '800',
  },
  closeIcon: {
    padding: 4,
  },
  scrollBody: {
    marginBottom: 16,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
  },
  label: {
    fontSize: 15,
    fontWeight: '700',
  },
  section: {
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 2,
  },
  sectionSub: {
    fontSize: 12,
    marginBottom: 10,
  },
  stepperRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  stepperBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 10,
  },
  stepperText: {
    fontSize: 13,
    fontWeight: '700',
  },
  valueText: {
    fontSize: 18,
    fontWeight: '800',
  },
  weekdayRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  chip: {
    width: 38,
    height: 38,
    borderRadius: 19,
    justifyContent: 'center',
    alignItems: 'center',
  },
  chipText: {
    fontSize: 13,
    fontWeight: '700',
  },
  timeWindowBox: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  timeWindowText: {
    fontSize: 16,
    fontWeight: '700',
  },
  confirmBtn: {
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
  },
  confirmBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
  },
});
