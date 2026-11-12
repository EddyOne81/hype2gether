/**
 * Scoring rule constants (PRODUCT_BRIEF.md, "Scoring rules — v2").
 * Any change to a value or formula in this package must bump RULE_VERSION.
 */
export const RULE_VERSION = 2;

export const ROUND_DAYS = 7;
export const MIN_PARTY_SIZE = 3;
export const MAX_PARTY_SIZE = 8;

/**
 * Points are computed as integers in hundredths of a point ("centipoints") and rounded down,
 * so totals are exact, ties compare exactly, and nobody is ever awarded more than earned.
 */
export const CENTIPOINTS_PER_POINT = 100;
export const STEP_CAP = 10_000;
/** 30 km of valid riding counts like STEP_CAP steps. */
export const RIDE_METRES_CAP = 30_000;
export const MAX_MOVEMENT_CENTIPOINTS = 80 * CENTIPOINTS_PER_POINT;
export const MAX_PHOTO_CENTIPOINTS = 20 * CENTIPOINTS_PER_POINT;
export const MAX_DAILY_CENTIPOINTS = MAX_MOVEMENT_CENTIPOINTS + MAX_PHOTO_CENTIPOINTS;

/** A ride counts only if it lasts at least this long and averages at most this speed. */
export const MIN_RIDE_SECONDS = 10 * 60;
export const MAX_RIDE_SPEED_KMH = 40;

export const STARTING_RATING = 1000;
export const RATING_FLOOR = 0;
export const MAX_RATING_DELTA = 20;
