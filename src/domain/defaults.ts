// src/domain/defaults.ts
import { AlertConfig, CostConfig, DisplaySettings } from './types';

export const AppDefaults = {
  // Alert Defaults
  alertConfig: {
    enabled: true,
    intervalMinutes: 45,      // 45분 기본
    preAlertMinutes: 5,        // 정각 5분 전 미리 알림
    allowedStartMinutes: 480,  // 08:00
    allowedEndMinutes: 1440,   // 24:00
    activeWeekdays: [1, 2, 3, 4, 5], // 월~금
    soundEnabled: true,
    vibrationEnabled: true,
  } as AlertConfig,

  // Cost Defaults
  costConfig: {
    packPrice: 4500, // 4,500원
    cigarettesPerPack: 20, // 20개비
    currency: 'KRW',
  } as CostConfig,

  // Display Defaults
  displaySettings: {
    isDarkMode: false,
    is24HourFormat: false,
    homeTimerReference: 'last_smoking',
  } as DisplaySettings,

  // Range Constraints
  minIntervalMinutes: 30,
  maxIntervalMinutes: 240,
  intervalStep: 5,

  minPreAlertMinutes: 0,
  maxPreAlertMinutes: 15,
  preAlertStep: 1,

  minPackPrice: 0,
  maxPackPrice: 200000,

  minCigarettesPerPack: 1,
  maxCigarettesPerPack: 60,
};

export const CurrencySymbols: Record<string, string> = {
  KRW: '₩',
  USD: '$',
  JPY: '¥',
  EUR: '€',
};

export function formatCurrency(amount: number, currency: string): string {
  const symbol = CurrencySymbols[currency] || '₩';
  if (currency === 'KRW' || currency === 'JPY') {
    return `${symbol}${Math.round(amount).toLocaleString('ko-KR')}`;
  }
  return `${symbol}${amount.toFixed(2)}`;
}
