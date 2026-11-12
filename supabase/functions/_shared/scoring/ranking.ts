// GENERATED FILE: do not edit by hand.
// Mirrored from packages/scoring/src/ranking.ts by `pnpm build:functions`. Edit the package, not this copy.

import { assertNonNegativeInteger, assertUniqueIds } from './validation.ts';

export interface RankInput {
  memberId: string;
  totalCentipoints: number;
}

export interface Placement {
  memberId: string;
  /** Competition ranking: equal totals share a place and the next place is skipped (1, 1, 3). */
  place: number;
  countHigher: number;
  countLower: number;
}

export function rankMembers(entries: readonly RankInput[]): Placement[] {
  assertUniqueIds(
    entries.map((e) => e.memberId),
    'entries',
  );
  for (const e of entries) assertNonNegativeInteger(e.totalCentipoints, 'totalCentipoints');

  return entries
    .map((e) => {
      const countHigher = entries.filter((o) => o.totalCentipoints > e.totalCentipoints).length;
      const countLower = entries.filter((o) => o.totalCentipoints < e.totalCentipoints).length;
      return { memberId: e.memberId, place: countHigher + 1, countHigher, countLower };
    })
    .sort((a, b) => a.place - b.place || a.memberId.localeCompare(b.memberId));
}
