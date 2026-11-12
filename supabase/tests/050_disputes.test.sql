-- An open dispute is what keeps a round provisional, so it has to be openable by exactly the
-- people the brief says, against something that actually counted, and resolvable only by the
-- server.
begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

create function pg_temp.write_as(p_user uuid, p_statement text) returns text
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  execute p_statement;
  execute 'reset role';
  return null;
exception
  when others then
    execute 'reset role';
    return sqlstate;
end;
$$;

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

insert into auth.users (id, email) values
  ('f0000000-0000-4000-8000-000000000001', 'disputer@example.test'),
  ('f0000000-0000-4000-8000-000000000002', 'disputed@example.test'),
  ('f0000000-0000-4000-8000-000000000009', 'bystander@example.test');

insert into public.parties (id, name, timezone, created_by) values
  ('f0000000-0000-4000-8000-00000000000a', 'Dispute Party', 'Asia/Ho_Chi_Minh',
   'f0000000-0000-4000-8000-000000000001'),
  ('f0000000-0000-4000-8000-00000000000f', 'Quiet Party', 'Asia/Ho_Chi_Minh',
   'f0000000-0000-4000-8000-000000000009');

insert into public.memberships (party_id, user_id) values
  ('f0000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-000000000001'),
  ('f0000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-000000000002'),
  ('f0000000-0000-4000-8000-00000000000f', 'f0000000-0000-4000-8000-000000000009');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version) values
  ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-00000000000a',
   now() - interval '1 day', now() + interval '6 days', 'Asia/Ho_Chi_Minh', 2);

-- A round that has already been scored: the argument there is over.
insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version, status, finalized_at)
values ('f0000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-00000000000a',
        now() - interval '9 days', now() - interval '2 days', 'Asia/Ho_Chi_Minh', 2,
        'final', now() - interval '1 day');

insert into public.round_members (round_id, user_id, rating_before) values
  ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000001', 1000),
  ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000002', 1000),
  ('f0000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-000000000001', 1000),
  ('f0000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-000000000002', 1000);

-- The implausible day that is worth arguing about, and a workout from a different week.
insert into public.daily_step_summaries (id, round_id, user_id, day, steps, source)
values ('f0000000-0000-4000-8000-0000000000c1', 'f0000000-0000-4000-8000-00000000000b',
        'f0000000-0000-4000-8000-000000000002',
        app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 71000, 'iPhone');

insert into public.activities (id, user_id, sport, started_at, ended_at, duration_s, distance_m, source_workout_id)
values
  ('f0000000-0000-4000-8000-0000000000c2', 'f0000000-0000-4000-8000-000000000002', 'ride',
   now() - interval '2 hours', now() - interval '1 hour', 3600, 39000, 'dispute-ride'),
  ('f0000000-0000-4000-8000-0000000000c3', 'f0000000-0000-4000-8000-000000000002', 'ride',
   now() - interval '30 days', now() - interval '30 days' + interval '1 hour', 3600, 20000,
   'dispute-old-ride');

-- Opening a dispute ------------------------------------------------------------

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000001',
          'daily_step_summary', 'f0000000-0000-4000-8000-0000000000c1', 'That is a lot of steps')
$q$), null, 'a locked-in member disputes a flagged day');

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000001',
          'activity', 'f0000000-0000-4000-8000-0000000000c2', 'Looks motorised')
$q$), null, 'a member disputes a ride that counted in the round');

select is(
  (select count(*) from public.disputes
   where round_id = 'f0000000-0000-4000-8000-00000000000b' and status = 'open'),
  2::bigint,
  'the round now has open disputes, which is what keeps it provisional'
);

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000001',
          'daily_step_summary', 'f0000000-0000-4000-8000-0000000000c1', 'Still a lot')
$q$), '23505', 'the same member cannot pile disputes onto the same target');

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000001',
          'activity', 'f0000000-0000-4000-8000-0000000000c3', 'From another week')
$q$), '23503', 'a dispute cannot point at something that never counted in the round');

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000009', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000009',
          'daily_step_summary', 'f0000000-0000-4000-8000-0000000000c1', 'Not my party')
$q$), '42501', 'someone outside the round cannot dispute it');

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  insert into public.disputes (round_id, opened_by, target_type, target_id, reason)
  values ('f0000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-000000000002',
          'daily_step_summary', 'f0000000-0000-4000-8000-0000000000c1', 'Not mine to open')
$q$), '42501', 'a member cannot open a dispute in someone else''s name');

-- Settling it -------------------------------------------------------------------

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  update public.disputes set status = 'withdrawn'
  where target_id = 'f0000000-0000-4000-8000-0000000000c2'
$q$), null, 'the author can withdraw their own dispute');

select is(
  (select count(*) from public.disputes
   where target_id = 'f0000000-0000-4000-8000-0000000000c1' and status = 'resolved'),
  0::bigint,
  'resolving is not something a client did here'
);

select is(pg_temp.write_as('f0000000-0000-4000-8000-000000000001', $q$
  update public.disputes set status = 'resolved'
  where target_id = 'f0000000-0000-4000-8000-0000000000c1'
$q$), '42501', 'only the server resolves a dispute');

select * from finish();

rollback;
