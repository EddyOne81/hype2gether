import { describe, expect, it } from 'vitest';
import { rankMembers } from './ranking';
import { applyRatingDelta, ratingDelta } from './rating';
import { tierFor } from './tier';

/** Rank totals (in centipoints) and return [place, ΔR] in input order. */
function placesAndDeltas(totals: number[]): [number, number][] {
  const placements = rankMembers(
    totals.map((totalCentipoints, i) => ({ memberId: `m${i + 1}`, totalCentipoints })),
  );
  const byId = new Map(placements.map((p) => [p.memberId, p]));
  return totals.map((_, i) => {
    const p = byId.get(`m${i + 1}`);
    if (!p) throw new Error(`missing placement for m${i + 1}`);
    return [p.place, ratingDelta(p, totals.length)];
  });
}

describe('required test cases (PRODUCT_BRIEF.md)', () => {
  it('N = 5 distinct totals → ΔR = +20/+10/0/−10/−20', () => {
    expect(placesAndDeltas([500, 400, 300, 200, 100])).toEqual([
      [1, 20],
      [2, 10],
      [3, 0],
      [4, -10],
      [5, -20],
    ]);
  });

  it('ties share place and ΔR', () => {
    expect(placesAndDeltas([500, 400, 400, 200, 100])).toEqual([
      [1, 20],
      [2, 5],
      [2, 5],
      [4, -10],
      [5, -20],
    ]);
  });
});

describe('rankMembers', () => {
  it('uses competition ranking (1, 1, 3)', () => {
    expect(placesAndDeltas([700, 700, 100]).map(([place]) => place)).toEqual([1, 1, 3]);
  });

  it('is independent of input order', () => {
    const a = rankMembers([
      { memberId: 'a', totalCentipoints: 3 },
      { memberId: 'b', totalCentipoints: 2 },
      { memberId: 'c', totalCentipoints: 1 },
    ]);
    const b = rankMembers([
      { memberId: 'c', totalCentipoints: 1 },
      { memberId: 'a', totalCentipoints: 3 },
      { memberId: 'b', totalCentipoints: 2 },
    ]);
    expect(a).toEqual(b);
  });

  it('rejects duplicate members and non-integer totals', () => {
    expect(() =>
      rankMembers([
        { memberId: 'a', totalCentipoints: 1 },
        { memberId: 'a', totalCentipoints: 2 },
      ]),
    ).toThrow();
    expect(() => rankMembers([{ memberId: 'a', totalCentipoints: 1.5 }])).toThrow(RangeError);
  });
});

describe('ratingDelta', () => {
  it('N = 3 distinct → +20/0/−20', () => {
    expect(placesAndDeltas([3, 2, 1]).map(([, d]) => d)).toEqual([20, 0, -20]);
  });

  it('N = 8 distinct → rounded steps of 20/7', () => {
    expect(placesAndDeltas([8, 7, 6, 5, 4, 3, 2, 1]).map(([, d]) => d)).toEqual([
      20, 14, 9, 3, -3, -9, -14, -20,
    ]);
  });

  it('N = 8 with ties in the middle', () => {
    expect(placesAndDeltas([8, 7, 5, 5, 5, 3, 2, 1])).toEqual([
      [1, 20],
      [2, 14],
      [3, 3],
      [3, 3],
      [3, 3],
      [6, -9],
      [7, -14],
      [8, -20],
    ]);
  });

  it('everyone tied → nobody moves', () => {
    expect(placesAndDeltas([42, 42, 42, 42]).map(([, d]) => d)).toEqual([0, 0, 0, 0]);
  });

  it('is zero-sum and within ±20 for every party size with distinct totals', () => {
    for (let n = 3; n <= 8; n++) {
      const deltas = placesAndDeltas(Array.from({ length: n }, (_, i) => n - i)).map(([, d]) => d);
      expect(deltas.reduce((s, d) => s + d, 0)).toBe(0);
      for (const d of deltas) expect(Math.abs(d)).toBeLessThanOrEqual(20);
    }
  });

  it('never returns -0', () => {
    expect(Object.is(ratingDelta({ countLower: 1, countHigher: 1 }, 3), 0)).toBe(true);
  });

  it('rejects invalid party sizes', () => {
    expect(() => ratingDelta({ countLower: 1, countHigher: 0 }, 2)).toThrow(RangeError);
    expect(() => ratingDelta({ countLower: 1, countHigher: 0 }, 9)).toThrow(RangeError);
  });
});

describe('applyRatingDelta', () => {
  it.each([
    [1000, 20, 1020],
    [1000, -20, 980],
    [15, -20, 0], // floor 0
    [0, -20, 0],
    [0, 20, 20],
  ])('%i %+i → %i', (before, delta, after) => {
    expect(applyRatingDelta(before, delta)).toBe(after);
  });

  it('rejects deltas outside ±20 and invalid ratings', () => {
    expect(() => applyRatingDelta(1000, 21)).toThrow(RangeError);
    expect(() => applyRatingDelta(1000, 2.5)).toThrow(RangeError);
    expect(() => applyRatingDelta(-1, 0)).toThrow(RangeError);
  });
});

describe('tierFor', () => {
  it.each([
    [0, 'bronze'],
    [1000, 'bronze'],
    [1099, 'bronze'],
    [1100, 'silver'],
    [1199, 'silver'],
    [1200, 'gold'],
    [1349, 'gold'],
    [1350, 'platinum'],
    [5000, 'platinum'],
  ] as const)('%i → %s', (rating, tier) => {
    expect(tierFor(rating)).toBe(tier);
  });
});
