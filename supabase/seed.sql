-- Local development seed. Fake data only: invented names, example.test addresses, no real
-- health data, no real photos (docs/SECURITY.md).
--
-- It lays out one finished round and one running round for the same party, so every table in
-- the model has something in it and the app has a leaderboard to render.
--
-- The values in daily_points, weekly_results and rating_history are illustrative fixtures,
-- not output of the scoring engine. Never treat them as an oracle: the engine's test cases
-- live in packages/scoring, and round finalization is what writes these tables for real.

do $$
declare
  v_linh constant uuid := '11111111-1111-4111-8111-111111111111';
  v_minh constant uuid := '22222222-2222-4222-8222-222222222222';
  v_an constant uuid := '33333333-3333-4333-8333-333333333333';
  v_thao constant uuid := '44444444-4444-4444-8444-444444444444';
  v_party constant uuid := 'aaaaaaaa-0000-4000-8000-aaaaaaaaaaaa';
  v_past_round constant uuid := 'bbbbbbbb-0000-4000-8000-bbbbbbbbbbbb';
  v_live_round constant uuid := 'cccccccc-0000-4000-8000-cccccccccccc';
  v_tz constant text := 'Asia/Ho_Chi_Minh';
  v_live_start timestamptz;
  v_past_start timestamptz;
  v_checkin uuid;
