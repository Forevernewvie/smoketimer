// src/services/notification.ts
import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

export const HapticService = {
  lightImpact() {
    if (Platform.OS === 'web') return;
    try {
      if (Haptics && typeof Haptics.impactAsync === 'function') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      }
    } catch (e) {
      // Ignore native module null error
    }
  },

  mediumImpact() {
    if (Platform.OS === 'web') return;
    try {
      if (Haptics && typeof Haptics.impactAsync === 'function') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
    } catch (e) {
      // Ignore native module null error
    }
  },

  heavyImpact() {
    if (Platform.OS === 'web') return;
    try {
      if (Haptics && typeof Haptics.impactAsync === 'function') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
      }
    } catch (e) {
      // Ignore native module null error
    }
  },

  successNotification() {
    if (Platform.OS === 'web') return;
    try {
      if (Haptics && typeof Haptics.notificationAsync === 'function') {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    } catch (e) {
      // Ignore native module null error
    }
  },

  warningNotification() {
    if (Platform.OS === 'web') return;
    try {
      if (Haptics && typeof Haptics.notificationAsync === 'function') {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      }
    } catch (e) {
      // Ignore native module null error
    }
  },
};
