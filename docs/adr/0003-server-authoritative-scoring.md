# 0003 — Server-authoritative scoring in a pure shared package

- Status: accepted
- Date: 2026-11-12

## Context

Points, places and ratings decide who wins and what appears on shareable cards. If clients computed or wrote them, a modified client could cheat. Rules must also be identical wherever they are shown (app previews) and applied (server).

## Decision

- Clients submit raw facts only: daily step totals, check-ins, votes. Only server code computes and writes `daily_points`, `weekly_results`, `rating_history` and `cards`; RLS denies client writes to those tables.
- All formulas live in `packages/scoring`: pure TypeScript, zero runtime dependencies, fully unit-tested. App and Edge Functions import it; nothing re-implements a formula.
- `RULE_VERSION` is exported and stored on each round; any rule change bumps it.
- Points are integers in hundredths of a point (centipoints), rounded down. Totals and tie comparisons are exact, and nobody is ever awarded more than earned.
- Invalid votes never count: self-votes, duplicate votes and votes from outside the locked member list are discarded by the engine, in addition to database constraints.
- Ties use competition ranking (1, 1, 3); tied members share place and ΔR.
- A round is `final` only when every member has step data for all 7 days and no dispute is open; otherwise it is `provisional` and no rating changes.
- Finalization is deterministic and independent of input order, so re-running it is safe.

## Consequences

- The app can preview scores with the same code, but those previews are never trusted.
- Changing a rule is a code change plus a `RULE_VERSION` bump, reviewed like any other change; past rounds keep their stored version.
- Inputs are validated strictly (party size 3–8, non-negative integer steps, at most 7 days); bad data fails loudly instead of producing a wrong score.
