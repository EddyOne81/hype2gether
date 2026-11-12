-- Photo check-ins and the party votes that verify them (CHECK-01, CHECK-02).
--
-- The photo itself lives in the private `checkins` storage bucket; only its path is stored
-- here. Reactions are social only and never score.

create table public.checkins (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  photo_path text not null,
  created_at timestamptz not null default now(),
  constraint checkins_one_counted_per_day unique (round_id, user_id, day),
  constraint checkins_photo_path_length check (char_length(photo_path) between 1 and 400)
);

comment on table public.checkins is
  'One counted check-in per member per day. The photo is captured by camera and stored privately.';

create index checkins_round_day_idx on public.checkins (round_id, day);
create index checkins_user_id_idx on public.checkins (user_id);

create trigger checkins_day_in_round
  before insert or update of round_id, day on public.checkins
  for each row execute function app.assert_day_in_round();

create trigger checkins_member_is_locked_in
  before insert or update of round_id, user_id on public.checkins
  for each row execute function app.assert_round_membership();

alter table public.checkins enable row level security;

-- The photo path carries its own tenancy, so a storage policy can authorise an object
-- without reading this table: {party_id}/{round_id}/{user_id}/{file}.
create function app.assert_checkin_photo_path()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_party_id uuid;
begin
  select r.party_id into v_party_id
  from public.rounds r
  where r.id = new.round_id;
  if new.photo_path not like format('%s/%s/%s/%%', v_party_id, new.round_id, new.user_id) then
    raise exception 'Check-in photo path must start with {party_id}/{round_id}/{user_id}/'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

create trigger checkins_photo_path_is_tenant_scoped
  before insert or update of photo_path, round_id, user_id on public.checkins
  for each row execute function app.assert_checkin_photo_path();

-- Verify votes ---------------------------------------------------------------

create table public.votes (
  checkin_id uuid not null references public.checkins (id) on delete cascade,
  voter_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (checkin_id, voter_id)
);

comment on table public.votes is
  'One verify vote per voter per check-in. Self-votes and votes from outside the locked list are rejected.';

create index votes_voter_id_idx on public.votes (voter_id);

alter table public.votes enable row level security;

-- Enforced as a trigger as well as in RLS, so no writer, service role included, can
-- create a vote the scoring engine would have to discard.
create function app.assert_vote_allowed()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  c record;
begin
  select user_id, round_id into c
  from public.checkins
  where id = new.checkin_id;
  if not found then
    raise exception 'Unknown check-in %', new.checkin_id using errcode = '23503';
  end if;
  if c.user_id = new.voter_id then
    raise exception 'A check-in cannot be verified by its author' using errcode = '23514';
  end if;
  if not exists (
    select 1 from public.round_members rm
    where rm.round_id = c.round_id and rm.user_id = new.voter_id
  ) then
    raise exception 'Voter % is not on the locked member list of round %', new.voter_id, c.round_id
      using errcode = '23503';
  end if;
  return new;
end;
$$;

create trigger votes_are_castable
  before insert or update on public.votes
  for each row execute function app.assert_vote_allowed();

-- Reactions ------------------------------------------------------------------

create table public.reactions (
  checkin_id uuid not null references public.checkins (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  primary key (checkin_id, user_id, emoji),
  constraint reactions_emoji_length check (char_length(emoji) between 1 and 8)
);

comment on table public.reactions is 'Social only. Reactions never contribute to any score.';

create index reactions_user_id_idx on public.reactions (user_id);

alter table public.reactions enable row level security;
