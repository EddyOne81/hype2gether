// GENERATED FILE: do not edit by hand.
// Mirrored from packages/scoring/src/format.ts by `pnpm build:functions`. Edit the package, not this copy.

import { CENTIPOINTS_PER_POINT } from './constants.ts';

/** Convert integer centipoints to points for display (e.g. 8400 → 84, 666 → 6.66). */
export function centipointsToPoints(centipoints: number): number {
  return centipoints / CENTIPOINTS_PER_POINT;
}
