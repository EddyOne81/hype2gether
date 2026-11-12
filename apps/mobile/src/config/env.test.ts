import { describe, expect, it } from 'vitest';
import { parseEnv } from './env';

// Fake values for tests only.
const valid = {
  EXPO_PUBLIC_APP_ENV: 'development',
  EXPO_PUBLIC_SUPABASE_URL: 'https://example.supabase.co',
  EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: 'test-publishable-key',
};

describe('parseEnv', () => {
  it('accepts a complete config', () => {
    expect(parseEnv(valid)).toEqual(valid);
  });

  it('rejects missing keys', () => {
    expect(() => parseEnv({ ...valid, EXPO_PUBLIC_SUPABASE_URL: undefined })).toThrow(
      /EXPO_PUBLIC_SUPABASE_URL/,
    );
  });

  it('rejects empty values copied from .env.example', () => {
    expect(() =>
      parseEnv({
        EXPO_PUBLIC_APP_ENV: '',
        EXPO_PUBLIC_SUPABASE_URL: '',
        EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: '',
      }),
    ).toThrow();
  });

  it('rejects an unknown app environment and a non-http URL', () => {
    expect(() => parseEnv({ ...valid, EXPO_PUBLIC_APP_ENV: 'staging' })).toThrow();
    expect(() => parseEnv({ ...valid, EXPO_PUBLIC_SUPABASE_URL: 'ftp://example.com' })).toThrow();
  });

  it('refuses a secret key and does not echo it in the error', () => {
    const fakeSecret = 'sb_secret_' + 'x'.repeat(8);
    let message = '';
    try {
      parseEnv({ ...valid, EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: fakeSecret });
    } catch (e) {
      message = (e as Error).message;
    }
    expect(message).toMatch(/EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY/);
    expect(message).not.toContain(fakeSecret);
  });
});
