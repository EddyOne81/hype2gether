// GENERATED FILE: do not edit by hand.
// Mirrored from packages/scoring/src/time.ts by `pnpm build:functions`. Edit the package, not this copy.

import { ROUND_DAYS } from './constants.ts';

/**
 * Day bucketing.
 *
 * Which calendar day a fact belongs to is a game rule, not a formatting detail: a ride that
 * starts at 23:50 and one that starts at 00:10 score on different days, and the boundary is
 * the party's time zone, not the phone's. It lives here so the app preview and the Edge
 * Functions bucket identically instead of each re-deriving it.
 *
 * Needs a runtime with a time zone database. An unknown zone throws rather than quietly
 * falling back to UTC, which would move someone's steps to the wrong day.
 */

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatterFor(timeZone: string): Intl.DateTimeFormat {
  const cached = formatters.get(timeZone);
  if (cached) return cached;
  // Throws RangeError for a zone the runtime does not know.
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  formatters.set(timeZone, formatter);
  return formatter;
}

function pad(value: number): string {
  return String(value).padStart(2, '0');
}

/** The calendar day a moment falls on in the given time zone, as `YYYY-MM-DD`. */
export function dayKey(instant: Date | number, timeZone: string): string {
  const at = typeof instant === 'number' ? new Date(instant) : instant;
  if (Number.isNaN(at.getTime())) {
    throw new RangeError('dayKey needs a valid instant');
  }
  const parts = formatterFor(timeZone).formatToParts(at);
  const read = (type: Intl.DateTimeFormatPartTypes): string | undefined =>
    parts.find((part) => part.type === type)?.value;
  const year = read('year');
  const month = read('month');
  const day = read('day');
  if (!year || !month || !day) {
    throw new RangeError(`Could not read a calendar day in time zone ${timeZone}`);
  }
  return `${year}-${month}-${day}`;
}

/**
 * The day keys of a round, in order, starting with the day the round starts on.
 *
 * Days are stepped as calendar dates rather than by adding 24 hours, so a round that crosses
 * a daylight saving change still has exactly seven days.
 */
export function roundDayKeys(
  startsAt: Date | number,
  timeZone: string,
  days: number = ROUND_DAYS,
): string[] {
  if (!Number.isInteger(days) || days < 1) {
    throw new RangeError(`A round needs at least one day, got ${days}`);
  }
  const [year, month, day] = dayKey(startsAt, timeZone).split('-').map(Number) as [
    number,
    number,
    number,
  ];
  const first = Date.UTC(year, month - 1, day);
  return Array.from({ length: days }, (_, offset) => {
    const at = new Date(first + offset * 86_400_000);
    return `${at.getUTCFullYear()}-${pad(at.getUTCMonth() + 1)}-${pad(at.getUTCDate())}`;
  });
}
