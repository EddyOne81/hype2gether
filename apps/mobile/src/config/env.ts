import { z } from 'zod';

const envSchema = z.object({
  EXPO_PUBLIC_APP_ENV: z.enum(['development', 'preview', 'production']),
  EXPO_PUBLIC_SUPABASE_URL: z.url({ protocol: /^https?$/ }),
  EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z
    .string()
    .min(1)
    .refine((key) => !key.startsWith('sb_secret_'), {
      message: 'A secret key must never be shipped in the app; use the publishable key',
    }),
});

export type Env = z.infer<typeof envSchema>;

/** Validates app config. Errors name the offending keys only, never their values. */
export function parseEnv(source: Record<string, string | undefined>): Env {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    const problems = result.error.issues.map(
      (issue) => `${issue.path.join('.')}: ${issue.message}`,
    );
    throw new Error(
      `Invalid app config (see apps/mobile/.env.example):\n- ${[...new Set(problems)].join('\n- ')}`,
    );
  }
  return result.data;
}

let cached: Env | undefined;

/** Lazily reads and validates EXPO_PUBLIC_* config on first use. */
export function getEnv(): Env {
  // Expo only inlines EXPO_PUBLIC_* values on static `process.env.NAME` access,
  // so every key is listed explicitly instead of passing `process.env` itself.
  cached ??= parseEnv({
    EXPO_PUBLIC_APP_ENV: process.env.EXPO_PUBLIC_APP_ENV,
    EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
    EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  });
  return cached;
}
