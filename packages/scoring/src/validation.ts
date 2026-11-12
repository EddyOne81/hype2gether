import { MAX_PARTY_SIZE, MIN_PARTY_SIZE } from './constants';

export function assertPartySize(memberCount: number): void {
  if (
    !Number.isInteger(memberCount) ||
    memberCount < MIN_PARTY_SIZE ||
    memberCount > MAX_PARTY_SIZE
  ) {
    throw new RangeError(
      `Party size must be an integer between ${MIN_PARTY_SIZE} and ${MAX_PARTY_SIZE}, got ${memberCount}`,
    );
  }
}

export function assertNonNegativeInteger(value: number, name: string): void {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new RangeError(`${name} must be a non-negative integer, got ${value}`);
  }
}

export function assertUniqueIds(ids: readonly string[], name: string): void {
  if (new Set(ids).size !== ids.length) {
    throw new Error(`${name} must not contain duplicate ids`);
  }
}
