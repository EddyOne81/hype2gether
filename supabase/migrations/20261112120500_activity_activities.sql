-- Walking, running and cycling workout summaries read from Apple Health (ACT-01).
--
-- Summary only: no GPS route, no coordinates, no per-sample data. The route is read on the
-- device at card render time and never leaves the phone (docs/adr/0006, docs/SECURITY.md).
--
-- An activity belongs to a person, not to a party: the same workout counts in whichever round
-- covers it. Who may read one is decided by app.can_read_activity.

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  sport public.sport not null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  duration_s integer not null,
  distance_m integer not null,
  source text,
  source_workout_id text not null,
  user_entered boolean not null default false,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Re-syncing the same workout updates one row instead of adding another.
  constraint activities_one_row_per_workout unique (user_id, source_workout_id),
  constraint activities_ends_after_starts check (ended_at >= started_at),
  constraint activities_duration_range check (duration_s between 0 and 86400),
  constraint activities_distance_range check (distance_m between 0 and 1000000),
  -- Recorded duration cannot exceed the wall-clock span, give or take rounding.
  constraint activities_duration_within_span
    check (duration_s <= ceil(extract(epoch from (ended_at - started_at)))::integer + 60),
  constraint activities_source_length
    check (source is null or char_length(btrim(source)) between 1 and 80),
  constraint activities_source_workout_id_length
    check (char_length(btrim(source_workout_id)) between 1 and 200)
);

comment on table public.activities is
  'Workout summaries. Never store a route, a coordinate or a raw sample here.';
comment on column public.activities.user_entered is
  'True when the workout was typed in by hand. Such activities show on cards but never score.';
comment on column public.activities.source_workout_id is
  'Stable identifier from Apple Health, used to make re-syncing idempotent.';

create index activities_user_started_at_idx on public.activities (user_id, started_at desc);
create index activities_started_at_idx on public.activities (started_at);

create trigger activities_set_updated_at
  before update on public.activities
  for each row execute function app.set_updated_at();

alter table public.activities enable row level security;
