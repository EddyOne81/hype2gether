-- A round is seven consecutive days in the party's time zone with a locked member list.
-- Rules never change mid-round, so each round stores the rule version it is played under and
-- the rating every member started it with. Clients can only read these tables, which is what
-- makes `rounds.status` unwritable from the app.

create table public.rounds (
  id uuid primary key default gen_random_uuid(),
  party_id uuid not null references public.parties (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  timezone text not null,
  rule_version integer not null,
  status public.round_status not null default 'active',
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rounds_ends_after_starts check (ends_at > starts_at),
  constraint rounds_rule_version_positive check (rule_version > 0),
  constraint rounds_finalized_at_matches_status
    check ((status = 'active') = (finalized_at is null)),
  -- A party plays one round at a time; consecutive rounds may touch but never overlap.
  constraint rounds_do_not_overlap
    exclude using gist (party_id with =, tstzrange(starts_at, ends_at, '[)') with &&)
);

comment on table public.rounds is
  'One competition week. status moves active -> provisional|final and is written only by round finalization.';
comment on column public.rounds.rule_version is
  'RULE_VERSION of packages/scoring at round start. Finalization refuses to score a round under a different version.';

create index rounds_party_starts_at_idx on public.rounds (party_id, starts_at desc);
create index rounds_active_ends_at_idx on public.rounds (ends_at) where status = 'active';

create trigger rounds_timezone_is_known
  before insert or update of timezone on public.rounds
  for each row execute function app.assert_valid_timezone();

create trigger rounds_set_updated_at
  before update on public.rounds
  for each row execute function app.set_updated_at();

alter table public.rounds enable row level security;

-- Locked member list ---------------------------------------------------------

create table public.round_members (
  round_id uuid not null references public.rounds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete restrict,
  rating_before integer not null,
  created_at timestamptz not null default now(),
  primary key (round_id, user_id),
  constraint round_members_rating_before_floor check (rating_before >= 0)
);

comment on table public.round_members is
  'The member list locked at round start. Someone who leaves the party stays in this list.';
comment on column public.round_members.rating_before is
  'Rating at round start. Stored so re-running finalization is idempotent instead of applying a delta twice.';

create index round_members_user_id_idx on public.round_members (user_id);

alter table public.round_members enable row level security;

-- Shared guards for round-scoped facts ---------------------------------------

-- A fact may only be filed against a day that belongs to its round, in the party's time zone.
create function app.assert_day_in_round()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  select starts_at, ends_at, timezone into r
  from public.rounds
  where id = new.round_id;
  if not found then
    raise exception 'Unknown round %', new.round_id using errcode = '23503';
  end if;
  if new.day < app.day_in_timezone(r.starts_at, r.timezone)
     or new.day > app.day_in_timezone(r.ends_at - interval '1 microsecond', r.timezone) then
    raise exception 'Day % is outside round %', new.day, new.round_id using errcode = '22023';
  end if;
  return new;
end;
$$;

-- A fact may only be filed by someone on the round's locked member list.
create function app.assert_round_membership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.round_members rm
    where rm.round_id = new.round_id and rm.user_id = new.user_id
  ) then
    raise exception 'User % is not on the locked member list of round %', new.user_id, new.round_id
      using errcode = '23503';
  end if;
  return new;
end;
$$;
