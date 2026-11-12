import { describe, expect, it } from 'vitest';
import { activityRejection, countedRideMetres, isValidRide, type ActivityInput } from './activity';
import { RULE_VERSION } from './constants';
import { movementCentipoints, scoreDay } from './daily';
import { centipointsToPoints } from './format';
import { finalizeRound } from './round';

const MINUTE = 60_000;
const T0 = Date.UTC(2026, 10, 9, 0, 0); // 07:00 in Asia/Ho_Chi_Minh

let nextId = 0;
/** A recorded ride at 20 km/h unless overridden, starting `startMin` minutes after T0. */
const ride = (km: number, startMin = 0, overrides: Partial<ActivityInput> = {}): ActivityInput => {
  const distanceMetres = km * 1000;
  const durationSeconds = Math.round((distanceMetres / 20_000) * 3600);
  const startedAt = T0 + startMin * MINUTE;
  return {
    id: `a${++nextId}`,
    sport: 'ride',
    startedAt,
    endedAt: startedAt + durationSeconds * 1000,
    durationSeconds,
    distanceMetres,
    userEntered: false,
    ...overrides,
  };
};
const run = (km: number, startMin = 0): ActivityInput => ({ ...ride(km, startMin), sport: 'run' });
const walk = (km: number, startMin = 0): ActivityInput => ({
  ...ride(km, startMin),
  sport: 'walk',
});

const ids = ['m1', 'm2', 'm3', 'm4', 'm5'];
const day = (steps: number | null, activities: ActivityInput[]) =>
  scoreDay('m1', { steps, checkin: null, activities }, ids);

describe('required test cases, rule v2 (PRODUCT_BRIEF.md)', () => {
  it('4,000 steps + 15 km valid ride → 72 movement points', () => {
    expect(centipointsToPoints(day(4000, [ride(15)]).movementCentipoints)).toBe(72);
  });

  it('2,000 steps + 60 km valid ride → 80 movement points (capped)', () => {
    const score = day(2000, [ride(60)]);
    expect(centipointsToPoints(score.movementCentipoints)).toBe(80);
    expect(score.countedRideMetres).toBe(60_000); // real distance is kept for display
  });

  it('8,000 steps + 15 km manually entered ride → 64 movement points', () => {
    const manual = ride(15, 0, { userEntered: true });
    expect(activityRejection(manual)).toBe('user_entered');
    expect(centipointsToPoints(day(8000, [manual]).movementCentipoints)).toBe(64);
  });

  it('two overlapping valid rides of 20 km and 18 km → only 20 km counts', () => {
    expect(countedRideMetres([ride(18, 5), ride(20, 0)])).toBe(20_000);
  });

  it('a ride at 45 km/h average → not valid', () => {
    const fast = ride(45, 0, { durationSeconds: 3600 });
    expect(activityRejection(fast)).toBe('too_fast');
    expect(isValidRide(fast)).toBe(false);
  });
});

describe('movementCentipoints', () => {
  it.each([
    [0, 0, 0],
    [0, 30_000, 8000],
    [0, 15_000, 4000],
    [0, 1, 0], // 0.0027 points rounds down
    [1, 1, 1], // 4 metre-equivalents → 1.07 centipoints
    [3333, 0, 2666], // same as rule v1 for steps only
    [10_000, 30_000, 8000],
    [Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER, 8000], // no overflow
  ])('%i steps + %i m ridden → %i centipoints', (steps, metres, expected) => {
    expect(movementCentipoints(steps, metres)).toBe(expected);
  });

  it('matches rule v1 step points whenever there is no ride', () => {
    for (let steps = 0; steps <= 12_000; steps += 7) {
      expect(movementCentipoints(steps, 0)).toBe(
        Math.floor((8000 * Math.min(steps, 10_000)) / 10_000),
      );
    }
  });

  it.each([
    [-1, 0],
    [0, -1],
    [0, 1.5],
    [0, Number.NaN],
  ])('rejects invalid input %s steps, %s m', (steps, metres) => {
    expect(() => movementCentipoints(steps, metres)).toThrow(RangeError);
  });
});

