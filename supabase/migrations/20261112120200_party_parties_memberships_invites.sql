-- Parties, their members and the invite codes that let people join.
-- `party_id` is the tenant key: every party-scoped row is reachable from one.
-- Clients never write these tables; Edge Functions do (CONTRIBUTING.md, engineering rule 1).

create table public.parties (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  timezone text not null default 'Asia/Ho_Chi_Minh',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint parties_name_length check (char_length(btrim(name)) between 1 and 60)
);

comment on table public.parties is 'A private group of close friends. Never publicly listable.';

create index parties_created_by_idx on public.parties (created_by);

create trigger parties_timezone_is_known
  before insert or update of timezone on public.parties
  for each row execute function app.assert_valid_timezone();

create trigger parties_set_updated_at
  before update on public.parties
  for each row execute function app.set_updated_at();

alter table public.parties enable row level security;

-- Memberships ---------------------------------------------------------------

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  party_id uuid not null references public.parties (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  rating integer not null default 1000,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  constraint memberships_one_row_per_member unique (party_id, user_id),
  constraint memberships_rating_floor check (rating >= 0),
  constraint memberships_left_after_joined check (left_at is null or left_at >= joined_at)
);

comment on table public.memberships is
  'Who belongs to a party now. Rows are removed with the account; finalized history lives elsewhere.';
comment on column public.memberships.rating is
  'Current rating in this party, written only by round finalization. `rating_history` is the audit log.';

create index memberships_user_id_idx on public.memberships (user_id);
create index memberships_active_party_idx on public.memberships (party_id) where left_at is null;

alter table public.memberships enable row level security;

-- A party holds at most MAX_PARTY_SIZE (8) active members (docs/PRODUCT_BRIEF.md).
-- The lower bound (3) is a round-start rule and is checked by the Edge Function.
create function app.assert_party_capacity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_active integer;
begin
  if new.left_at is not null then
    return new;
  end if;
  select count(*) into v_active
  from public.memberships m
  where m.party_id = new.party_id and m.left_at is null and m.id <> new.id;
  if v_active >= 8 then
    raise exception 'Party % already has the maximum of 8 active members', new.party_id
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger memberships_respect_capacity
  before insert or update of party_id, left_at on public.memberships
  for each row execute function app.assert_party_capacity();

-- Invites --------------------------------------------------------------------

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  party_id uuid not null references public.parties (id) on delete cascade,
  code text not null,
  created_by uuid not null references public.profiles (id) on delete restrict,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  constraint invites_code_unique unique (code),
  -- Six characters from an alphabet without 0/1/I/L/O, so a code read aloud is unambiguous.
  constraint invites_code_format check (code ~ '^[2-9A-HJKMNP-Z]{6}$')
);

comment on table public.invites is 'Server-generated join codes. Redeemed through an Edge Function, never read by anonymous clients.';

create index invites_party_id_idx on public.invites (party_id);
create index invites_created_by_idx on public.invites (created_by);

alter table public.invites enable row level security;
