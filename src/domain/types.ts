// src/domain/types.ts

export type CurrencyCode = 'KRW' | 'USD' | 'JPY' | 'EUR';

export interface SmokingLog {
  id: string;
  timestamp: number; // unix milliseconds
  note?: string;
}

export interface AlertConfig {
  enabled: boolean;
  intervalMinutes: number; // 30 ~ 240 mins (default: 45)
  preAlertMinutes: number;  // 0 ~ 15 mins (default: 5)
  allowedStartMinutes: number; // 0 ~ 1440 (default: 480 = 08:00)
  allowedEndMinutes: number;   // 0 ~ 1440 (default: 1440 = 24:00)
  activeWeekdays: number[];    // 1=Mon, 7=Sun (default: [1,2,3,4,5])
  soundEnabled: boolean;
  vibrationEnabled: boolean;
}

export interface CostConfig {
  packPrice: number; // default: 4500 (KRW)
  cigarettesPerPack: number; // default: 20
  currency: CurrencyCode;
}

export type HomeTimerReference = 'last_smoking' | 'today_start';

export interface DisplaySettings {
  isDarkMode: boolean;
  is24HourFormat: boolean;
  homeTimerReference: HomeTimerReference;
}

export interface AppState {
  hasCompletedOnboarding: boolean;
  logs: SmokingLog[];
  lastDeletedLog: SmokingLog | null; // For Undo
  alertConfig: AlertConfig;
  costConfig: CostConfig;
  displaySettings: DisplaySettings;
}
