-- Cards issued from a finished round or a single workout (CARD-01, CARD-03).
--
-- The row is the record of issue: who earned it, under which rules, and a hash of the image
-- that was rendered. The image itself is rendered on the device and shared by the user.
-- Written by the server only.

create table public.cards (
  id uuid primary key default gen_random_uuid(),
  serial bigint generated always as identity,
  user_id uuid not null references public.profiles (id) on delete restrict,
  kind public.card_kind not null,
  round_id uuid references public.rounds (id) on delete cascade,
  activity_id uuid references public.activities (id) on delete cascade,
  rule_version integer not null,
  image_hash text,
  created_at timestamptz not null default now(),
  constraint cards_serial_unique unique (serial),
  -- A weekly card belongs to a round, an activity card to one workout. Never both, never neither.
  constraint cards_subject_matches_kind check (
    (kind = 'activity' and activity_id is not null and round_id is null)
    or (kind <> 'activity' and round_id is not null and activity_id is null)
  ),
  constraint cards_image_hash_format check (image_hash is null or image_hash ~ '^[0-9a-f]{64}$'),
  constraint cards_rule_version_positive check (rule_version > 0)
);

comment on table public.cards is
  'Issued cards. serial is reserved for the numbered, earned-only kits in docs/PRODUCT_BRIEF.md "Future works".';
comment on column public.cards.image_hash is
  'SHA-256 of the exported image, lowercase hex. Evidence that a shared card is the one that was issued.';

create index cards_user_created_at_idx on public.cards (user_id, created_at desc);
create index cards_round_id_idx on public.cards (round_id);
create index cards_activity_id_idx on public.cards (activity_id);

alter table public.cards enable row level security;
