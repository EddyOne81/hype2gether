import { ROUND_DAYS } from './constants';
import type { DailyScore } from './daily';

export interface WeeklyScore {
  totalCentipoints: number;
  daysWithStepData: number;
}

/** Weekly points = sum of the round's daily totals (at most 7 days). */
export function weeklyTotal(days: readonly DailyScore[]): WeeklyScore {
  if (days.length > ROUND_DAYS) {
    throw new RangeError(`A round has at most ${ROUND_DAYS} days, got ${days.length}`);
  }
  return {
    totalCentipoints: days.reduce((sum, d) => sum + d.totalCentipoints, 0),
    daysWithStepData: days.filter((d) => d.hasStepData).length,
  };
}
