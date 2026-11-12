// Lint config for packages/* and root scripts. apps/mobile has its own config (eslint-config-expo).
import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      'apps/**',
      '**/node_modules/**',
      '**/dist/**',
      '**/coverage/**',
      'supabase/**',
      'packages/shared/src/db.types.ts',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.strict,
  {
    files: ['scripts/**/*.mjs', '*.mjs'],
    languageOptions: { globals: globals.node },
  },
  prettier,
);
