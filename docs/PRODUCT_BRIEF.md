# Product brief — Hype2gether (MVP)

## Goal of the MVP

Prove two things with real users:

1. A group of close friends finishes a full week and starts another one.
2. Users export and share their card without being pushed.

## Target users (pilot)

Close-friend groups of 3–8 people, all on iPhone. Pilot via TestFlight. Many of them walk, run or ride and already record those workouts with Apple Watch, Apple Fitness, Strava, Garmin or similar apps.

## Core loops

- **Move loop:** see rank → walk, run or ride → steps and workouts sync → see progress.
- **Friend loop:** post a photo check-in → friends verify → recognition → come back.
- **Share loop:** finish a walk, a run, a ride or the week → receive a card → share → viewers join via invite code/link.

## MVP scope

In scope:

- Sign in, HealthKit permission, sync status ("synced / not synced yet")
- Two sports besides daily steps: **running** and **cycling**, read from workouts already recorded in Apple Health (the app does not record GPS itself). Recorded **walking** workouts are read too, for their cards only: walking already scores through steps
- Create or join a party via invite link or 6-character code
- Fixed rules per round; member list locked when a round starts
- Daily leaderboard
- Photo check-in (camera only, not gallery), verify votes, reactions (reactions never score)
- Weekly finalization, rating update, tier
- Cards: weekly winner card + weekly summary card for everyone + an activity card for each walk, run or ride; export 9:16 and 4:5
- Minimal solo mode (personal weekly card, no rank)
- Essential notifications, report content, leave party, delete account and data

Out of scope (do not build): public feed, full chat, matchmaking with strangers, other sports and health metrics (swimming, hiking, heart rate, calories…), in-app GPS recording, map tiles, direct Strava/Garmin API sync, money rewards, item shop, paid skins, regional kits, NFTs, Android build.

## Scoring rules — v2 (implement exactly; `RULE_VERSION = 2`)

Definitions: a **round** is 7 consecutive days in the party's time zone (default `Asia/Ho_Chi_Minh`). `N` = number of members locked at round start (3 ≤ N ≤ 8).

Daily points (max 100):

- `movementPoints = 80 × min(validSteps / 10000 + validRideKm / 30, 1)`: 30 km of cycling counts like 10,000 steps (both take about 1.5 h). The 30 km value is a starting point to calibrate after the pilot; changing it bumps `RULE_VERSION`.
- Running scores through steps: a run already adds its steps to the day's step total, so run distance never adds points (no double counting). Run distance is still shown on cards. The same applies to walking workouts.
- `validRideKm` is the day's total distance of valid rides (see Activity rules). Points are computed in integer centipoints and rounded down: `floor(8000 × min(3 × validSteps + validRideMetres, 30000) / 30000)`.
- `photoPoints = 20 × min(v / q, 1)` where `v` = valid verify votes on that day's counted check-in, `q = ceil((N − 1) / 2)`
- One counted check-in per member per day. One vote per voter per check-in. No self-votes. Missing votes give partial points, never negative points.
- The daily movement cap (10,000 steps or 30 km of riding) is a game-balance ceiling, not health advice. Always display real step counts and distances.

Weekly points = sum of the 7 daily totals. Equal totals share the same place.

Rating change after a finalized round:

- `ΔR = round(20 × (countLower − countHigher) / (N − 1))`, clamped to [−20, +20]; tied members get the same ΔR.
- Example, N = 5, all different totals: +20, +10, 0, −10, −20.
- Rating starts at 1000, floor 0. Rating is per party, not global.
- Tiers: Bronze < 1100, Silver 1100–1199, Gold 1200–1349, Platinum ≥ 1350.

Required test cases (from the brief):

- 8,000 steps + fully verified photo → 64 + 20 = 84 points.
- 4,000 steps + 15 km valid ride → 72 movement points.
- 2,000 steps + 60 km valid ride → 80 movement points (capped).
- 8,000 steps + 15 km manually entered ride → 64 movement points (the ride is not valid).
- Two overlapping valid rides of 20 km and 18 km → only 20 km counts.
- A ride at 45 km/h average → not valid.
- N = 5 → q = 2; 1 vote → 10 photo points; 2 votes → 20.
- 25,000 steps → 80 movement points, displayed steps still 25,000.
- N = 5 distinct totals → ΔR = +20/+10/0/−10/−20; ties share ΔR.

## Activity rules (walking, running and cycling)

- An activity is a walking, running or cycling workout read from Apple Health: type, start, end, duration, distance, source app/device and whether it was entered manually.
- An activity belongs to the day it **starts** on, in the party's time zone.
- A ride is **valid** for scoring only if all of these hold (checked on the server):
  - recorded by a device or app, not entered manually;
  - duration at least 10 minutes;
  - average speed at most 40 km/h (faster suggests a motor vehicle).
- Overlapping valid rides (the same ride recorded by two apps, for example) count once: within each group of rides that overlap in time, only the longest distance counts.
- Activities that are not valid still appear on cards with a truthful label ("Entered manually", "Not counted for points"), never hidden or silently scored.
- The GPS route never leaves the phone. The server stores the summary only. The activity card draws the route shape on a graphic background (no map tiles) and trims at least the first and last 300 m so start and end points (often home) are not shown.
- Data from a phone cannot be made tamper-proof. Server checks catch implausible data; party members can open a dispute, which keeps the round provisional.

## Fairness and data rules

- Missing step data shows "not synced yet", never 0.
- Step sync deadline: 12 h after the round ends. Votes close 24 h after the check-in is posted. Finalize only after both deadlines.
- Rating updates only if every member has 7 valid days and no dispute is open; otherwise results stay **provisional** and ratings are not changed for anyone.
- Step counts differ between devices (phone in a pocket or in hand, with or without a watch; other brands later). Nothing is calibrated per device: the leaderboard shows where each member's steps come from (for example "Apple Watch" or "iPhone"), so differences are visible.
- The server flags implausible days for the party to see, starting with more than 60,000 steps in a day. A flag never changes points by itself; members can open a dispute, which keeps the round provisional. The threshold is a starting value to tune after the pilot.
- Members who join mid-round wait for the next round. Members who leave stay in the current round's list.
- Rules never change mid-round.
- Labels must be truthful: "Steps synced", "Verified by party members", "Achievement in party". Never imply app-level verification of photos.

## Card content (prototype: modern sports style)

Weekly cards: identity (name, avatar), main achievement (place or title, rating once final), context (party name, place / N, round dates), evidence (total synced steps, km run, km ridden, days with data, verified check-ins), share footer (app name, optional invite code/QR). Provisional cards are labelled. Party name and photos can be hidden before export. Never auto-post.

Activity card (one per walk, run or ride): sport, trimmed route shape, distance, duration, pace (walk, run) or average speed (ride), date, labels from the activity rules, share footer. Same export formats and rules as weekly cards.

## Future works (do not build now; keep the data model open)

- Android: step counts differ between brands (Health Connect, Samsung Health and others). Decide in an ADR, using pilot data, how to keep parties with mixed devices fair before shipping Android.
- Limited regional card kits, HCMC first, keyed by **new ward code** (post-2025 administrative units), seasonal and serial-numbered (`#023/500`), earned only, never sold.
- Optional collectible/NFT later. Today: each card and kit grant has a serial, owner, evidence and image hash in Postgres.
