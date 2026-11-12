// https://docs.expo.dev/guides/using-eslint/
const { defineConfig, globalIgnores } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const prettierConfig = require('eslint-config-prettier/flat');

module.exports = defineConfig([
  globalIgnores(['dist/*', '.expo/*', 'expo-env.d.ts']),
  expoConfig,
  // docs/ARCHITECTURE.md: screens and components never call Supabase directly. Data access
  // goes through the feature's api.ts, and screens use its hooks.ts.
  {
    files: [
      'app/**/*.{ts,tsx}',
      'src/features/*/screens/**/*.{ts,tsx}',
      'src/features/*/components/**/*.{ts,tsx}',
      'src/components/**/*.{ts,tsx}',
    ],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@supabase/*', '**/services/supabase', '**/services/supabase/**'],
              message:
                "Use the feature's api.ts and hooks.ts instead of reaching for Supabase here.",
            },
          ],
        },
      ],
    },
  },
  prettierConfig,
]);
