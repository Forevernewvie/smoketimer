// src/components/CostSettingsModal.tsx
import React, { useState } from 'react';
import { Modal, View, Text, StyleSheet, Pressable, TextInput, ScrollView } from 'react-native';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';
import { CurrencyCode } from '../domain/types';
import { formatCurrency } from '../domain/defaults';

interface CostSettingsModalProps {
  visible: boolean;
  onClose: () => void;
}

export const CostSettingsModal: React.FC<CostSettingsModalProps> = ({ visible, onClose }) => {
  const { state, updateCostConfig } = useAppState();
  const config = state.costConfig;

  const [priceInput, setPriceInput] = useState(config.packPrice.toString());

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  const currencies: CurrencyCode[] = ['KRW', 'USD', 'JPY', 'EUR'];

  const handlePriceChange = (val: string) => {
    setPriceInput(val);
    const num = parseInt(val.replace(/[^0-9]/g, ''), 10);
    if (!isNaN(num) && num >= 0 && num <= 200000) {
      updateCostConfig({ packPrice: num });
    }
  };

  const adjustCigarettes = (delta: number) => {
    const next = Math.max(1, Math.min(60, config.cigarettesPerPack + delta));
    updateCostConfig({ cigarettesPerPack: next });
  };

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={[styles.container, { backgroundColor: colors.surface }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: colors.textPrimary }]}>비용 및 통화 설정</Text>
            <Pressable onPress={onClose} style={styles.closeIcon}>
              <Text style={{ color: colors.textSecondary, fontSize: 18, fontWeight: '700' }}>✕</Text>
            </Pressable>
          </View>

          <ScrollView style={styles.scrollBody} showsVerticalScrollIndicator={false}>
            {/* Currency Selector */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>사용 통화 선택</Text>
              <View style={styles.currencyRow}>
                {currencies.map((curr) => {
                  const isActive = config.currency === curr;
                  return (
                    <Pressable
                      key={curr}
                      style={[
                        styles.currencyChip,
                        {
                          backgroundColor: isActive ? colors.accent : colors.surfaceSecondary,
                        },
                      ]}
                      onPress={() => updateCostConfig({ currency: curr })}
                    >
                      <Text
                        style={[
                          styles.currencyText,
                          { color: isActive ? '#FFFFFF' : colors.textSecondary },
                        ]}
                      >
                        {curr}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
            </View>

            {/* Pack Price */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>담배 한 갑당 가격</Text>
              <Text style={[styles.sectionSub, { color: colors.textSecondary }]}>
                현재 구매하시는 담배 한 갑의 금액을 입력하세요
              </Text>

              <View style={[styles.inputBox, { backgroundColor: colors.surfaceSecondary, borderColor: colors.border }]}>
                <TextInput
                  style={[styles.input, { color: colors.textPrimary }]}
                  keyboardType="numeric"
                  value={priceInput}
                  onChangeText={handlePriceChange}
                  placeholder="예: 4500"
                  placeholderTextColor={colors.textMuted}
                />
                <Text style={[styles.currencySymbol, { color: colors.accent }]}>
                  {formatCurrency(config.packPrice, config.currency)}
                </Text>
              </View>
            </View>

            {/* Cigarettes per Pack */}
            <View style={[styles.section, { borderColor: colors.border }]}>
              <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>한 갑당 개비 수</Text>
              <Text style={[styles.sectionSub, { color: colors.textSecondary }]}>
                한 갑에 들어있는 담배 개비 수 (기본 20개비)
              </Text>

              <View style={styles.stepperRow}>
                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustCigarettes(-1)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>- 1개비</Text>
                </Pressable>

                <Text style={[styles.valueText, { color: colors.accent }]}>
                  {config.cigarettesPerPack} 개비
                </Text>

                <Pressable
                  style={[styles.stepperBtn, { backgroundColor: colors.surfaceSecondary }]}
                  onPress={() => adjustCigarettes(1)}
                >
                  <Text style={[styles.stepperText, { color: colors.textPrimary }]}>+ 1개비</Text>
                </Pressable>
              </View>
            </View>
          </ScrollView>

          <Pressable style={[styles.confirmBtn, { backgroundColor: colors.accent }]} onPress={onClose}>
            <Text style={styles.confirmBtnText}>저장 완료</Text>
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
    maxHeight: '75%',
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
  currencyRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 6,
  },
  currencyChip: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  currencyText: {
    fontSize: 13,
    fontWeight: '700',
  },
  inputBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    marginTop: 4,
  },
  input: {
    fontSize: 16,
    fontWeight: '700',
    flex: 1,
  },
  currencySymbol: {
    fontSize: 16,
    fontWeight: '800',
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