describe('activityRejection', () => {
  it('accepts exactly 10 minutes and exactly 40 km/h', () => {
    expect(activityRejection(ride(0, 0, { durationSeconds: 600, distanceMetres: 6667 }))).toBe(
      'too_fast', // 40.002 km/h
    );
    expect(
      activityRejection(ride(0, 0, { durationSeconds: 600, distanceMetres: 6666 })),
    ).toBeNull();
    expect(
      activityRejection(ride(0, 0, { durationSeconds: 900, distanceMetres: 10_000 })),
    ).toBeNull();
  });

  it('rejects rides shorter than 10 minutes', () => {
    expect(activityRejection(ride(3, 0, { durationSeconds: 599 }))).toBe('too_short');
  });

  it('reports manual entry before any other problem', () => {
    expect(activityRejection(ride(100, 0, { durationSeconds: 60, userEntered: true }))).toBe(
      'user_entered',
    );
  });

  it.each([
    { startedAt: -1 },
    { durationSeconds: 1.5 },
    { distanceMetres: -5 },
    { distanceMetres: Number.POSITIVE_INFINITY },
    { startedAt: T0 + MINUTE, endedAt: T0 },
  ])('rejects malformed activity %o', (overrides) => {
    expect(() => activityRejection(ride(10, 0, overrides))).toThrow(RangeError);
  });
});

describe('countedRideMetres', () => {
  it('runs never add ride distance (they score through steps)', () => {
    expect(countedRideMetres([run(10)])).toBe(0);
    expect(day(12_000, [run(10)]).movementCentipoints).toBe(8000);
    expect(day(5000, [run(10)]).movementCentipoints).toBe(4000);
  });

  it('adds up rides that do not overlap, including rides that only touch', () => {
    const first = ride(10); // 30 minutes
    expect(countedRideMetres([first, ride(6, 30), ride(4, 120)])).toBe(20_000);
  });

  it('treats a chain of overlaps as one group and keeps its longest ride', () => {
    // 0–30 min, 20–50 min, 45–75 min: each overlaps the next, the first and last do not.
    expect(
      countedRideMetres([ride(10, 0), ride(10, 20, { distanceMetres: 12_000 }), ride(10, 45)]),
    ).toBe(12_000);
  });

  it('an invalid duplicate cannot knock out the valid ride it overlaps', () => {
    const manualCopy = ride(25, 1, { userEntered: true });
    expect(countedRideMetres([ride(20, 0), manualCopy])).toBe(20_000);
  });

  it('does not depend on input order', () => {
    const rides = [ride(5, 200), ride(8, 0), ride(12, 10), ride(4, 100)];
    expect(countedRideMetres([...rides].reverse())).toBe(countedRideMetres(rides));
    expect(countedRideMetres(rides)).toBe(12_000 + 4000 + 5000);
  });

  it('is 0 for a day without activities', () => {
    expect(countedRideMetres([])).toBe(0);
  });
});

describe('scoreDay with activities', () => {
  it('rides score on a day without synced steps, which stays flagged as not synced', () => {
    const score = day(null, [ride(30)]);
    expect(score.movementCentipoints).toBe(8000);
    expect(score.hasStepData).toBe(false);
  });

  it('a ride cannot push a day past 100 points', () => {
    const score = scoreDay(
      'm1',
      {
        steps: 10_000,
        checkin: { authorId: 'm1', voterIds: ['m2', 'm3'] },
        activities: [ride(100, 0, { durationSeconds: 5 * 3600 })],
      },
      ids,
    );
    expect(centipointsToPoints(score.totalCentipoints)).toBe(100);
  });
});

describe('finalizeRound with rides', () => {
  it('a cyclist with few steps can win the round', () => {
    const week = (steps: number, activities: ActivityInput[]) =>
      Array.from({ length: 7 }, () => ({ steps, checkin: null, activities }));
    const result = finalizeRound({
      hasOpenDispute: false,
      ruleVersion: RULE_VERSION,
      members: [
        { memberId: 'walker', ratingBefore: 1000, days: week(9000, []) },
        { memberId: 'cyclist', ratingBefore: 1000, days: week(2000, [ride(25)]) },
        { memberId: 'idle', ratingBefore: 1000, days: week(3000, []) },
      ],
    });
    expect(result.status).toBe('final');
    expect(result.results.map((r) => r.memberId)).toEqual(['cyclist', 'walker', 'idle']);
  });
});

describe('walks', () => {
  it('never add ride distance (they score through steps, like runs)', () => {
    expect(countedRideMetres([walk(5)])).toBe(0);
    expect(day(6000, [walk(5)]).movementCentipoints).toBe(4800);
  });

  it('do not hide an overlapping valid ride', () => {
    expect(countedRideMetres([walk(12, 0), ride(10, 5)])).toBe(10_000);
  });
});
