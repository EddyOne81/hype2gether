// GENERATED FILE: do not edit by hand.
// Mirrored from packages/scoring/src/tier.ts by `pnpm build:functions`. Edit the package, not this copy.

import { assertNonNegativeInteger } from './validation.ts';

export type Tier = 'bronze' | 'silver' | 'gold' | 'platinum';

/** Bronze < 1100, Silver 1100–1199, Gold 1200–1349, Platinum ≥ 1350. */
export function tierFor(rating: number): Tier {
  assertNonNegativeInteger(rating, 'rating');
  if (rating >= 1350) return 'platinum';
  if (rating >= 1200) return 'gold';
  if (rating >= 1100) return 'silver';
  return 'bronze';
}
