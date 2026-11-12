# 0010 — Shared code in Edge Functions

- Status: accepted
- Date: 2026-11-12

## Context

`docs/ARCHITECTURE.md` states that `supabase/functions` depends on `packages/scoring` and
`packages/shared`, and engineering rule 2 forbids restating a formula anywhere else. Nothing had
checked that the dependency is possible.

It is not, by any of the obvious routes. The Edge Runtime only ever sees the `supabase/`
directory, in `supabase functions serve` and when a function is deployed. A function importing
`../../packages/scoring/src/index.ts`, directly or through a `deno.json` import map, fails at
boot with `Module not found`; a symlink out of the tree is not followed either. On top of that,
Deno resolves ES module specifiers literally, so the extensionless relative imports that Metro
and Vitest accept would not resolve even if the files were reachable.

Round finalization is the next piece of work and cannot be written without a way across.

## Decision

- `pnpm build:functions` mirrors `packages/scoring/src` and `packages/shared/src` into
  `supabase/functions/_shared/`, which is Supabase's own convention for code shared between
  functions. Test files are not copied.
- The mirror is generated, carries a header saying so, and is committed. CI regenerates it and
  fails on any diff — the same contract `packages/shared/src/db.types.ts` already has.
- The only transformation is adding explicit extensions to relative specifiers, resolved against
  the file system because `./contracts` may be a module or a directory with an index.
- Functions import `@hype2gether/scoring` and `@hype2gether/shared` through the import map in
  `supabase/functions/deno.json`, so a function reads like the app does and the mirror stays an
  implementation detail.
- `scoring-version` is kept as a small real function that imports from both packages: if the
  route across ever breaks, a deployment fails there rather than inside round finalization.

## Consequences

- The packages remain the only place the rules are written. The copy is build output, and
  editing it is caught by CI rather than by a wrong score.
- Changing a package means running `pnpm build:functions` before committing, like
  `pnpm gen:types` after a migration. Both are checked in the same CI job.
- The mirror is readable TypeScript, so a reviewer can diff it and see exactly what the server
  will run. A bundler would have been less work and less reviewable.
- Deno tests for Edge Functions still need Deno on the CI runner; that arrives with the first
  function that has logic worth testing (ROUND-02).
- If the packages ever gain a runtime dependency, the import map needs an `npm:` entry for it.
  `packages/scoring` cannot: the linter now refuses any import that is not one of its own
  modules.
