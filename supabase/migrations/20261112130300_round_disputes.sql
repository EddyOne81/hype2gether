-- Disputes (docs/PRODUCT_BRIEF.md, "Fairness and data rules").
--
-- Phone data cannot be made tamper-proof. The server flags implausible days and rejects
-- implausible rides, but the last guard rail is the party itself: any member of the locked
-- list can dispute a day or a workout, and an open dispute keeps the round provisional, so
-- nobody's rating moves until it is settled.
--
-- This is the table `finalizeRound(hasOpenDispute)` has always expected. Without it the
-- finalization function would have had to pass a constant and the guard rail would exist in
-- the brief only.

create type public.dispute_target as enum ('daily_step_summary', 'activity');
create type public.dispute_status as enum ('open', 'withdrawn', 'resolved');

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds (id) on delete cascade,
  -- Part of the party's history rather than private data: a dispute changes the outcome for
  -- everyone, so it outlives its author's account the way results do (docs/adr/0009).
  opened_by uuid not null references public.profiles (id) on delete restrict,
  target_type public.dispute_target not null,
  target_id uuid not null,
  reason text not null,
  status public.dispute_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint disputes_one_per_member_and_target unique (round_id, target_type, target_id, opened_by),
  constraint disputes_reason_length check (char_length(btrim(reason)) between 1 and 500)
);

comment on table public.disputes is
  'An open dispute keeps its round provisional. target_id is not a foreign key so more target types can be added later.';
comment on column public.disputes.status is
  'Only the author may withdraw. Resolving is a server decision, like every other round outcome.';

create index disputes_round_idx on public.disputes (round_id);
create index disputes_open_round_idx on public.disputes (round_id) where status = 'open';
create index disputes_target_idx on public.disputes (target_type, target_id);
create index disputes_opened_by_idx on public.disputes (opened_by);

create trigger disputes_set_updated_at
  before update on public.disputes
  for each row execute function app.set_updated_at();

alter table public.disputes enable row level security;

-- A dispute has to point at something that actually counted in this round, or finalization
-- would stall on an argument about data that was never scored.
create function app.assert_dispute_target()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  select starts_at, ends_at into r from public.rounds where id = new.round_id;
  if not found then
    raise exception 'Unknown round %', new.round_id using errcode = '23503';
  end if;

  if new.target_type = 'daily_step_summary' then
    if not exists (
      select 1 from public.daily_step_summaries s
      where s.id = new.target_id and s.round_id = new.round_id
    ) then
      raise exception 'Step summary % does not belong to round %', new.target_id, new.round_id
        using errcode = '23503';
    end if;
  else
    if not exists (
      select 1
      from public.activities a
      join public.round_members rm on rm.user_id = a.user_id and rm.round_id = new.round_id
      where a.id = new.target_id
        and a.started_at >= r.starts_at
        and a.started_at < r.ends_at
    ) then
      raise exception 'Activity % did not count in round %', new.target_id, new.round_id
        using errcode = '23503';
    end if;
  end if;

  return new;
end;
$$;

create trigger disputes_target_counted_in_the_round
  before insert or update of round_id, target_type, target_id on public.disputes
  for each row execute function app.assert_dispute_target();

-- A round can be disputed until it is final. Once ratings have moved, the argument is over.
create function app.round_is_disputable(p_round_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.rounds r
    where r.id = p_round_id and r.status <> 'final'
  );
$$;

grant execute on function app.round_is_disputable(uuid) to authenticated, service_role;

-- Supabase grants the Data API roles access to every newly created table, so each new table
-- has to take `anon` back out itself. The grant invariant in supabase/tests catches a miss.
revoke all on public.disputes from anon;

-- Clients open and withdraw their own disputes; only the server resolves one.
grant select, insert, update on public.disputes to authenticated;

create policy "disputes are visible to the whole round"
  on public.disputes for select to authenticated
  using (app.can_read_round(round_id));

create policy "a locked-in member opens a dispute until the round is final"
  on public.disputes for insert to authenticated
  with check (
    opened_by = (select auth.uid())
    and app.is_round_member(round_id)
    and app.round_is_disputable(round_id)
    and status = 'open'
  );

create policy "the author withdraws their own dispute"
  on public.disputes for update to authenticated
  using (opened_by = (select auth.uid()) and app.round_is_disputable(round_id))
  with check (
    opened_by = (select auth.uid())
    and status in ('open', 'withdrawn')
  );

-- The party should see a dispute appear, because it is why their round is still provisional.
alter publication supabase_realtime add table public.disputes;
