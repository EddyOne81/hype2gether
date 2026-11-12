-- What a signed-in member may and may not submit: their own facts, for themselves, before the
-- deadline. Deadlines come from docs/PRODUCT_BRIEF.md ("Fairness and data rules") and are
-- enforced here rather than in the app, so a modified client gains nothing.
begin;

create extension if not exists pgtap with schema extensions;

select plan(15);

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
-- One running round, and one round that ended 13 hours ago: past the 12 hour step deadline
-- but not yet finalized, which is exactly the state a late sync would arrive in.

insert into auth.users (id, email) values
  ('d0000000-0000-4000-8000-000000000001', 'walker-one@example.test'),
  ('d0000000-0000-4000-8000-000000000002', 'walker-two@example.test'),
  ('d0000000-0000-4000-8000-000000000003', 'walker-three@example.test'),
  ('d0000000-0000-4000-8000-000000000009', 'stranger@example.test');

insert into public.parties (id, name, timezone, created_by) values
  ('d0000000-0000-4000-8000-00000000000a', 'Live Party', 'Asia/Ho_Chi_Minh',
   'd0000000-0000-4000-8000-000000000001'),
  ('d0000000-0000-4000-8000-00000000000f', 'Late Party', 'Asia/Ho_Chi_Minh',
   'd0000000-0000-4000-8000-000000000001');

insert into public.memberships (party_id, user_id) values
  ('d0000000-0000-4000-8000-00000000000a', 'd0000000-0000-4000-8000-000000000001'),
  ('d0000000-0000-4000-8000-00000000000a', 'd0000000-0000-4000-8000-000000000002'),
  ('d0000000-0000-4000-8000-00000000000a', 'd0000000-0000-4000-8000-000000000003'),
  ('d0000000-0000-4000-8000-00000000000f', 'd0000000-0000-4000-8000-000000000001');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version) values
  ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-00000000000a',
   now() - interval '1 day', now() + interval '6 days', 'Asia/Ho_Chi_Minh', 2),
  ('d0000000-0000-4000-8000-00000000000e', 'd0000000-0000-4000-8000-00000000000f',
   now() - interval '7 days' - interval '13 hours', now() - interval '13 hours',
   'Asia/Ho_Chi_Minh', 2);

insert into public.round_members (round_id, user_id, rating_before) values
  ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000001', 1000),
  ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000002', 1000),
  ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000003', 1000),
  ('d0000000-0000-4000-8000-00000000000e', 'd0000000-0000-4000-8000-000000000001', 1000);

-- Steps -----------------------------------------------------------------------

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
  values ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000001',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 7000, 'iPhone')
$q$), null, 'a member syncs their own steps');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
  values ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000001',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 9100, 'Apple Watch')
  on conflict (round_id, user_id, day) do update
    set steps = excluded.steps, source = excluded.source, synced_at = now()
$q$), null, 'a re-sync upserts the same day');

select is(
  (select count(*) from public.daily_step_summaries
   where round_id = 'd0000000-0000-4000-8000-00000000000b'),
  1::bigint,
  'a re-sync never double-counts: still one row for that day'
);

select is(
  (select steps from public.daily_step_summaries
   where round_id = 'd0000000-0000-4000-8000-00000000000b'),
  9100,
  'the re-sync replaced the day total instead of adding to it'
);

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_step_summaries (round_id, user_id, day, steps)
  values ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000002',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 30000)
$q$), '42501', 'a member cannot sync steps on behalf of someone else');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001', $q$
  insert into public.daily_step_summaries (round_id, user_id, day, steps)
  values ('d0000000-0000-4000-8000-00000000000e', 'd0000000-0000-4000-8000-000000000001',
          app.day_in_timezone(now() - interval '2 days', 'Asia/Ho_Chi_Minh'), 30000)
$q$), '42501', 'steps cannot be synced more than 12 hours after a round ends');

-- Check-ins and votes -------------------------------------------------------------

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001', $q$
  insert into public.checkins (id, round_id, user_id, day, photo_path)
  values ('d0000000-0000-4000-8000-00000000000c', 'd0000000-0000-4000-8000-00000000000b',
          'd0000000-0000-4000-8000-000000000001', app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'),
          'd0000000-0000-4000-8000-00000000000a/d0000000-0000-4000-8000-00000000000b/d0000000-0000-4000-8000-000000000001/p.jpg')
$q$), null, 'a member checks in for themselves');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000002', $q$
  insert into public.checkins (round_id, user_id, day, photo_path)
  values ('d0000000-0000-4000-8000-00000000000b', 'd0000000-0000-4000-8000-000000000003',
          app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'),
          'd0000000-0000-4000-8000-00000000000a/d0000000-0000-4000-8000-00000000000b/d0000000-0000-4000-8000-000000000003/p.jpg')
$q$), '42501', 'a member cannot check in on behalf of someone else');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000002',
  $q$insert into public.votes (checkin_id, voter_id)
     values ('d0000000-0000-4000-8000-00000000000c', 'd0000000-0000-4000-8000-000000000002')$q$),
  null, 'a member verifies someone else''s check-in');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000001',
  $q$insert into public.votes (checkin_id, voter_id)
     values ('d0000000-0000-4000-8000-00000000000c', 'd0000000-0000-4000-8000-000000000001')$q$),
  '23514', 'a check-in cannot be verified by its own author');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000002',
  $q$insert into public.votes (checkin_id, voter_id)
     values ('d0000000-0000-4000-8000-00000000000c', 'd0000000-0000-4000-8000-000000000002')$q$),
  '23505', 'a voter cannot verify the same check-in twice');

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000009',
  $q$insert into public.votes (checkin_id, voter_id)
     values ('d0000000-0000-4000-8000-00000000000c', 'd0000000-0000-4000-8000-000000000009')$q$),
  '23503', 'someone outside the locked member list cannot verify a check-in');

-- Reporting hides the item for the reporter, straight away ------------------------

select is(pg_temp.write_as('d0000000-0000-4000-8000-000000000002', $q$
  insert into public.reports (target_type, target_id, reporter_id, reason)
  values ('checkin', 'd0000000-0000-4000-8000-00000000000c',
          'd0000000-0000-4000-8000-000000000002', 'Test report')
$q$), null, 'a member reports a check-in they can see');

select is(
  pg_temp.visible_to('d0000000-0000-4000-8000-000000000002',
    $q$select 1 from public.checkins where id = 'd0000000-0000-4000-8000-00000000000c'$q$),
  0::bigint,
  'the reported check-in disappears for the reporter'
);

select is(
  pg_temp.visible_to('d0000000-0000-4000-8000-000000000003',
    $q$select 1 from public.checkins where id = 'd0000000-0000-4000-8000-00000000000c'$q$),
  1::bigint,
  'the reported check-in is still visible to everyone else'
);

select * from finish();

rollback;
