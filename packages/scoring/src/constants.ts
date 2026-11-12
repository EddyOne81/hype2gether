/**
 * Scoring rule constants (PRODUCT_BRIEF.md, "Scoring rules — v1").
 * Any change to a value or formula in this package must bump RULE_VERSION.
 */
export const RULE_VERSION = 1;

export const ROUND_DAYS = 7;
export const MIN_PARTY_SIZE = 3;
export const MAX_PARTY_SIZE = 8;

/**
 * Points are computed as integers in hundredths of a point ("centipoints") and rounded down,
 * so totals are exact, ties compare exactly, and nobody is ever awarded more than earned.
 */
export const CENTIPOINTS_PER_POINT = 100;
export const STEP_CAP = 10_000;
export const MAX_STEP_CENTIPOINTS = 80 * CENTIPOINTS_PER_POINT;
export const MAX_PHOTO_CENTIPOINTS = 20 * CENTIPOINTS_PER_POINT;
export const MAX_DAILY_CENTIPOINTS = MAX_STEP_CENTIPOINTS + MAX_PHOTO_CENTIPOINTS;

export const STARTING_RATING = 1000;
export const RATING_FLOOR = 0;
export const MAX_RATING_DELTA = 20;
