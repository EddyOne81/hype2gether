-- CONTRIBUTING.md engineering rule 4: a user reads a party's data only if they are a member.
--
-- The fixture fills every party-scoped table once, then looks at all of them through the eyes
-- of a signed-in user who belongs to no party. Positive controls at the end prove the rows
-- really are there, so the test cannot pass just because the fixture is empty.
begin;

create extension if not exists pgtap with schema extensions;

select plan(22);

-- Runs a query as a signed-in user and reports how many rows that user can see.
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
  ('a0000000-0000-4000-8000-000000000001', 'member-one@example.test'),
  ('a0000000-0000-4000-8000-000000000002', 'member-two@example.test'),
  ('a0000000-0000-4000-8000-000000000009', 'outsider@example.test');

insert into public.parties (id, name, timezone, created_by)
values ('a0000000-0000-4000-8000-00000000000a', 'Isolation Party', 'Asia/Ho_Chi_Minh',
        'a0000000-0000-4000-8000-000000000001');

insert into public.memberships (party_id, user_id) values
  ('a0000000-0000-4000-8000-00000000000a', 'a0000000-0000-4000-8000-000000000001'),
  ('a0000000-0000-4000-8000-00000000000a', 'a0000000-0000-4000-8000-000000000002');

insert into public.invites (party_id, code, created_by, expires_at)
values ('a0000000-0000-4000-8000-00000000000a', 'ZZ2345',
        'a0000000-0000-4000-8000-000000000001', now() + interval '7 days');

insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version)
values ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-00000000000a',
        now() - interval '1 day', now() + interval '6 days', 'Asia/Ho_Chi_Minh', 2);

insert into public.round_members (round_id, user_id, rating_before) values
  ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-000000000001', 1000),
  ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-000000000002', 1000);

insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
values ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-000000000001',
        app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 9000, 'Apple Watch');

insert into public.activities (user_id, sport, started_at, ended_at, duration_s, distance_m, source_workout_id)
values ('a0000000-0000-4000-8000-000000000001', 'ride', now() - interval '2 hours',
        now() - interval '1 hour', 3600, 20000, 'isolation-ride');

insert into public.checkins (id, round_id, user_id, day, photo_path)
values ('a0000000-0000-4000-8000-00000000000c', 'a0000000-0000-4000-8000-00000000000b',
        'a0000000-0000-4000-8000-000000000001', app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'),
        'a0000000-0000-4000-8000-00000000000a/a0000000-0000-4000-8000-00000000000b/a0000000-0000-4000-8000-000000000001/p.jpg');

insert into public.votes (checkin_id, voter_id)
values ('a0000000-0000-4000-8000-00000000000c', 'a0000000-0000-4000-8000-000000000002');

insert into public.reactions (checkin_id, user_id, emoji)
values ('a0000000-0000-4000-8000-00000000000c', 'a0000000-0000-4000-8000-000000000002', '🔥');

insert into public.daily_points (round_id, user_id, day, movement_centipoints, photo_centipoints, rule_version)
values ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-000000000001',
        app.day_in_timezone(now(), 'Asia/Ho_Chi_Minh'), 7200, 2000, 2);

insert into public.weekly_results (round_id, user_id, total_centipoints, place, delta_r, status, days_with_step_data, rule_version)
values ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-000000000001',
        9200, 1, 0, 'provisional', 1, 2);

insert into public.rating_history (party_id, user_id, round_id, rating_before, rating_after)
values ('a0000000-0000-4000-8000-00000000000a', 'a0000000-0000-4000-8000-000000000001',
        'a0000000-0000-4000-8000-00000000000b', 1000, 1010);

insert into public.cards (user_id, kind, round_id, rule_version)
values ('a0000000-0000-4000-8000-000000000001', 'weekly_summary',
        'a0000000-0000-4000-8000-00000000000b', 2);

-- The outsider ----------------------------------------------------------------

select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.parties'),
  0::bigint, 'an outsider sees no party');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.memberships'),
  0::bigint, 'an outsider sees no membership');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.invites'),
  0::bigint, 'an outsider sees no invite code');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.rounds'),
  0::bigint, 'an outsider sees no round');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.round_members'),
  0::bigint, 'an outsider sees no locked member list');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.daily_step_summaries'),
  0::bigint, 'an outsider sees no step summary');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.activities'),
  0::bigint, 'an outsider sees no activity');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.checkins'),
  0::bigint, 'an outsider sees no check-in');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.votes'),
  0::bigint, 'an outsider sees no vote');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.reactions'),
  0::bigint, 'an outsider sees no reaction');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.daily_points'),
  0::bigint, 'an outsider sees no daily points');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.weekly_results'),
  0::bigint, 'an outsider sees no weekly result');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.rating_history'),
  0::bigint, 'an outsider sees no rating history');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.cards'),
  0::bigint, 'an outsider sees no card');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.reports'),
  0::bigint, 'an outsider sees no report');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000009', 'select 1 from public.profiles'),
  1::bigint, 'an outsider sees only their own profile');

-- Positive controls: a member of the party does see the same rows -------------

select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.parties'),
  1::bigint, 'a member sees their party');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.daily_step_summaries'),
  1::bigint, 'a member sees the step summaries of their round');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.activities'),
  1::bigint, 'a member sees the activities of their round');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.daily_points'),
  1::bigint, 'a member sees the daily points of their round');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.rating_history'),
  1::bigint, 'a member sees the rating history of their party');
select is(pg_temp.visible_to('a0000000-0000-4000-8000-000000000002', 'select 1 from public.cards'),
  1::bigint, 'a member sees the cards of their round');

select * from finish();

rollback;
