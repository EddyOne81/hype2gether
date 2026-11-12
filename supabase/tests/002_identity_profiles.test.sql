-- docs/adr/0009: a profile is the durable identity, created with the auth user and kept as an
-- anonymised tombstone when the account goes, so finished rounds keep their member list.
begin;

create extension if not exists pgtap with schema extensions;

select plan(5);

insert into auth.users (id, email, raw_user_meta_data) values
  ('e0000000-0000-4000-8000-000000000001', 'fresh@example.test', '{"full_name": "Fresh Member"}'),
  ('e0000000-0000-4000-8000-000000000002', 'nameless@example.test', '{}');

select is(
  (select display_name from public.profiles where id = 'e0000000-0000-4000-8000-000000000001'),
  'Fresh Member',
  'signing up creates a profile and takes the name the provider gave once'
);

select is(
  (select display_name from public.profiles where id = 'e0000000-0000-4000-8000-000000000002'),
  'New member',
  'a provider that reveals no name still gets a profile'
);

-- A party and a finished round that reference the member who is about to leave.
insert into public.parties (id, name, timezone, created_by)
values ('e0000000-0000-4000-8000-00000000000a', 'Memory Party', 'Asia/Ho_Chi_Minh',
        'e0000000-0000-4000-8000-000000000001');

insert into public.memberships (party_id, user_id)
values ('e0000000-0000-4000-8000-00000000000a', 'e0000000-0000-4000-8000-000000000001');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version, status, finalized_at)
values ('e0000000-0000-4000-8000-00000000000b', 'e0000000-0000-4000-8000-00000000000a',
        now() - interval '8 days', now() - interval '1 day', 'Asia/Ho_Chi_Minh', 2,
        'final', now() - interval '12 hours');

insert into public.round_members (round_id, user_id, rating_before)
values ('e0000000-0000-4000-8000-00000000000b', 'e0000000-0000-4000-8000-000000000001', 1000);

insert into public.weekly_results (round_id, user_id, total_centipoints, place, delta_r, status, days_with_step_data, rule_version)
values ('e0000000-0000-4000-8000-00000000000b', 'e0000000-0000-4000-8000-000000000001',
        50000, 1, 20, 'final', 7, 2);

-- Account deletion: anonymise the profile, then remove the auth user.
update public.profiles
set display_name = 'Deleted member', avatar_path = null, deleted_at = now()
where id = 'e0000000-0000-4000-8000-000000000001';

delete from auth.users where id = 'e0000000-0000-4000-8000-000000000001';

select is(
  (select count(*) from public.memberships
   where user_id = 'e0000000-0000-4000-8000-000000000001'),
  0::bigint,
  'deleting the account takes the personal data with it'
);

select is(
  (select count(*) from public.weekly_results
   where round_id = 'e0000000-0000-4000-8000-00000000000b'),
  1::bigint,
  'a finished round keeps the result of a member who has left'
);

select is(
  (select display_name from public.profiles where id = 'e0000000-0000-4000-8000-000000000001'),
  'Deleted member',
  'the profile stays behind as an anonymous tombstone'
);

select * from finish();

rollback;
