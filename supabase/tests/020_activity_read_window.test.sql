-- docs/ARCHITECTURE.md, access rules: "Members of a round can read the activities of the
-- round's members that start inside the round."
--
-- Activities are owned by a person, not by a party, so the window is what keeps a workout
-- from before someone joined — or from long after the round — private.
begin;

create extension if not exists pgtap with schema extensions;

select plan(8);

create function pg_temp.visible_to(p_user uuid, p_query text) returns bigint
language plpgsql as $$
declare
  n bigint;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  execute 'select count(*) from (' || p_query || ') as rows_visible' into n;
  execute 'reset role';
  return n;
end;
$$;

-- Fixture --------------------------------------------------------------------
-- m1 and m2 are locked into the round. m3 belongs to the party but joined after the round
-- started, so they wait for the next one. The outsider belongs to a different party.

insert into auth.users (id, email) values
  ('b0000000-0000-4000-8000-000000000001', 'runner-one@example.test'),
  ('b0000000-0000-4000-8000-000000000002', 'runner-two@example.test'),
  ('b0000000-0000-4000-8000-000000000003', 'latecomer@example.test'),
  ('b0000000-0000-4000-8000-000000000009', 'other-party@example.test');

insert into public.parties (id, name, timezone, created_by) values
  ('b0000000-0000-4000-8000-00000000000a', 'Window Party', 'Asia/Ho_Chi_Minh',
   'b0000000-0000-4000-8000-000000000001'),
  ('b0000000-0000-4000-8000-00000000000f', 'Another Party', 'Asia/Ho_Chi_Minh',
   'b0000000-0000-4000-8000-000000000009');

insert into public.memberships (party_id, user_id) values
  ('b0000000-0000-4000-8000-00000000000a', 'b0000000-0000-4000-8000-000000000001'),
  ('b0000000-0000-4000-8000-00000000000a', 'b0000000-0000-4000-8000-000000000002'),
  ('b0000000-0000-4000-8000-00000000000a', 'b0000000-0000-4000-8000-000000000003'),
  ('b0000000-0000-4000-8000-00000000000f', 'b0000000-0000-4000-8000-000000000009');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version)
values ('b0000000-0000-4000-8000-00000000000b', 'b0000000-0000-4000-8000-00000000000a',
        now() - interval '2 days', now() + interval '5 days', 'Asia/Ho_Chi_Minh', 2);

insert into public.round_members (round_id, user_id, rating_before) values
  ('b0000000-0000-4000-8000-00000000000b', 'b0000000-0000-4000-8000-000000000001', 1000),
  ('b0000000-0000-4000-8000-00000000000b', 'b0000000-0000-4000-8000-000000000002', 1000);

insert into public.activities (user_id, sport, started_at, ended_at, duration_s, distance_m, source_workout_id)
values
  ('b0000000-0000-4000-8000-000000000002', 'ride', now() - interval '3 hours',
   now() - interval '2 hours', 3600, 22000, 'window-inside'),
  ('b0000000-0000-4000-8000-000000000002', 'ride', now() - interval '10 days',
   now() - interval '10 days' + interval '1 hour', 3600, 21000, 'window-before'),
  ('b0000000-0000-4000-8000-000000000002', 'run', now() + interval '10 days',
   now() + interval '10 days' + interval '40 minutes', 2400, 7000, 'window-after'),
  ('b0000000-0000-4000-8000-000000000001', 'run', now() - interval '30 days',
   now() - interval '30 days' + interval '40 minutes', 2400, 6000, 'window-own-old');

-- Assertions ------------------------------------------------------------------

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000001',
    $q$select 1 from public.activities where source_workout_id = 'window-inside'$q$),
  1::bigint,
  'a round member reads a co-member activity that starts inside the round'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000001',
    $q$select 1 from public.activities where source_workout_id = 'window-before'$q$),
  0::bigint,
  'a co-member activity from before the round stays private'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000001',
    $q$select 1 from public.activities where source_workout_id = 'window-after'$q$),
  0::bigint,
  'a co-member activity from after the round stays private'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000001',
    $q$select 1 from public.activities where source_workout_id = 'window-own-old'$q$),
  1::bigint,
  'a user always reads their own activities, in or out of any round'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000003',
    $q$select 1 from public.activities where user_id = 'b0000000-0000-4000-8000-000000000002'$q$),
  0::bigint,
  'a party member who is not on the locked list reads no activity of the round'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000009',
    $q$select 1 from public.activities where user_id = 'b0000000-0000-4000-8000-000000000002'$q$),
  0::bigint,
  'someone from another party reads no activity'
);

select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000002',
    $q$select 1 from public.activities where user_id = 'b0000000-0000-4000-8000-000000000002'$q$),
  3::bigint,
  'the owner reads all of their own activities'
);

-- The same window governs step summaries through round membership, not through time.
select is(
  pg_temp.visible_to('b0000000-0000-4000-8000-000000000003',
    $q$select 1 from public.rounds where id = 'b0000000-0000-4000-8000-00000000000b'$q$),
  1::bigint,
  'a party member still sees the round they are waiting out'
);

select * from finish();

rollback;
