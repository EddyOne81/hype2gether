import { describe, expect, it } from 'vitest';
import { daySchema, idSchema } from './common';

describe('common contract schemas', () => {
  it('accepts a UUID and rejects other strings', () => {
    expect(idSchema.safeParse('3f1c2b8e-6a4d-4c3e-9b7a-2d1e0f9a8b7c').success).toBe(true);
    expect(idSchema.safeParse('not-a-uuid').success).toBe(false);
  });

  it('accepts a calendar day and rejects timestamps or invalid dates', () => {
    expect(daySchema.safeParse('2026-11-12').success).toBe(true);
    expect(daySchema.safeParse('2026-11-12T10:00:00Z').success).toBe(false);
    expect(daySchema.safeParse('2026-02-30').success).toBe(false);
  });
});
