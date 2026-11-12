# 0009 — Account deletion and historical results

- Status: accepted
- Date: 2026-11-12

## Context

AUTH-02 promises a real, complete deletion, and `docs/SECURITY.md` lists what goes: profile,
memberships' personal data, check-ins, photos, step summaries and activities. It does not list
weekly results, ratings or cards, and for good reason — they belong to a whole party, not to one
person.

The obvious schema, every table pointing at `auth.users` with `on delete cascade`, quietly
breaks that. Deleting one account would punch holes in finished rounds: `N` would change
retroactively, a past leaderboard would lose a row, and a card someone already shared would have
no owner. The choice of foreign key is therefore not a detail to settle later; it shapes every
table, and changing it afterwards means rewriting history that by then exists.

## Decision

- **A profile is the durable identity and has no foreign key to `auth.users`.** It is created by
  a trigger when an auth user appears, and it survives deletion as an anonymised tombstone:
  `deleted_at` set, `display_name` replaced, `avatar_path` cleared.
- **Personal data cascades from `auth.users`:** `memberships`, `daily_step_summaries`,
  `activities`, `checkins`, `votes`, `reactions`, `reports`. Deleting the auth user removes all
  of it, even if the deletion job is interrupted halfway.
- **Historical results reference `profiles` with `on delete restrict`:** `round_members`,
  `daily_points`, `weekly_results`, `rating_history`, `cards`. A finished round keeps its full
  member list and its places.
- **Account deletion is an Edge Function** that anonymises the profile, then deletes the auth
  user. Photos in the private bucket are removed explicitly, because storage objects have no
  foreign key to follow.
- **Activity cards go with the workout.** They cascade from `activities`, so they are deleted
  with the rest of the personal data; weekly cards stay.

## Consequences

- Someone who deletes their account still appears in past leaderboards and on other people's
  cards, as an anonymous former member. That is the honest outcome: the week really did have
  that many players, and other people's results depend on it. It needs saying plainly in the
  deletion screen and in the privacy notice before release.
- The tombstone holds no personal data — an opaque id, a generic label and timestamps — so it is
  not a way of keeping a deleted user's information.
- `profiles` needs the trigger on `auth.users` to stay in place; a future change to Supabase Auth
  that skips it would leave users without a profile. A pgTAP test covers it.
- Restoring an account is not supported. Signing in again creates a new identity with a new
  rating in every party.
