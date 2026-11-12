# 0007 — Walking cards and step sources

- Status: accepted
- Date: 2026-11-12

## Context

Many users walk every day rather than run or ride, and want to share a walk the same way. Step counts also differ between devices: a phone in a pocket, a phone in hand and a watch do not count the same, and other brands will differ more once Android ships.

## Decision

- Read recorded walking workouts from Apple Health and give each one an activity card, like runs and rides.
- Walking keeps scoring through steps only; walk distance never adds points, so scoring rule v2 and `RULE_VERSION` do not change.
- Do not calibrate steps per device. Show each member's step source on the leaderboard instead.
- The server flags days with more than 60,000 steps for the party to see. A flag never changes points by itself; members can open a dispute, which keeps the round provisional.
- Before shipping Android, decide in a new ADR how to keep parties with mixed devices fair, using pilot data.

## Consequences

- `activities.sport` accepts `walk`; the scoring engine treats walks like runs (no ride distance).
- `daily_points` gains `flags`; the leaderboard and STEP-02 show flagged days.
- The 60,000-step threshold is a first guess, tuned after the pilot.
