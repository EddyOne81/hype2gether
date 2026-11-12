import { describe, expect, it } from 'vitest';
import { RULE_VERSION, STARTING_RATING } from './constants';
import type { DailyInput } from './daily';
import { finalizeRound, type RoundMemberInput } from './round';
import { weeklyTotal } from './weekly';

const fullWeek = (steps: number): DailyInput[] =>
  Array.from({ length: 7 }, () => ({ steps, checkin: null }));

const member = (memberId: string, days: DailyInput[], ratingBefore = STARTING_RATING) => ({
  memberId,
  ratingBefore,
  days,
});

describe('RULE_VERSION', () => {
  it('is 1', () => {
    expect(RULE_VERSION).toBe(1);
  });
});

describe('weeklyTotal', () => {
  it('sums daily totals and counts days with data', () => {
    const day = (total: number, hasStepData = true) => ({
      stepCentipoints: total,
      photoCentipoints: 0,
      totalCentipoints: total,
      hasStepData,
    });
    expect(weeklyTotal([day(8400), day(10000), day(0, false)])).toEqual({
      totalCentipoints: 18400,
      daysWithStepData: 2,
    });
  });

  it('rejects more than 7 days', () => {
    const day = { stepCentipoints: 0, photoCentipoints: 0, totalCentipoints: 0, hasStepData: true };
    expect(() => weeklyTotal(Array.from({ length: 8 }, () => day))).toThrow(RangeError);
  });
});

describe('finalizeRound', () => {
  const fiveMembers: RoundMemberInput[] = [
    member('a', fullWeek(10_000)),
    member('b', fullWeek(8_000)),
    member('c', fullWeek(6_000)),
    member('d', fullWeek(4_000)),
    member('e', fullWeek(2_000)),
  ];

  it('final round: weekly totals, places and rating changes', () => {
    const { status, results } = finalizeRound({ members: fiveMembers, hasOpenDispute: false });
    expect(status).toBe('final');
    expect(results.map((r) => [r.memberId, r.totalCentipoints, r.place, r.ratingAfter])).toEqual([
      ['a', 56000, 1, 1020],
      ['b', 44800, 2, 1010],
      ['c', 33600, 3, 1000],
      ['d', 22400, 4, 990],
      ['e', 11200, 5, 980],
    ]);
  });

  it('missing step data → provisional, nobody’s rating changes, but places are still shown', () => {
    const members = [...fiveMembers];
    const partial = fullWeek(10_000);
    partial[3] = { steps: null, checkin: null };
    members[4] = member('e', partial);

    const { status, results } = finalizeRound({ members, hasOpenDispute: false });
    expect(status).toBe('provisional');
    expect(results.every((r) => r.ratingDelta === 0 && r.ratingAfter === r.ratingBefore)).toBe(
      true,
    );
    expect(results.find((r) => r.memberId === 'e')?.daysWithStepData).toBe(6);
  });

  it('fewer than 7 days submitted → provisional', () => {
    const members = fiveMembers.map((m) => ({ ...m, days: m.days.slice(0, 6) }));
    expect(finalizeRound({ members, hasOpenDispute: false }).status).toBe('provisional');
  });

  it('open dispute → provisional', () => {
    const { status, results } = finalizeRound({ members: fiveMembers, hasOpenDispute: true });
    expect(status).toBe('provisional');
    expect(results.every((r) => r.ratingDelta === 0)).toBe(true);
  });

  it('applies the rating floor', () => {
    const members = [...fiveMembers];
    members[4] = member('e', fullWeek(0), 7);
    const last = finalizeRound({ members, hasOpenDispute: false }).results.at(-1);
    expect(last).toMatchObject({ memberId: 'e', ratingDelta: -20, ratingAfter: 0 });
  });

  it('is deterministic and independent of member order (safe to re-run)', () => {
    const once = finalizeRound({ members: fiveMembers, hasOpenDispute: false });
    const again = finalizeRound({ members: [...fiveMembers].reverse(), hasOpenDispute: false });
    expect(again).toEqual(once);
  });

  it('counts votes only from locked members, excluding self-votes and duplicates', () => {
    const days = fullWeek(10_000);
    days[0] = { steps: 10_000, checkin: { authorId: 'a', voterIds: ['a', 'b', 'b', 'stranger'] } };
    const members = [
      member('a', days),
      member('b', fullWeek(10_000)),
      member('c', fullWeek(10_000)),
    ];
    const a = finalizeRound({ members, hasOpenDispute: false }).results.find(
      (r) => r.memberId === 'a',
    );
    expect(a?.daily[0]?.photoCentipoints).toBe(2000); // N = 3: q = 1, b's single vote counts
    expect(a?.totalCentipoints).toBe(7 * 8000 + 2000);
  });

  it.each([2, 9])('rejects a locked list of %i members', (n) => {
    const members = Array.from({ length: n }, (_, i) => member(`m${i}`, fullWeek(1)));
    expect(() => finalizeRound({ members, hasOpenDispute: false })).toThrow(RangeError);
  });

  it('rejects duplicate members and more than 7 days', () => {
    expect(() =>
      finalizeRound({
        members: [member('a', fullWeek(1)), member('a', fullWeek(1)), member('b', fullWeek(1))],
        hasOpenDispute: false,
      }),
    ).toThrow();
    expect(() =>
      finalizeRound({
        members: [
          member('a', [...fullWeek(1), { steps: 1, checkin: null }]),
          member('b', []),
          member('c', []),
        ],
        hasOpenDispute: false,
      }),
    ).toThrow(RangeError);
  });
});
