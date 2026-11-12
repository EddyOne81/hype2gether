# 0008 — Database and row level security model

- Status: accepted
- Date: 2026-11-12

## Context

The MVP schema has to hold a competition whose outcome people care about, on a backend the app
talks to directly. Row level security is the only thing between a modified client and another
party's data, and between a player and their own score. ADR 0003 settled that the server is
authoritative; this record settles how the database makes that true rather than merely stated.

## Decision

- **Two layers, not one.** GRANTs decide what a role may attempt at all; policies decide which
  rows. The schema starts from no client access and hands out exactly what each role needs, so
  `anon` holds nothing and `daily_points`, `weekly_results`, `rating_history`, `cards`,
  `rounds`, `round_members`, `parties`, `memberships` and `invites` carry no write grant for any
  client role. A policy mistake alone cannot open them.
- **Clients write six tables only:** `daily_step_summaries`, `activities`, `checkins`, `votes`,
  `reactions`, `reports`, plus their own `profiles` row. Everything else is written by Edge
  Functions through the service role.
- **No scoring logic in SQL, ever.** The database stores facts, enforces identity, deadlines
  and shapes. Check constraints stay free of rule constants: the caps, the ride ratio and the
  rating clamp belong to `packages/scoring`, and a constraint repeating them would quietly go
  wrong the day `RULE_VERSION` moves.
- **Security helpers live in a private `app` schema**, outside the Data API, `security definer`
  with a pinned `search_path`, so a policy can read membership tables without recursing through
  their own policies and nothing it reads can be shadowed.
- **Deadlines are enforced in RLS**, not in the app: steps up to 12 hours after a round ends,
  votes up to 24 hours after a check-in. Both intervals appear exactly once in SQL, as
  functions.
- **Points are stored in centipoints and every column says so.** A column named
  `movement_points` holding 8000 for 80 points is a bug waiting to happen.
- **Integrity triggers are `security definer`.** They guard what the engine depends on, so
  they have to see the real state rather than the caller's filtered view — otherwise hiding a
  check-in from its reporter would also hide it from the trigger that validates their vote.
- **Hard invariants are triggers, not just policies**, so no writer — service role included —
  can create data the engine would have to discard: a fact belongs to a day inside its round, is
  filed by someone on the locked member list, and a vote is never a self-vote.
- **`memberships.rating` holds the current rating**, written only by round finalization;
  `rating_history` is the append-only audit log that proves how it got there.
  `round_members.rating_before` freezes the starting rating so re-running finalization applies a
  delta once rather than twice.
- **Activities are owned by a person, not a party.** The same workout counts in whichever round
  covers it, so visibility is decided by a shared round plus the round's time window rather than
  by a `party_id` column.

## Consequences

- Adding a table means adding its grants too, not only its policies. Two CI invariants catch a
  miss: every table in `public` has RLS and a policy, and no client write grant exists on a
  server-authoritative table.
- Every policy path is covered by a pgTAP suite that asserts exact SQLSTATEs, so a test says
  which layer refused a request rather than only that something did.
- Creating a party or joining one needs an Edge Function before PARTY-01 and PARTY-02 can ship;
  the client cannot do it with a plain insert.
- The activity read policy is a correlated subquery. At party sizes of 3 to 8 that is
  comfortable; if it ever is not, the scale path is a server-written `round_activities` join
  table, which would also make "which activities counted" auditable — not a weaker policy.
