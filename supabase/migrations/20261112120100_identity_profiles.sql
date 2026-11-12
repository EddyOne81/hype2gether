-- A profile is the durable identity of a person inside a party.
--
-- It deliberately has no foreign key to `auth.users`: deleting an account removes the auth
-- user and every row of personal data, but finalized results, ratings and cards must keep
-- pointing at someone. Account deletion anonymises the profile instead of removing it
-- (docs/adr/0009).

create table public.profiles (
  id uuid primary key,
  display_name text not null,
  avatar_path text,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (char_length(btrim(display_name)) between 1 and 40),
  constraint profiles_avatar_path_length check (avatar_path is null or char_length(avatar_path) between 1 and 400),
  constraint profiles_deleted_has_no_avatar check (deleted_at is null or avatar_path is null)
);

comment on table public.profiles is
  'One row per person. Survives account deletion as an anonymised tombstone so historical results stay readable.';
comment on column public.profiles.deleted_at is
  'Set when the account was deleted. The row is kept only to anchor finalized results, ratings and cards.';

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function app.set_updated_at();

alter table public.profiles enable row level security;

-- Every authenticated user gets a profile. Sign in with Apple only reveals a name on the very
-- first sign-in, so it is taken here and the user can change it afterwards.
create function app.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(btrim(left(new.raw_user_meta_data ->> 'full_name', 40)), ''), 'New member')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_auth_user();
