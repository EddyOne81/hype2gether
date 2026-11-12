import { MAX_RATING_DELTA, RATING_FLOOR } from './constants';
import type { Placement } from './ranking';
import { assertNonNegativeInteger, assertPartySize } from './validation';

/** Round half away from zero so mirrored placements get mirrored deltas. */
function roundHalfAwayFromZero(x: number): number {
  return Math.sign(x) * Math.round(Math.abs(x));
}

/** ΔR = round(20 × (countLower − countHigher) / (N − 1)), clamped to [−20, +20]. */
export function ratingDelta(
  placement: Pick<Placement, 'countLower' | 'countHigher'>,
  memberCount: number,
): number {
  assertPartySize(memberCount);
  const raw =
    (MAX_RATING_DELTA * (placement.countLower - placement.countHigher)) / (memberCount - 1);
  const clamped = Math.max(
    -MAX_RATING_DELTA,
    Math.min(MAX_RATING_DELTA, roundHalfAwayFromZero(raw)),
  );
  return clamped === 0 ? 0 : clamped; // normalise -0
}

/** New rating after a finalized round, never below the floor. */
export function applyRatingDelta(ratingBefore: number, delta: number): number {
  assertNonNegativeInteger(ratingBefore, 'ratingBefore');
  if (!Number.isInteger(delta) || Math.abs(delta) > MAX_RATING_DELTA) {
    throw new RangeError(`delta must be an integer within ±${MAX_RATING_DELTA}, got ${delta}`);
  }
  return Math.max(RATING_FLOOR, ratingBefore + delta);
}
