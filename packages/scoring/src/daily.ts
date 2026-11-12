import { MAX_PHOTO_CENTIPOINTS, MAX_STEP_CENTIPOINTS, STEP_CAP } from './constants';
import { assertNonNegativeInteger, assertPartySize } from './validation';

/** Verify votes needed for full photo points: q = ceil((N − 1) / 2). */
export function requiredVotes(memberCount: number): number {
  assertPartySize(memberCount);
  return Math.ceil((memberCount - 1) / 2);
}

/**
 * stepPoints = 80 × min(steps / 10000, 1), in centipoints, rounded down.
 * Steps above the cap are still real steps for display; they just earn no extra points.
 */
export function stepCentipoints(steps: number): number {
  assertNonNegativeInteger(steps, 'steps');
  const counted = Math.min(steps, STEP_CAP);
  return Math.floor((MAX_STEP_CENTIPOINTS * counted) / STEP_CAP);
}

export interface CheckinVotes {
  authorId: string;
  /** Voter ids as stored; duplicates and invalid voters are ignored. */
  voterIds: readonly string[];
}

/**
 * Valid verify votes on a check-in: distinct voters who are locked round members
 * and not the author. Self-votes, duplicates and outsiders never count.
 */
export function countValidVotes(checkin: CheckinVotes, roundMemberIds: readonly string[]): number {
  const members = new Set(roundMemberIds);
  const voters = new Set(
    checkin.voterIds.filter((id) => id !== checkin.authorId && members.has(id)),
  );
  return voters.size;
}

/** photoPoints = 20 × min(v / q, 1), in centipoints, rounded down. */
export function photoCentipoints(validVotes: number, memberCount: number): number {
  assertNonNegativeInteger(validVotes, 'validVotes');
  const q = requiredVotes(memberCount);
  return Math.floor((MAX_PHOTO_CENTIPOINTS * Math.min(validVotes, q)) / q);
}

export interface DailyInput {
  /** Synced daily step total, or null when no data has been synced for that day. */
  steps: number | null;
  /** The day's counted check-in, or null when the member did not check in. */
  checkin: CheckinVotes | null;
}

export interface DailyScore {
  stepCentipoints: number;
  photoCentipoints: number;
  totalCentipoints: number;
  /** False means "not synced yet": the UI must never show this as 0 steps. */
  hasStepData: boolean;
}

export function scoreDay(
  memberId: string,
  day: DailyInput,
  roundMemberIds: readonly string[],
): DailyScore {
  const memberCount = roundMemberIds.length;
  assertPartySize(memberCount);
  if (!roundMemberIds.includes(memberId)) {
    throw new Error(`Member ${memberId} is not in the locked round list`);
  }
  if (day.checkin && day.checkin.authorId !== memberId) {
    throw new Error('Check-in author does not match the scored member');
  }
  const steps = day.steps === null ? 0 : stepCentipoints(day.steps);
  const photo = day.checkin
    ? photoCentipoints(countValidVotes(day.checkin, roundMemberIds), memberCount)
    : 0;
  return {
    stepCentipoints: steps,
    photoCentipoints: photo,
    totalCentipoints: steps + photo,
    hasStepData: day.steps !== null,
  };
}
