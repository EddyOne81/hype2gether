import { CENTIPOINTS_PER_POINT } from './constants';

/** Convert integer centipoints to points for display (e.g. 8400 → 84, 666 → 6.66). */
export function centipointsToPoints(centipoints: number): number {
  return centipoints / CENTIPOINTS_PER_POINT;
}
