# Product brief — Hype2gether (MVP)

## Goal of the MVP

Prove two things with real users:

1. A group of close friends finishes a full week and starts another one.
2. Users export and share their card without being pushed.

## Target users (pilot)

Close-friend groups of 3–8 people, all on iPhone. Pilot via TestFlight.

## Core loops

- **Move loop:** see rank → move → steps sync → see progress.
- **Friend loop:** post a photo check-in → friends verify → recognition → come back.
- **Share loop:** finish the week → receive a card → share → viewers join via invite code/link.

## MVP scope

In scope:

- Sign in, HealthKit permission, sync status ("synced / not synced yet")
- Create or join a party via invite link or 6-character code
- Fixed rules per round; member list locked when a round starts
- Daily leaderboard
- Photo check-in (camera only, not gallery), verify votes, reactions (reactions never score)
- Weekly finalization, rating update, tier
- Cards: weekly winner card + weekly summary card for everyone; export 9:16 and 4:5
- Minimal solo mode (personal weekly card, no rank)
- Essential notifications, report content, leave party, delete account and data

Out of scope (do not build): public feed, full chat, matchmaking with strangers, other health metrics, money rewards, item shop, paid skins, regional kits, NFTs, Android build.

## Scoring rules — v1 (implement exactly; `RULE_VERSION = 1`)

Definitions: a **round** is 7 consecutive days in the party's time zone (default `Asia/Ho_Chi_Minh`). `N` = number of members locked at round start (3 ≤ N ≤ 8).

Daily points (max 100):

- `stepPoints = 80 × min(validSteps / 10000, 1)`
- `photoPoints = 20 × min(v / q, 1)` where `v` = valid verify votes on that day's counted check-in, `q = ceil((N − 1) / 2)`
- One counted check-in per member per day. One vote per voter per check-in. No self-votes. Missing votes give partial points, never negative points.
- The 10,000-step cap is a game-balance ceiling, not health advice. Always display real step counts.

Weekly points = sum of the 7 daily totals. Equal totals share the same place.

Rating change after a finalized round:

- `ΔR = round(20 × (countLower − countHigher) / (N − 1))`, clamped to [−20, +20]; tied members get the same ΔR.
- Example, N = 5, all different totals: +20, +10, 0, −10, −20.
- Rating starts at 1000, floor 0. Rating is per party, not global.
- Tiers: Bronze < 1100, Silver 1100–1199, Gold 1200–1349, Platinum ≥ 1350.

Required test cases (from the brief):

- 8,000 steps + fully verified photo → 64 + 20 = 84 points.
- N = 5 → q = 2; 1 vote → 10 photo points; 2 votes → 20.
- 25,000 steps → 80 step points, displayed steps still 25,000.
- N = 5 distinct totals → ΔR = +20/+10/0/−10/−20; ties share ΔR.

## Fairness and data rules

- Missing step data shows "not synced yet", never 0.
- Step sync deadline: 12 h after the round ends. Votes close 24 h after the check-in is posted. Finalize only after both deadlines.
- Rating updates only if every member has 7 valid days and no dispute is open; otherwise results stay **provisional** and ratings are not changed for anyone.
- Members who join mid-round wait for the next round. Members who leave stay in the current round's list.
- Rules never change mid-round.
- Labels must be truthful: "Steps synced", "Verified by party members", "Achievement in party". Never imply app-level verification of photos.

## Card content (prototype: modern sports style)

Identity (name, avatar), main achievement (place or title, rating once final), context (party name, place / N, round dates), evidence (total synced steps, days with data, verified check-ins), share footer (app name, optional invite code/QR). Provisional cards are labelled. Party name and photos can be hidden before export. Never auto-post.

## Future works (do not build now; keep the data model open)

- Limited regional card kits, HCMC first, keyed by **new ward code** (post-2025 administrative units), seasonal and serial-numbered (`#023/500`), earned only, never sold.
- Optional collectible/NFT later. Today: each card and kit grant has a serial, owner, evidence and image hash in Postgres.
