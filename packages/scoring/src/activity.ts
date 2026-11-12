import { MAX_RIDE_SPEED_KMH, MIN_RIDE_SECONDS } from './constants';
import { assertNonNegativeInteger } from './validation';

export type Sport = 'run' | 'ride';

/** A run or ride summary as read from Apple Health. Routes never reach the scoring engine. */
export interface ActivityInput {
  id: string;
  sport: Sport;
  /** Start and end as Unix epoch milliseconds. */
  startedAt: number;
  endedAt: number;
  /** Recorded (moving) duration in whole seconds. */
  durationSeconds: number;
  distanceMetres: number;
  /** True when the workout was typed in by hand instead of recorded by a device or app. */
  userEntered: boolean;
}

export type ActivityRejection = 'user_entered' | 'too_short' | 'too_fast';

function assertActivity(activity: ActivityInput): void {
  assertNonNegativeInteger(activity.startedAt, 'startedAt');
  assertNonNegativeInteger(activity.endedAt, 'endedAt');
  assertNonNegativeInteger(activity.durationSeconds, 'durationSeconds');
  assertNonNegativeInteger(activity.distanceMetres, 'distanceMetres');
  if (activity.endedAt < activity.startedAt) {
    throw new RangeError(`Activity ${activity.id} ends before it starts`);
  }
}

/**
 * Why an activity would not count for points, or null when it would. Applies the ride rules
 * (PRODUCT_BRIEF.md, "Activity rules"); runs get the same checks so cards can label them.
 */
export function activityRejection(activity: ActivityInput): ActivityRejection | null {
  assertActivity(activity);
  if (activity.userEntered) return 'user_entered';
  if (activity.durationSeconds < MIN_RIDE_SECONDS) return 'too_short';
  // distance / duration > 40 km/h, compared in integers: metres × 3600 > 40000 × seconds.
  if (activity.distanceMetres * 3600 > MAX_RIDE_SPEED_KMH * 1000 * activity.durationSeconds) {
    return 'too_fast';
  }
  return null;
}

export function isValidRide(activity: ActivityInput): boolean {
  return activity.sport === 'ride' && activityRejection(activity) === null;
}

/**
 * Ride distance that counts for one day: valid rides only, and within each group of rides that
 * overlap in time (the same ride recorded by two apps), only the longest distance counts.
 * Runs never count here: they already score through steps.
 */
export function countedRideMetres(activities: readonly ActivityInput[]): number {
  const rides = activities
    .filter(isValidRide)
    .sort((a, b) => a.startedAt - b.startedAt || a.endedAt - b.endedAt);

  let total = 0;
  let groupEnd = Number.NEGATIVE_INFINITY;
  let groupBest = 0;
  for (const ride of rides) {
    if (ride.startedAt < groupEnd) {
      groupEnd = Math.max(groupEnd, ride.endedAt);
      groupBest = Math.max(groupBest, ride.distanceMetres);
    } else {
      total += groupBest;
      groupEnd = ride.endedAt;
      groupBest = ride.distanceMetres;
    }
  }
  return total + groupBest;
}
