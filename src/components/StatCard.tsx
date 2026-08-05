// src/components/StatCard.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';

interface StatCardProps {
  label: string;
  value: string;
  subValue?: string;
  icon?: string;
}

export const StatCard: React.FC<StatCardProps> = ({ label, value, subValue, icon }) => {
  const { state } = useAppState();
  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  return (
    <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
      <View style={styles.header}>
        <Text style={[styles.label, { color: colors.textSecondary }]}>{label}</Text>
        {icon && <Text style={styles.icon}>{icon}</Text>}
      </View>

      <Text style={[styles.value, { color: colors.textPrimary }]}>{value}</Text>
      {subValue && <Text style={[styles.subValue, { color: colors.accent }]}>{subValue}</Text>}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    flex: 1,
    minWidth: '45%',
    padding: 14,
    borderRadius: 16,
    borderWidth: 1,
    marginBottom: 10,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
  },
  icon: {
    fontSize: 14,
  },
  value: {
    fontSize: 20,
    fontWeight: '800',
  },
  subValue: {
    fontSize: 11,
    fontWeight: '700',
    marginTop: 2,
  },
});
