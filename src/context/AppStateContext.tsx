// src/context/AppStateContext.tsx
import React, { createContext, useContext, useEffect, useState } from 'react';
import { AppState, SmokingLog, AlertConfig, CostConfig, DisplaySettings } from '../domain/types';
import { StorageService } from '../services/storage';
import { HapticService } from '../services/notification';

interface AppContextType {
  state: AppState;
  isLoading: boolean;
  addSmokingLog: (note?: string) => Promise<void>;
  undoLastLog: () => Promise<void>;
  deleteSmokingLog: (id: string) => Promise<void>;
  updateAlertConfig: (config: Partial<AlertConfig>) => Promise<void>;
  updateCostConfig: (config: Partial<CostConfig>) => Promise<void>;
  updateDisplaySettings: (settings: Partial<DisplaySettings>) => Promise<void>;
  completeOnboarding: () => Promise<void>;
  resetAllData: () => Promise<void>;
}

const AppStateContext = createContext<AppContextType | undefined>(undefined);

export const AppStateProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<AppState>({
    hasCompletedOnboarding: false,
    logs: [],
    lastDeletedLog: null,
    alertConfig: {
      enabled: true,
      intervalMinutes: 45,
      preAlertMinutes: 5,
      allowedStartMinutes: 480,
      allowedEndMinutes: 1440,
      activeWeekdays: [1, 2, 3, 4, 5],
      soundEnabled: true,
      vibrationEnabled: true,
    },
    costConfig: {
      packPrice: 4500,
      cigarettesPerPack: 20,
      currency: 'KRW',
    },
    displaySettings: {
      isDarkMode: false,
      is24HourFormat: false,
      homeTimerReference: 'last_smoking',
    },
  });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    StorageService.loadAppState().then((loaded) => {
      setState(loaded);
      setIsLoading(false);
    });
  }, []);

  const addSmokingLog = async (note?: string) => {
    HapticService.heavyImpact();
    const newLog: SmokingLog = {
      id: Date.now().toString(),
      timestamp: Date.now(),
      note,
    };
    const updatedLogs = [newLog, ...state.logs];
    setState((prev) => ({
      ...prev,
      logs: updatedLogs,
      lastDeletedLog: null,
    }));
    await StorageService.saveLogs(updatedLogs);
  };

  const undoLastLog = async () => {
    if (state.logs.length === 0) return;
    HapticService.mediumImpact();
    const deletedLog = state.logs[0];
    const updatedLogs = state.logs.slice(1);
    setState((prev) => ({
      ...prev,
      logs: updatedLogs,
      lastDeletedLog: deletedLog,
    }));
    await StorageService.saveLogs(updatedLogs);
  };

  const deleteSmokingLog = async (id: string) => {
    HapticService.lightImpact();
    const target = state.logs.find((l) => l.id === id);
    const updatedLogs = state.logs.filter((l) => l.id !== id);
    setState((prev) => ({
      ...prev,
      logs: updatedLogs,
      lastDeletedLog: target || null,
    }));
    await StorageService.saveLogs(updatedLogs);
  };

  const updateAlertConfig = async (partial: Partial<AlertConfig>) => {
    HapticService.lightImpact();
    const updated = { ...state.alertConfig, ...partial };
    setState((prev) => ({ ...prev, alertConfig: updated }));
    await StorageService.saveAlertConfig(updated);
  };

  const updateCostConfig = async (partial: Partial<CostConfig>) => {
    HapticService.lightImpact();
    const updated = { ...state.costConfig, ...partial };
    setState((prev) => ({ ...prev, costConfig: updated }));
    await StorageService.saveCostConfig(updated);
  };

  const updateDisplaySettings = async (partial: Partial<DisplaySettings>) => {
    HapticService.lightImpact();
    const updated = { ...state.displaySettings, ...partial };
    setState((prev) => ({ ...prev, displaySettings: updated }));
    await StorageService.saveDisplaySettings(updated);
  };

  const completeOnboarding = async () => {
    HapticService.successNotification();
    setState((prev) => ({ ...prev, hasCompletedOnboarding: true }));
    await StorageService.setHasCompletedOnboarding(true);
  };

  const resetAllData = async () => {
    HapticService.warningNotification();
    await StorageService.clearAllData();
    const fresh = await StorageService.loadAppState();
    setState(fresh);
  };

  return (
    <AppStateContext.Provider
      value={{
        state,
        isLoading,
        addSmokingLog,
        undoLastLog,
        deleteSmokingLog,
        updateAlertConfig,
        updateCostConfig,
        updateDisplaySettings,
        completeOnboarding,
        resetAllData,
      }}
    >
      {children}
    </AppStateContext.Provider>
  );
};

export const useAppState = () => {
  const context = useContext(AppStateContext);
  if (!context) throw new Error('useAppState must be used within AppStateProvider');
  return context;
};
