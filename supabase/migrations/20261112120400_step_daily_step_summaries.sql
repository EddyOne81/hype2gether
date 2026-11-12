-- Daily step totals, one row per member per day of a round (STEP-02).
--
-- Only per-day totals are stored: never a raw HealthKit sample, never a timestamped series.
-- Re-syncing upserts the same row, so a re-sync can never double-count.

create table public.daily_step_summaries (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  steps integer not null,
  source text,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_step_summaries_one_row_per_day unique (round_id, user_id, day),
  constraint daily_step_summaries_steps_range check (steps between 0 and 500000),
  constraint daily_step_summaries_source_length
    check (source is null or char_length(btrim(source)) between 1 and 80)
);

comment on table public.daily_step_summaries is
  'Per-day step totals as synced from Apple Health. A missing row means not synced yet, never zero.';
comment on column public.daily_step_summaries.source is
  'Device or app the steps came from, for example Apple Watch or iPhone. Shown on the leaderboard, never used to calibrate.';

create index daily_step_summaries_round_day_idx on public.daily_step_summaries (round_id, day);
create index daily_step_summaries_user_id_idx on public.daily_step_summaries (user_id);

create trigger daily_step_summaries_day_in_round
  before insert or update of round_id, day on public.daily_step_summaries
  for each row execute function app.assert_day_in_round();

create trigger daily_step_summaries_member_is_locked_in
  before insert or update of round_id, user_id on public.daily_step_summaries
  for each row execute function app.assert_round_membership();

create trigger daily_step_summaries_set_updated_at
  before update on public.daily_step_summaries
  for each row execute function app.set_updated_at();

alter table public.daily_step_summaries enable row level security;
