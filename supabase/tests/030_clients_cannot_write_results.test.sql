-- CONTRIBUTING.md engineering rule 1 and docs/adr/0003: clients submit raw facts, and only
-- server code writes points, results, ratings and cards — or moves a round to another status.
--
-- Every attempt below must fail with 42501 (insufficient privilege), because the client roles
-- hold no write grant at all on these tables. A policy mistake alone could not open them.
begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

-- Runs a statement as a signed-in user. Returns null when it succeeded, or the SQLSTATE.
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

-- Fixture --------------------------------------------------------------------

insert into auth.users (id, email) values
  ('c0000000-0000-4000-8000-000000000001', 'cheater@example.test'),
  ('c0000000-0000-4000-8000-000000000002', 'teammate@example.test');

insert into public.parties (id, name, timezone, created_by)
values ('c0000000-0000-4000-8000-00000000000a', 'Write Party', 'Asia/Ho_Chi_Minh',
        'c0000000-0000-4000-8000-000000000001');

insert into public.memberships (party_id, user_id) values
  ('c0000000-0000-4000-8000-00000000000a', 'c0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-00000000000a', 'c0000000-0000-4000-8000-000000000002');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version)
values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-00000000000a',
        now() - interval '1 day', now() + interval '6 days', 'Asia/Ho_Chi_Minh', 2);

insert into public.round_members (round_id, user_id, rating_before) values
  ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000001', 1000),
  ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000002', 1000);

insert into public.daily_points (round_id, user_id, day, movement_centipoints, photo_centipoints, rule_version)
values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000001',
        app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 1000, 0, 2);

insert into public.rating_history (party_id, user_id, round_id, rating_before, rating_after)
values ('c0000000-0000-4000-8000-00000000000a', 'c0000000-0000-4000-8000-000000000001',
        'c0000000-0000-4000-8000-00000000000b', 1000, 1010);

-- Points, results, ratings, cards ----------------------------------------------

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_points (round_id, user_id, day, movement_centipoints, photo_centipoints, rule_version)
  values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000001',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh') + 1, 8000, 2000, 2)
$q$), '42501', 'a client cannot award itself daily points');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001',
  $q$update public.daily_points set movement_centipoints = 8000$q$),
  '42501', 'a client cannot raise stored daily points');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001',
  $q$delete from public.daily_points$q$),
  '42501', 'a client cannot erase daily points');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.weekly_results (round_id, user_id, total_centipoints, place, delta_r, status, days_with_step_data, rule_version)
  values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000001',
          70000, 1, 20, 'final', 7, 2)
$q$), '42501', 'a client cannot write a weekly result');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.rating_history (party_id, user_id, round_id, rating_before, rating_after)
  values ('c0000000-0000-4000-8000-00000000000a', 'c0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-00000000000b', 1000, 2000)
$q$), '42501', 'a client cannot append to the rating history');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001',
  $q$update public.rating_history set rating_after = 2000$q$),
  '42501', 'a client cannot rewrite the rating history');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.cards (user_id, kind, round_id, rule_version)
  values ('c0000000-0000-4000-8000-000000000001', 'weekly_winner',
          'c0000000-0000-4000-8000-00000000000b', 2)
$q$), '42501', 'a client cannot issue itself a card');

-- Round status and membership ----------------------------------------------------

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001',
  $q$update public.rounds set status = 'final', finalized_at = now()$q$),
  '42501', 'a client cannot finalize a round');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001',
  $q$update public.memberships set rating = 2000$q$),
  '42501', 'a client cannot change a rating directly');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.round_members (round_id, user_id, rating_before)
  values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000002', 5000)
$q$), '42501', 'a client cannot add anyone to a locked member list');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.parties (name, timezone, created_by)
  values ('Side Party', 'Asia/Ho_Chi_Minh', 'c0000000-0000-4000-8000-000000000001')
$q$), '42501', 'a client cannot create a party outside an Edge Function');

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.invites (party_id, code, created_by, expires_at)
  values ('c0000000-0000-4000-8000-00000000000a', 'QQ3456',
          'c0000000-0000-4000-8000-000000000001', now() + interval '1 day')
$q$), '42501', 'a client cannot mint an invite code');

-- Control: the same client can still submit the facts it owns ----------------------

select is(pg_temp.write_as('c0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
  values ('c0000000-0000-4000-8000-00000000000b', 'c0000000-0000-4000-8000-000000000001',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 9000, 'iPhone')
$q$), null, 'the same client can still sync its own steps');

select * from finish();

rollback;
