# 0001 — Monorepo with pnpm workspaces

- Status: accepted
- Date: 2026-11-12

## Context

Hype2gether has a mobile app, server code (Supabase Edge Functions, SQL) and game logic that both sides must share exactly. We want one language (TypeScript) end to end, atomic changes across app, server and rules, and a single CI pipeline. The team develops on Windows.

## Decision

- One repository with pnpm workspaces: `apps/mobile`, `packages/scoring`, `packages/shared`, plus `supabase/`.
- Workspace packages are consumed as TypeScript source (`"main": "./src/index.ts"`); no build step for internal packages.
- pnpm's default isolated `node_modules` layout. Expo supports isolated installs from SDK 54 and configures Metro for monorepos automatically from SDK 52, so no custom `metro.config` is needed. Fall back to `nodeLinker: hoisted` in `pnpm-workspace.yaml` only if a native module proves incompatible.
- Supply-chain defaults stay on: dependency build scripts are denied unless reviewed in `allowBuilds`, and pnpm's minimum release age is respected (no blanket `minimumReleaseAgeExclude`).
- The pnpm version is pinned through `packageManager` in the root `package.json`.

## Consequences

- One lockfile and one CI run cover everything; a rule change and its consumers land in the same commit.
- Dependency direction must be enforced by review: `apps/*` → `packages/*`, `supabase/functions` → `packages/*`, never the reverse.
- Supabase Edge Functions run on Deno; importing workspace packages from functions will need an import map or bundling step, decided when the first function is written.
- Newly published dependency versions are installable only after pnpm's release-age window; patch upgrades may lag by a day.