begin
  -- The running round started three local days ago, so the step and check-in windows are open.
  v_live_start := (date_trunc('day', (now() at time zone v_tz)) - interval '3 days') at time zone v_tz;
  v_past_start := v_live_start - interval '7 days';

  insert into auth.users (id, email)
  values
    (v_linh, 'linh@example.test'),
    (v_minh, 'minh@example.test'),
    (v_an, 'an@example.test'),
    (v_thao, 'thao@example.test');

  -- Profiles are created by the on_auth_user_created trigger; give them readable names.
  update public.profiles set display_name = 'Linh' where id = v_linh;
  update public.profiles set display_name = 'Minh' where id = v_minh;
  update public.profiles set display_name = 'An' where id = v_an;
  update public.profiles set display_name = 'Thao' where id = v_thao;

  insert into public.parties (id, name, timezone, created_by)
  values (v_party, 'Demo Party', v_tz, v_linh);

  -- Ratings below are where the finished round left everyone.
  insert into public.memberships (party_id, user_id, rating)
  values
    (v_party, v_linh, 1020),
    (v_party, v_minh, 1007),
    (v_party, v_an, 993),
    (v_party, v_thao, 980);

  insert into public.invites (party_id, code, created_by, expires_at)
  values (v_party, 'H2G7KM', v_linh, now() + interval '7 days');

  -- Finished round ------------------------------------------------------------

  insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version, status, finalized_at)
  values (v_past_round, v_party, v_past_start, v_live_start, v_tz, 2, 'final', v_live_start + interval '36 hours');

  insert into public.round_members (round_id, user_id, rating_before)
  values
    (v_past_round, v_linh, 1000),
    (v_past_round, v_minh, 1000),
    (v_past_round, v_an, 1000),
    (v_past_round, v_thao, 1000);

  insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
  select
    v_past_round,
    m.user_id,
    d::date,
    m.steps,
    m.source
  from (values
    (v_linh, 11200, 'Apple Watch'),
    (v_minh, 8600, 'iPhone'),
    (v_an, 6100, 'iPhone'),
    (v_thao, 5200, 'Apple Watch')
  ) as m (user_id, steps, source)
  cross join generate_series(
    app.day_in_timezone(v_past_start, v_tz),
    app.day_in_timezone(v_live_start - interval '1 microsecond', v_tz),
    interval '1 day'
  ) as d;

  insert into public.daily_points (round_id, user_id, day, movement_centipoints, photo_centipoints, rule_version)
  select
    v_past_round,
    m.user_id,
    d::date,
    m.movement,
    case when d::date - app.day_in_timezone(v_past_start, v_tz) < m.photo_days then m.photo else 0 end,
    2
  from (values
    (v_linh, 8000, 2000, 3),
    (v_minh, 6400, 2000, 2),
    (v_an, 4800, 0, 0),
    (v_thao, 4000, 1000, 1)
  ) as m (user_id, movement, photo, photo_days)
  cross join generate_series(
    app.day_in_timezone(v_past_start, v_tz),
    app.day_in_timezone(v_live_start - interval '1 microsecond', v_tz),
    interval '1 day'
  ) as d;

  -- Places and rating deltas for four members with distinct totals: +20, +7, -7, -20.
  insert into public.weekly_results (round_id, user_id, total_centipoints, place, delta_r, status, days_with_step_data, rule_version)
  select
    v_past_round,
    p.user_id,
    sum(p.total_centipoints)::integer,
    r.place,
    r.delta_r,
    'final',
    7,
    2
  from public.daily_points p
  join (values
    (v_linh, 1, 20),
    (v_minh, 2, 7),
    (v_an, 3, -7),
    (v_thao, 4, -20)
  ) as r (user_id, place, delta_r) on r.user_id = p.user_id
  where p.round_id = v_past_round
  group by p.user_id, r.place, r.delta_r;

  insert into public.rating_history (party_id, user_id, round_id, rating_before, rating_after)
  select v_party, w.user_id, v_past_round, 1000, 1000 + w.delta_r
  from public.weekly_results w
  where w.round_id = v_past_round;

  insert into public.cards (user_id, kind, round_id, rule_version)
  select w.user_id,
         case when w.place = 1 then 'weekly_winner'::public.card_kind else 'weekly_summary'::public.card_kind end,
         v_past_round,
         2
  from public.weekly_results w
  where w.round_id = v_past_round;

  -- Running round --------------------------------------------------------------

  insert into public.rounds (id, party_id, starts_at, ends_at, timezone, rule_version, status)
  values (v_live_round, v_party, v_live_start, v_live_start + interval '7 days', v_tz, 2, 'active');

  insert into public.round_members (round_id, user_id, rating_before)
  select v_live_round, m.user_id, m.rating
  from public.memberships m
  where m.party_id = v_party;

  -- Three days of steps. Thao has synced only two: the third day must read
  -- "not synced yet", never 0. Linh has one implausible day for the flag to show.
  insert into public.daily_step_summaries (round_id, user_id, day, steps, source)
  values
    (v_live_round, v_linh, app.day_in_timezone(v_live_start, v_tz), 9800, 'Apple Watch'),
    (v_live_round, v_linh, app.day_in_timezone(v_live_start, v_tz) + 1, 63500, 'iPhone'),
    (v_live_round, v_linh, app.day_in_timezone(v_live_start, v_tz) + 2, 10400, 'Apple Watch'),
    (v_live_round, v_minh, app.day_in_timezone(v_live_start, v_tz), 7400, 'iPhone'),
    (v_live_round, v_minh, app.day_in_timezone(v_live_start, v_tz) + 1, 8100, 'iPhone'),
    (v_live_round, v_minh, app.day_in_timezone(v_live_start, v_tz) + 2, 5200, 'iPhone'),
    (v_live_round, v_an, app.day_in_timezone(v_live_start, v_tz), 4300, 'iPhone'),
    (v_live_round, v_an, app.day_in_timezone(v_live_start, v_tz) + 1, 3900, 'iPhone'),
    (v_live_round, v_an, app.day_in_timezone(v_live_start, v_tz) + 2, 6600, 'iPhone'),
    (v_live_round, v_thao, app.day_in_timezone(v_live_start, v_tz), 5100, 'Apple Watch'),
    (v_live_round, v_thao, app.day_in_timezone(v_live_start, v_tz) + 1, 4700, 'Apple Watch');

  -- Workout summaries, including the edge cases the engine has to reject or de-duplicate.
  insert into public.activities (user_id, sport, started_at, ended_at, duration_s, distance_m, source, source_workout_id, user_entered)
  values
    (v_minh, 'ride', v_live_start + interval '7 hours', v_live_start + interval '8 hours', 3600, 24000, 'Strava', 'demo-ride-valid', false),
    (v_minh, 'ride', v_live_start + interval '7 hours 10 minutes', v_live_start + interval '8 hours 5 minutes', 3300, 21000, 'Garmin', 'demo-ride-overlap', false),
    (v_an, 'ride', v_live_start + interval '1 day 6 hours', v_live_start + interval '1 day 6 hours 40 minutes', 2400, 15000, 'Health', 'demo-ride-manual', true),
    (v_an, 'ride', v_live_start + interval '2 days 6 hours', v_live_start + interval '2 days 6 hours 20 minutes', 1200, 15000, 'Strava', 'demo-ride-too-fast', false),
    (v_linh, 'run', v_live_start + interval '5 hours', v_live_start + interval '5 hours 45 minutes', 2700, 8200, 'Apple Watch', 'demo-run', false),
    (v_linh, 'walk', v_live_start + interval '1 day 11 hours', v_live_start + interval '1 day 11 hours 50 minutes', 3000, 4100, 'Apple Watch', 'demo-walk', false),
    (v_thao, 'ride', v_live_start + interval '9 hours', v_live_start + interval '9 hours 5 minutes', 300, 1800, 'Strava', 'demo-ride-too-short', false);

  -- One check-in, verified by two of the three other members.
  v_checkin := gen_random_uuid();
  insert into public.checkins (id, round_id, user_id, day, photo_path)
  values (
    v_checkin,
    v_live_round,
    v_linh,
    app.day_in_timezone(v_live_start, v_tz),
    format('%s/%s/%s/demo-checkin.jpg', v_party, v_live_round, v_linh)
  );

  insert into public.votes (checkin_id, voter_id)
  values (v_checkin, v_minh), (v_checkin, v_an);

  insert into public.reactions (checkin_id, user_id, emoji)
  values (v_checkin, v_thao, '🔥');
end;
$$;
