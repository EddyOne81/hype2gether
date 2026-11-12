import { describe, expect, it } from 'vitest';
import {
  countValidVotes,
  photoCentipoints,
  requiredVotes,
  scoreDay,
  movementCentipoints,
} from './daily';
import { centipointsToPoints } from './format';

const members = (n: number) => Array.from({ length: n }, (_, i) => `m${i + 1}`);

describe('required test cases (PRODUCT_BRIEF.md)', () => {
  it('8,000 steps + fully verified photo → 64 + 20 = 84 points', () => {
    const ids = members(5);
    const score = scoreDay(
      'm1',
      { steps: 8000, checkin: { authorId: 'm1', voterIds: ['m2', 'm3'] }, activities: [] },
      ids,
    );
    expect(centipointsToPoints(score.movementCentipoints)).toBe(64);
    expect(centipointsToPoints(score.photoCentipoints)).toBe(20);
    expect(centipointsToPoints(score.totalCentipoints)).toBe(84);
  });

  it('N = 5 → q = 2; 1 vote → 10 photo points; 2 votes → 20', () => {
    expect(requiredVotes(5)).toBe(2);
    expect(centipointsToPoints(photoCentipoints(1, 5))).toBe(10);
    expect(centipointsToPoints(photoCentipoints(2, 5))).toBe(20);
  });

  it('25,000 steps → 80 movement points (real steps are not altered)', () => {
    const steps = 25_000;
    expect(centipointsToPoints(movementCentipoints(steps, 0))).toBe(80);
    expect(steps).toBe(25_000);
  });
});

describe('requiredVotes', () => {
  it.each([
    [3, 1],
    [4, 2],
    [5, 2],
    [6, 3],
    [7, 3],
    [8, 4],
  ])('N = %i → q = %i', (n, q) => {
    expect(requiredVotes(n)).toBe(q);
  });

  it.each([2, 9, 0, -1, 4.5, Number.NaN])('rejects party size %s', (n) => {
    expect(() => requiredVotes(n)).toThrow(RangeError);
  });
});

describe('movementCentipoints (steps only, same as rule v1)', () => {
  it.each([
    [0, 0],
    [1, 0], // 0.008 points rounds down
    [1234, 987], // 9.872 → 9.87
    [5000, 4000],
    [9999, 7999],
    [10_000, 8000],
    [10_001, 8000],
    [1_000_000, 8000],
  ])('%i steps → %i centipoints', (steps, expected) => {
    expect(movementCentipoints(steps, 0)).toBe(expected);
  });

  it.each([-1, 1.5, Number.NaN, Number.POSITIVE_INFINITY])('rejects invalid steps %s', (steps) => {
    expect(() => movementCentipoints(steps, 0)).toThrow(RangeError);
  });
});

describe('photoCentipoints', () => {
  it.each([
    // [votes, N, centipoints]
    [0, 3, 0],
    [1, 3, 2000], // N = 3: one vote is enough
    [5, 3, 2000], // capped
    [1, 6, 666], // 6.666… rounds down, never up
    [2, 6, 1333],
    [3, 6, 2000],
    [1, 8, 500], // N = 8: q = 4
    [3, 8, 1500],
    [4, 8, 2000],
    [7, 8, 2000],
  ])('%i votes with N = %i → %i centipoints', (votes, n, expected) => {
    expect(photoCentipoints(votes, n)).toBe(expected);
  });

  it('missing votes give partial points, never negative', () => {
    for (let n = 3; n <= 8; n++) {
      for (let v = 0; v <= n; v++) {
        const c = photoCentipoints(v, n);
        expect(c).toBeGreaterThanOrEqual(0);
        expect(c).toBeLessThanOrEqual(2000);
      }
    }
  });

  it('rejects negative or fractional vote counts', () => {
    expect(() => photoCentipoints(-1, 5)).toThrow(RangeError);
    expect(() => photoCentipoints(0.5, 5)).toThrow(RangeError);
  });
});

describe('countValidVotes', () => {
  const ids = members(5);

  it('ignores self-votes', () => {
    expect(countValidVotes({ authorId: 'm1', voterIds: ['m1'] }, ids)).toBe(0);
    expect(countValidVotes({ authorId: 'm1', voterIds: ['m1', 'm2'] }, ids)).toBe(1);
  });

  it('counts each voter once (duplicate votes)', () => {
    expect(countValidVotes({ authorId: 'm1', voterIds: ['m2', 'm2', 'm2'] }, ids)).toBe(1);
  });

  it('ignores voters outside the locked round list', () => {
    expect(countValidVotes({ authorId: 'm1', voterIds: ['outsider', 'm9', 'm3'] }, ids)).toBe(1);
  });

  it('self + duplicate + outsider votes cannot fake full photo points', () => {
    const score = scoreDay(
      'm1',
      {
        steps: 0,
        checkin: { authorId: 'm1', voterIds: ['m1', 'm1', 'm2', 'm2', 'x', 'y'] },
        activities: [],
      },
      ids,
    );
    expect(score.photoCentipoints).toBe(1000); // only m2 counts: 1 of q = 2
  });
});

describe('scoreDay', () => {
  it('missing step data scores 0 but is flagged as not synced (never shown as 0 steps)', () => {
    const score = scoreDay('m1', { steps: null, checkin: null, activities: [] }, members(3));
    expect(score).toEqual({
      movementCentipoints: 0,
      countedRideMetres: 0,
      photoCentipoints: 0,
      totalCentipoints: 0,
      hasStepData: false,
    });
  });

  it('a synced day with 0 steps is distinct from a missing day', () => {
    expect(
      scoreDay('m1', { steps: 0, checkin: null, activities: [] }, members(3)).hasStepData,
    ).toBe(true);
  });

  it('no check-in → no photo points', () => {
    expect(
      scoreDay('m1', { steps: 10_000, checkin: null, activities: [] }, members(4)).totalCentipoints,
    ).toBe(8000);
  });

  it('caps a perfect day at 100 points', () => {
    const score = scoreDay(
      'm1',
      {
        steps: 50_000,
        checkin: { authorId: 'm1', voterIds: ['m2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8'] },
        activities: [],
      },
      members(8),
    );
    expect(centipointsToPoints(score.totalCentipoints)).toBe(100);
  });

  it('rejects a check-in that belongs to someone else', () => {
    expect(() =>
      scoreDay(
        'm1',
        { steps: 0, checkin: { authorId: 'm2', voterIds: ['m3'] }, activities: [] },
        members(3),
      ),
    ).toThrow();
  });

  it('rejects scoring a member outside the locked list', () => {
    expect(() =>
      scoreDay('late-joiner', { steps: 9000, checkin: null, activities: [] }, members(3)),
    ).toThrow();
  });
});
