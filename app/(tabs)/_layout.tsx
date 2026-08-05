// app/(tabs)/_layout.tsx
import React from 'react';
import { Tabs } from 'expo-router';
import { Text } from 'react-native';
import { useAppState } from '../../src/context/AppStateContext';
import { ThemeColors } from '../../src/constants/theme';

export default function TabsLayout() {
  const { state } = useAppState();
  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: colors.surface,
          borderTopColor: colors.border,
          height: 64,
          paddingBottom: 8,
          paddingTop: 8,
        },
        tabBarActiveTintColor: colors.accent,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '700',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: '타이머',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 18, color }}>⏱️</Text>,
        }}
      />
      <Tabs.Screen
        name="record"
        options={{
          title: '통계기록',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 18, color }}>📊</Text>,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: '설정',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 18, color }}>⚙️</Text>,
        }}
      />
    </Tabs>
  );
}
