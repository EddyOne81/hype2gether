-- Everything the server computes: daily points, weekly results and rating history.
--
-- No client may write a single row here, and the database holds no formula. Values are
-- produced by `packages/scoring` inside an Edge Function and stored as-is, together with the
-- rule version they were produced under (docs/adr/0003, docs/adr/0008).
--
-- Points are stored in centipoints (hundredths of a point) because the engine computes in
-- integers and rounds down. The unit is in every column name on purpose: a column called
-- `movement_points` holding 8000 for 80 points is a bug waiting to happen.

create table public.daily_points (
  round_id uuid not null references public.rounds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete restrict,
  day date not null,
  movement_centipoints integer not null,
  photo_centipoints integer not null,
  total_centipoints integer generated always as (movement_centipoints + photo_centipoints) stored,
  counted_ride_metres integer not null default 0,
  flags public.point_flag[] not null default '{}',
  rule_version integer not null,
  computed_at timestamptz not null default now(),
  primary key (round_id, user_id, day),
  constraint daily_points_movement_non_negative check (movement_centipoints >= 0),
  constraint daily_points_photo_non_negative check (photo_centipoints >= 0),
  constraint daily_points_ride_metres_non_negative check (counted_ride_metres >= 0),
  constraint daily_points_rule_version_positive check (rule_version > 0)
);

comment on table public.daily_points is
  'Server-computed points for one member on one day. Recomputed in place, never appended to.';
comment on column public.daily_points.counted_ride_metres is
  'Ride distance that actually counted after validity and overlap rules. Kept as card evidence.';
comment on column public.daily_points.flags is
  'Plausibility flags shown to the party. A flag never changes points by itself.';

create index daily_points_round_day_idx on public.daily_points (round_id, day);
create index daily_points_user_id_idx on public.daily_points (user_id);

create trigger daily_points_day_in_round
  before insert or update of round_id, day on public.daily_points
  for each row execute function app.assert_day_in_round();

create trigger daily_points_member_is_locked_in
  before insert or update of round_id, user_id on public.daily_points
  for each row execute function app.assert_round_membership();

alter table public.daily_points enable row level security;

-- Weekly results -------------------------------------------------------------

create table public.weekly_results (
  round_id uuid not null references public.rounds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete restrict,
  total_centipoints integer not null,
  place integer not null,
  delta_r integer not null,
  status public.result_status not null,
  days_with_step_data smallint not null,
  rule_version integer not null,
  computed_at timestamptz not null default now(),
  primary key (round_id, user_id),
  constraint weekly_results_total_non_negative check (total_centipoints >= 0),
  constraint weekly_results_place_positive check (place >= 1),
  constraint weekly_results_days_non_negative check (days_with_step_data >= 0),
  constraint weekly_results_rule_version_positive check (rule_version > 0)
);

comment on table public.weekly_results is
  'One row per member per finished round. Provisional results carry delta_r = 0.';

create index weekly_results_round_place_idx on public.weekly_results (round_id, place);
create index weekly_results_user_id_idx on public.weekly_results (user_id);

create trigger weekly_results_member_is_locked_in
  before insert or update of round_id, user_id on public.weekly_results
  for each row execute function app.assert_round_membership();

alter table public.weekly_results enable row level security;

-- Rating history --------------------------------------------------------------

create table public.rating_history (
  id uuid primary key default gen_random_uuid(),
  party_id uuid not null references public.parties (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete restrict,
  round_id uuid not null references public.rounds (id) on delete cascade,
  rating_before integer not null,
  rating_after integer not null,
  created_at timestamptz not null default now(),
  constraint rating_history_one_row_per_round unique (round_id, user_id),
  constraint rating_history_before_non_negative check (rating_before >= 0),
  constraint rating_history_after_non_negative check (rating_after >= 0)
);

comment on table public.rating_history is
  'Append-only audit log of rating changes. memberships.rating holds the current value; this proves how it got there.';

create index rating_history_party_user_idx on public.rating_history (party_id, user_id, created_at desc);
create index rating_history_round_id_idx on public.rating_history (round_id);

-- A rating change is written once, when a round becomes final, and final is terminal.
-- Deletes stay possible so that removing a party or a round still cascades.
create trigger rating_history_is_append_only
  before update on public.rating_history
  for each row execute function app.reject_update();

alter table public.rating_history enable row level security;
