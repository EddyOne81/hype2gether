import { describe, expect, it } from 'vitest';
import { dayKey, roundDayKeys } from './time';

const HCMC = 'Asia/Ho_Chi_Minh';

describe('dayKey', () => {
  it('buckets by the party time zone, not by UTC', () => {
    // 23:59 local on the 12th, which is still the 12th even though UTC has not got there.
    expect(dayKey(Date.parse('2026-11-12T16:59:00Z'), HCMC)).toBe('2026-11-12');
    // 00:30 local on the 13th: a late-night walk counts for the new day.
    expect(dayKey(Date.parse('2026-11-12T17:30:00Z'), HCMC)).toBe('2026-11-13');
  });

  it('gives different days to the same instant in different zones', () => {
    const instant = Date.parse('2026-11-12T22:00:00Z');
    expect(dayKey(instant, HCMC)).toBe('2026-11-13');
    expect(dayKey(instant, 'Europe/Paris')).toBe('2026-11-12');
    expect(dayKey(instant, 'UTC')).toBe('2026-11-12');
  });

  it('accepts a Date as well as epoch milliseconds', () => {
    const instant = Date.parse('2026-11-12T17:30:00Z');
    expect(dayKey(new Date(instant), HCMC)).toBe(dayKey(instant, HCMC));
  });

  it('refuses an unknown time zone instead of falling back to UTC', () => {
    expect(() => dayKey(Date.now(), 'Mars/Olympus_Mons')).toThrow(RangeError);
  });

  it('refuses an invalid instant', () => {
    expect(() => dayKey(new Date('not a date'), HCMC)).toThrow(RangeError);
  });
});

describe('roundDayKeys', () => {
  it('returns the seven days of a round in order', () => {
    expect(roundDayKeys(Date.parse('2026-11-11T17:00:00Z'), HCMC)).toEqual([
      '2026-11-12',
      '2026-11-13',
      '2026-11-14',
      '2026-11-15',
      '2026-11-16',
      '2026-11-17',
      '2026-11-18',
    ]);
  });

  it('still has seven days across a daylight saving change', () => {
    // European clocks go back on 25 October 2026; stepping by 24 hours would repeat a day.
    const days = roundDayKeys(Date.parse('2026-10-22T00:00:00Z'), 'Europe/Paris');
    expect(days).toEqual([
      '2026-10-22',
      '2026-10-23',
      '2026-10-24',
      '2026-10-25',
      '2026-10-26',
      '2026-10-27',
      '2026-10-28',
    ]);
  });

  it('crosses a month and a year boundary', () => {
    expect(roundDayKeys(Date.parse('2026-12-28T00:00:00Z'), 'UTC')).toEqual([
      '2026-12-28',
      '2026-12-29',
      '2026-12-30',
      '2026-12-31',
      '2027-01-01',
      '2027-01-02',
      '2027-01-03',
    ]);
  });

  it('refuses a round with no days', () => {
    expect(() => roundDayKeys(Date.now(), HCMC, 0)).toThrow(RangeError);
  });
});
