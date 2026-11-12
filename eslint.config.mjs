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
  // Dependency direction (docs/ARCHITECTURE.md): apps depend on packages, never the reverse.
  {
    files: ['packages/**/*.ts'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@hype2gether/mobile', '**/apps/**'],
              message: 'A package never imports an app. Dependencies point apps -> packages only.',
            },
          ],
        },
      ],
    },
  },
  // packages/scoring is pure: no runtime dependency, no Node built-in, no sibling package.
  // It has to run unchanged in Hermes on the phone and in Deno on the server.
  {
    files: ['packages/scoring/src/**/*.ts'],
    ignores: ['packages/scoring/src/**/*.test.ts'],
    rules: {
      'no-restricted-syntax': [
        'error',
        ...['ImportDeclaration', 'ExportAllDeclaration', 'ExportNamedDeclaration'].map(
          (statement) => ({
            selector: `${statement} > Literal.source:not([value=/^[.][.]?[/]/])`,
            message:
              'packages/scoring has zero runtime dependencies, so it keeps working in Hermes and in Deno. Import only its own modules.',
          }),
        ),
      ],
    },
  },
  prettier,
);
