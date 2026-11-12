# Contributing to Hype2gether

Detailed specs live in `docs/`:

- `docs/PRODUCT_BRIEF.md`: what we build, MVP scope, scoring rules (source of truth for game logic)
- `docs/ARCHITECTURE.md`: repo layout, data model, flows, decisions
- `docs/SECURITY.md`: secrets policy (mandatory)
- `docs/FEATURES.md`: feature codes and acceptance criteria (reference them in commits and PRs)

Setup and commands are in the [README](README.md).

## Project in one paragraph

Hype2gether is an iOS-first mobile app where small groups of close friends (3–8 people) compete on weekly movement (steps, plus walking, running and cycling workouts from Apple Health) and daily photo check-ins verified by party votes. Each walk, run, ride and week ends with a shareable achievement card (9:16 and 4:5) that users flex on social media, Strava-style. The card is the product's centrepiece.

## Naming

- Brand name: **Hype2gether** (always this exact spelling and casing in UI copy).
- Code identifiers: `hype2gether` (repo, package scope `@hype2gether/*`, bundle id prefix decided by the team).
- Users may type "hypetogether": keep that spelling in mind for deep links and search keywords; never use it as the display name.

## Working together

- The team talks in Vietnamese. Code, comments, commit messages and docs are in English.
- For non-trivial changes, describe the plan and the files you will touch in an issue or draft PR before writing the code.
- When unsure about a library API or version, check the official docs. Never pin a package version without checking that it exists.

## Stack

- App: React Native + Expo (dev build, Expo Router), TypeScript strict. iOS first; Android later from the same code.
- Health data: HealthKit via a maintained React Native library. Daily step aggregates plus walking, running and cycling workout summaries; workout routes are read on the device only, to draw cards.
- Backend: Supabase (Postgres, Auth, Storage, Realtime, Edge Functions, scheduled jobs). Hosted dev project, no local Docker required.
- Game logic: `packages/scoring`, pure TypeScript with zero runtime dependencies, fully unit-tested.
- Card: React Native Skia + view capture; skins are data (JSON + assets), not code.
- Tooling: pnpm workspaces, ESLint, Prettier, Vitest, gitleaks, GitHub Actions.
- Builds via EAS Build (cloud). Test on physical iPhones.

## Repository layout

```
apps/mobile/           Expo app (UI, device integrations only, no game rules here)
                       src/features/<domain>/ = api.ts · hooks.ts · screens/ · components/
packages/scoring/      Pure scoring engine (daily points, weekly ranking, rating deltas, tiers)
packages/shared/       Generated DB types, zod schemas for function contracts, constants (no secrets, no env access)
supabase/migrations/   SQL migrations (schema, RLS policies), the only way to change the DB
supabase/functions/    Edge Functions (server-authoritative writes, round finalization)
docs/                  Product, architecture, security, ADRs
```

## Engineering rules

1. **Server is authoritative.** Clients submit raw facts (daily step totals, check-ins, votes). Only server code computes and writes points, results and ratings.
2. **Scoring lives in `packages/scoring` only.** App and Edge Functions import it; never re-implement a formula elsewhere. Every rule change bumps `RULE_VERSION`.
3. **Idempotency.** Re-sending the same data must never double-count. Use unique constraints + upserts (e.g. one step summary per user/round/day).
4. **`party_id` is the tenant key.** Every party-scoped row is reachable from a `party_id`; every policy filters by membership. RLS is on for every table, deny by default. A CI test fails if any table in `public` has RLS disabled or no policy, and each table has a test proving a non-member cannot read it.
5. **Privacy by default.** Store daily step totals only (no raw health samples, no location). Parties are private. Photos live in a private bucket served by signed URLs.
6. **Never commit secrets.** Follow `docs/SECURITY.md`. Never commit `.env*` (except `.env.example`), keys, certificates or credentials.
7. **Small, reviewable steps.** One concern per commit. Conventional Commits (`feat:`, `fix:`, `chore:`…). Run lint, typecheck and tests before opening a PR.
8. **Original code only.** Do not copy code from other projects or external repositories. Use official docs and well-maintained open-source packages with compatible licences.
9. **Contracts are generated, not hand-written.** DB types come from `supabase gen types` into `packages/shared`; Edge Function inputs/outputs are zod schemas in `packages/shared`. CI fails if generated types are stale.
10. **The server decides, the UI only shows or hides.** Permissions, limits and deadlines are enforced in RLS/functions; client checks are for UX only.
11. **Every failed action shows an error and restores state.** Optimistic updates must roll back. User-initiated deletes (check-in, leave party) are confirmed or undoable; account deletion is a real, complete deletion.
12. **Work references feature codes** from `docs/FEATURES.md` (e.g. `feat(party): PARTY-02 join by invite code`).

## Pull requests

`main` is protected: every change goes through a pull request and needs passing CI.

## Definition of done

- Lint, typecheck and tests pass locally and in CI.
- New tables have migrations + RLS policies + tests; generated types updated.
- The feature code's acceptance criteria in `docs/FEATURES.md` are met.
- No secret or personal data in the diff (gitleaks clean).
- Docs updated when behaviour or architecture changes (add an ADR in `docs/adr/` for decisions).
