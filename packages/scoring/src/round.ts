import { ROUND_DAYS } from './constants';
import { scoreDay, type DailyInput, type DailyScore } from './daily';
import { rankMembers } from './ranking';
import { applyRatingDelta, ratingDelta } from './rating';
import { assertPartySize, assertUniqueIds } from './validation';
import { weeklyTotal } from './weekly';

export type RoundStatus = 'final' | 'provisional';

export interface RoundMemberInput {
  memberId: string;
  ratingBefore: number;
  /** One entry per round day, in order. Fewer than 7 entries means the remaining days are missing. */
  days: readonly DailyInput[];
}

export interface RoundInput {
  /** The locked member list (N members). */
  members: readonly RoundMemberInput[];
  hasOpenDispute: boolean;
}

export interface MemberResult {
  memberId: string;
  daily: DailyScore[];
  totalCentipoints: number;
  daysWithStepData: number;
  place: number;
  /** 0 when the round is provisional. */
  ratingDelta: number;
  ratingBefore: number;
  ratingAfter: number;
}

export interface RoundResult {
  status: RoundStatus;
  results: MemberResult[];
}

/**
 * Ratings change only if every member has step data for all 7 days and no dispute is open;
 * otherwise the round is provisional and nobody's rating changes. Pure and deterministic,
 * so finalization is safe to re-run.
 */
export function finalizeRound(input: RoundInput): RoundResult {
  const memberIds = input.members.map((m) => m.memberId);
  assertPartySize(memberIds.length);
  assertUniqueIds(memberIds, 'members');

  const scored = input.members.map((m) => {
    if (m.days.length > ROUND_DAYS) {
      throw new RangeError(`A round has at most ${ROUND_DAYS} days, got ${m.days.length}`);
    }
    const daily = m.days.map((d) => scoreDay(m.memberId, d, memberIds));
    return { member: m, daily, weekly: weeklyTotal(daily) };
  });

  const eligible =
    !input.hasOpenDispute && scored.every((s) => s.weekly.daysWithStepData === ROUND_DAYS);

  const placements = new Map(
    rankMembers(
      scored.map((s) => ({
        memberId: s.member.memberId,
        totalCentipoints: s.weekly.totalCentipoints,
      })),
    ).map((p) => [p.memberId, p]),
  );

  const results = scored.map(({ member, daily, weekly }): MemberResult => {
    const placement = placements.get(member.memberId);
    if (!placement) throw new Error(`Missing placement for ${member.memberId}`);
    const delta = eligible ? ratingDelta(placement, memberIds.length) : 0;
    return {
      memberId: member.memberId,
      daily,
      totalCentipoints: weekly.totalCentipoints,
      daysWithStepData: weekly.daysWithStepData,
      place: placement.place,
      ratingDelta: delta,
      ratingBefore: member.ratingBefore,
      ratingAfter: applyRatingDelta(member.ratingBefore, delta),
    };
  });

  results.sort((a, b) => a.place - b.place || a.memberId.localeCompare(b.memberId));
  return { status: eligible ? 'final' : 'provisional', results };
}
