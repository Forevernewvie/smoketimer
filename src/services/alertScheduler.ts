// src/services/alertScheduler.ts
import { AlertConfig } from '../domain/types';

export interface NextAlertResult {
  nextAlertTime: Date | null;
  intervalFormatted: string;
  preAlertFormatted: string;
}

export function calculateNextAlert(
  lastSmokingAt: number | null,
  config: AlertConfig,
  now: Date = new Date()
): NextAlertResult {
  if (!config.enabled || !lastSmokingAt) {
    return {
      nextAlertTime: null,
      intervalFormatted: formatMinutes(config.intervalMinutes),
      preAlertFormatted: formatMinutes(config.preAlertMinutes),
    };
  }

  const intervalMs = config.intervalMinutes * 60 * 1000;
  const preAlertMs = config.preAlertMinutes * 60 * 1000;

  // 1. Initial Candidate Time
  let candidateTime = lastSmokingAt + intervalMs - preAlertMs;
  const nowMs = now.getTime();

  // If candidate is in the past, add interval repeatedly
  if (candidateTime <= nowMs) {
    const diff = nowMs - candidateTime;
    const intervalsToAdd = Math.floor(diff / intervalMs) + 1;
    candidateTime += intervalsToAdd * intervalMs;
  }

  let candidateDate = new Date(candidateTime);

  // 2. Alignment Logic (Allowed Time Window & Active Weekdays)
  let loopCount = 0;
  const maxLoops = 20000; // Protection against infinite loop

  while (loopCount < maxLoops) {
    loopCount++;

    // Weekday alignment (1 = Mon, 7 = Sun in JS/ISO)
    // JS getDay(): 0 = Sun, 1 = Mon, ..., 6 = Sat -> convert to 1=Mon..7=Sun
    const jsDay = candidateDate.getDay();
    const isoWeekday = jsDay === 0 ? 7 : jsDay;

    if (!config.activeWeekdays.includes(isoWeekday)) {
      // Advance to next day at allowedStart
      candidateDate = getNextDayAtMinutes(candidateDate, config.allowedStartMinutes);
      continue;
    }

    // Time of day alignment
    const currentMinutesFromMidnight = candidateDate.getHours() * 60 + candidateDate.getMinutes();

    if (currentMinutesFromMidnight < config.allowedStartMinutes) {
      // Move to allowedStart on same day
      candidateDate.setHours(Math.floor(config.allowedStartMinutes / 60), config.allowedStartMinutes % 60, 0, 0);
      break;
    } else if (currentMinutesFromMidnight > config.allowedEndMinutes) {
      // Move to allowedStart on next day
      candidateDate = getNextDayAtMinutes(candidateDate, config.allowedStartMinutes);
      continue;
    }

    // Candidate fits within allowed window and active weekday!
    break;
  }

  return {
    nextAlertTime: candidateDate,
    intervalFormatted: formatMinutes(config.intervalMinutes),
    preAlertFormatted: formatMinutes(config.preAlertMinutes),
  };
}

function getNextDayAtMinutes(date: Date, startMinutes: number): Date {
  const next = new Date(date);
  next.setDate(next.getDate() + 1);
  next.setHours(Math.floor(startMinutes / 60), startMinutes % 60, 0, 0);
  return next;
}

export function formatMinutes(mins: number): string {
  if (mins < 60) return `${mins}분`;
  const hrs = Math.floor(mins / 60);
  const rem = mins % 60;
  if (rem === 0) return `${hrs}시간`;
  return `${hrs}시간 ${rem}분`;
}

export function formatMinutesToTimeString(minsFromMidnight: number): string {
  const hrs = Math.floor(minsFromMidnight / 60);
  const mins = minsFromMidnight % 60;
  const padH = String(hrs).padStart(2, '0');
  const padM = String(mins).padStart(2, '0');
  return `${padH}:${padM}`;
}
