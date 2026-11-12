# Hype2gether

iOS-first app where small groups of close friends compete on weekly movement (steps, runs and rides) and daily photo check-ins, and share achievement cards for each walk, run, ride and week.

Start with [`CONTRIBUTING.md`](CONTRIBUTING.md), then:

- [Product brief](docs/PRODUCT_BRIEF.md): scope and scoring rules
- [Architecture](docs/ARCHITECTURE.md): layout, data model, flows
- [Security](docs/SECURITY.md): secrets policy (mandatory)
- [Features](docs/FEATURES.md): feature codes and acceptance criteria
- [Decisions](docs/adr/)

Licence: all rights reserved, see [`LICENSE`](LICENSE). The code is public for viewing only.

## Requirements

- Node.js ≥ 22.13
- pnpm 12 (`npm i -g pnpm@12`, the exact version is pinned in `package.json`)
- [gitleaks](https://github.com/gitleaks/gitleaks) on `PATH`: commits are blocked without it (Windows: `winget install Gitleaks.Gitleaks`)
- Optional: Docker, only to run database tests locally (CI runs them)

## Setup

```sh
pnpm install          # also installs the git hooks
```

App config: copy `apps/mobile/.env.example` to `apps/mobile/.env` and fill in the **dev** project's public values. Never commit `.env` files or put secret keys in `EXPO_PUBLIC_*` variables.

## Commands

| Command                      | What it does                                                   |
| ---------------------------- | -------------------------------------------------------------- |
| `pnpm lint`                  | ESLint + Prettier check                                        |
| `pnpm typecheck`             | TypeScript in every workspace                                  |
| `pnpm test`                  | Vitest in every workspace                                      |
| `pnpm format`                | Format everything with Prettier                                |
| `pnpm --filter mobile start` | Metro dev server for the development build                     |
| `pnpm db:start` / `db:stop`  | Local Supabase stack (Docker)                                  |
| `pnpm test:db`               | RLS / SQL tests against the local stack                        |
| `pnpm gen:types`             | Regenerate `packages/shared/src/db.types.ts` from the local DB |

## Layout

```
apps/mobile         Expo app (Expo Router, dev build)
packages/scoring    Pure scoring engine (rule v2)
packages/shared     Generated DB types, zod contracts, constants
supabase/           Migrations, Edge Functions, SQL tests, seed (fake data only)
docs/               Product, architecture, security, ADRs
```
