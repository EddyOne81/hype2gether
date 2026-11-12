# 0002 — Supabase as the backend

- Status: accepted
- Date: 2026-11-12

## Context

The MVP needs auth (Sign in with Apple), a relational model with per-party access control, private photo storage with signed URLs, realtime leaderboard updates, server-side functions and scheduled jobs. The team is small and should not operate servers.

## Decision

- Use Supabase: Postgres, Auth, Storage, Realtime, Edge Functions and scheduled jobs.
- Two hosted projects, `dev` and `prod`, with separate keys. A dev build never points at prod.
- The database changes only through SQL migrations in `supabase/migrations/`. Row Level Security is enabled on every table, deny by default, with policies filtering by party membership.
- RLS/SQL tests (pgTAP) run against a throw-away local stack (`supabase start`) in CI. Docker on developer machines is optional.
- DB types are generated with the Supabase CLI into `packages/shared/src/db.types.ts`; CI regenerates them and fails on any diff.
- The Supabase CLI is a pinned dev dependency so local and CI use the same version.

## Consequences

- Security depends on correct RLS; every table needs policies and a test proving a non-member cannot read it, plus the invariant test in `supabase/tests/`.
- The publishable key ships in the app (public by design); the secret/service role key lives only in Edge Function secrets.
- Vendor coupling to Supabase APIs is accepted; data stays in standard Postgres.
