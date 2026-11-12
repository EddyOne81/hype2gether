# 0006 — Running and cycling with scoring rule v2

- Status: accepted
- Date: 2026-11-12

## Context

The product is inspired by Strava and similar apps, where people share their runs and rides. Users should be able to share a run or a ride as a Hype2gether card, and both sports should count in the party competition. Rule v1 scores steps only, so cyclists score almost nothing. A route reveals where people live and train, and the brief so far forbids storing location.

## Decision

- Support two sports besides daily steps: running and cycling.
- Read workouts that are already recorded in Apple Health (Apple Watch, Apple Fitness, Strava, Garmin…). Do not record GPS in the app.
- Scoring rule v2 (`RULE_VERSION = 2`): `movementPoints = 80 × min(validSteps / 10000 + validRideKm / 30, 1)`. Running scores through steps, which already include the run, so run distance never adds points. Photo points, ranking, rating and tiers are unchanged. No round has been played under v1, so v1 is replaced rather than kept side by side.
- A ride counts only if it was recorded (not entered manually), lasts at least 10 minutes and averages at most 40 km/h; overlapping rides count once. The server applies these checks.
- The GPS route never leaves the phone. The server stores a summary per workout. Activity cards draw the route shape without map tiles and trim at least the first and last 300 m.
- Add an activity card for each run or ride, and show km run and km ridden on weekly cards.

## Consequences

- The `activities` table and the `ACT-01` and `CARD-03` features join the MVP; `daily_points.step_points` becomes `movement_points`.
- The HealthKit spike must also prove that workouts and their routes can be read, and from which source apps.
- 30 km per 10,000 steps and 40 km/h are first guesses; tuning them after the pilot is a rule change and bumps `RULE_VERSION`.
- Phone data cannot be made tamper-proof; plausibility checks on the server and party disputes are the guard rails, as for steps.
- Cards from devices without routes (treadmill runs, indoor rides) show the summary without a route.
