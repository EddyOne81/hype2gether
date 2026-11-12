-- Tables the leaderboard subscribes to (LEAD-01).
--
-- Realtime applies the same row level security as a normal read, so a subscriber only ever
-- receives changes to rows they could have selected. Postgres Changes is enough for parties
-- of 3 to 8; if a future scale makes it expensive, the replacement is broadcast from the
-- database, not a weaker policy.

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end;
$$;

alter publication supabase_realtime add table public.daily_points;
alter publication supabase_realtime add table public.weekly_results;
alter publication supabase_realtime add table public.daily_step_summaries;
alter publication supabase_realtime add table public.checkins;
alter publication supabase_realtime add table public.votes;
