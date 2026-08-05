// src/services/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppState, SmokingLog, AlertConfig, CostConfig, DisplaySettings } from '../domain/types';
import { AppDefaults } from '../domain/defaults';

const STORAGE_KEYS = {
  HAS_COMPLETED_ONBOARDING: '@smoke_timer/has_completed_onboarding',
  LOGS: '@smoke_timer/smoking_logs',
  ALERT_CONFIG: '@smoke_timer/alert_config',
  COST_CONFIG: '@smoke_timer/cost_config',
  DISPLAY_SETTINGS: '@smoke_timer/display_settings',
};

// In-memory fallback if AsyncStorage is unavailable or native module is null
const inMemoryStore: Record<string, string> = {};

const safeGetItem = async (key: string): Promise<string | null> => {
  try {
    if (AsyncStorage && typeof AsyncStorage.getItem === 'function') {
      return await AsyncStorage.getItem(key);
    }
  } catch (e) {
    console.warn(`[StorageService] AsyncStorage.getItem failed for ${key}, using fallback.`, e);
  }
  return inMemoryStore[key] || null;
};

const safeSetItem = async (key: string, value: string): Promise<void> => {
  try {
    if (AsyncStorage && typeof AsyncStorage.setItem === 'function') {
      await AsyncStorage.setItem(key, value);
      return;
    }
  } catch (e) {
    console.warn(`[StorageService] AsyncStorage.setItem failed for ${key}, using fallback.`, e);
  }
  inMemoryStore[key] = value;
};

const safeRemoveItem = async (key: string): Promise<void> => {
  try {
    if (AsyncStorage && typeof AsyncStorage.removeItem === 'function') {
      await AsyncStorage.removeItem(key);
      return;
    }
  } catch (e) {
    console.warn(`[StorageService] AsyncStorage.removeItem failed for ${key}, using fallback.`, e);
  }
  delete inMemoryStore[key];
};

export const StorageService = {
  async loadAppState(): Promise<AppState> {
    try {
      const [onboardingRaw, logsRaw, alertRaw, costRaw, displayRaw] = await Promise.all([
        safeGetItem(STORAGE_KEYS.HAS_COMPLETED_ONBOARDING),
        safeGetItem(STORAGE_KEYS.LOGS),
        safeGetItem(STORAGE_KEYS.ALERT_CONFIG),
        safeGetItem(STORAGE_KEYS.COST_CONFIG),
        safeGetItem(STORAGE_KEYS.DISPLAY_SETTINGS),
      ]);

      const hasCompletedOnboarding = onboardingRaw ? JSON.parse(onboardingRaw) : false;
      const logs: SmokingLog[] = logsRaw ? JSON.parse(logsRaw) : [];
      const alertConfig: AlertConfig = alertRaw ? JSON.parse(alertRaw) : AppDefaults.alertConfig;
      const costConfig: CostConfig = costRaw ? JSON.parse(costRaw) : AppDefaults.costConfig;
      const displaySettings: DisplaySettings = displayRaw ? JSON.parse(displayRaw) : AppDefaults.displaySettings;

      return {
        hasCompletedOnboarding,
        logs,
        lastDeletedLog: null,
        alertConfig,
        costConfig,
        displaySettings,
      };
    } catch (e) {
      console.error('Failed to load app state from storage:', e);
      return {
        hasCompletedOnboarding: false,
        logs: [],
        lastDeletedLog: null,
        alertConfig: AppDefaults.alertConfig,
        costConfig: AppDefaults.costConfig,
        displaySettings: AppDefaults.displaySettings,
      };
    }
  },

  async setHasCompletedOnboarding(completed: boolean): Promise<void> {
    await safeSetItem(STORAGE_KEYS.HAS_COMPLETED_ONBOARDING, JSON.stringify(completed));
  },

  async saveLogs(logs: SmokingLog[]): Promise<void> {
    await safeSetItem(STORAGE_KEYS.LOGS, JSON.stringify(logs));
  },

  async saveAlertConfig(config: AlertConfig): Promise<void> {
    await safeSetItem(STORAGE_KEYS.ALERT_CONFIG, JSON.stringify(config));
  },

  async saveCostConfig(config: CostConfig): Promise<void> {
    await safeSetItem(STORAGE_KEYS.COST_CONFIG, JSON.stringify(config));
  },

  async saveDisplaySettings(settings: DisplaySettings): Promise<void> {
    await safeSetItem(STORAGE_KEYS.DISPLAY_SETTINGS, JSON.stringify(settings));
  },

  async clearAllData(): Promise<void> {
    await Promise.all([
      safeRemoveItem(STORAGE_KEYS.HAS_COMPLETED_ONBOARDING),
      safeRemoveItem(STORAGE_KEYS.LOGS),
      safeRemoveItem(STORAGE_KEYS.ALERT_CONFIG),
      safeRemoveItem(STORAGE_KEYS.COST_CONFIG),
      safeRemoveItem(STORAGE_KEYS.DISPLAY_SETTINGS),
    ]);
  },
};
