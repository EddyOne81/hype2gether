-- Access control for the whole schema, in one reviewable place.
--
-- Two layers, on purpose:
--   * GRANTs decide what a role may attempt at all. Server-only tables carry no write grant
--     for any client role, so "the server decides" is structural, not just a policy.
--   * POLICIES decide which rows a client may see or write, and enforce the deadlines from
--     docs/PRODUCT_BRIEF.md.
--
-- Helpers are `security definer` so a policy can read membership tables without recursing
-- through those tables' own policies, and `set search_path = ''` so nothing can be shadowed.

-- Deadlines ------------------------------------------------------------------
-- Written once, here, so the two numbers in the brief appear exactly once in SQL.

create function app.step_sync_grace()
returns interval language sql immutable set search_path = '' as $$
  select interval '12 hours';
$$;

create function app.vote_window()
returns interval language sql immutable set search_path = '' as $$
  select interval '24 hours';
$$;

-- Membership helpers -----------------------------------------------------------

create function app.is_party_member(p_party_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.party_id = p_party_id
      and m.user_id = (select auth.uid())
      and m.left_at is null
  );
$$;

create function app.shares_party_with(p_user_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.memberships mine
    join public.memberships theirs on theirs.party_id = mine.party_id
    where mine.user_id = (select auth.uid())
      and mine.left_at is null
      and theirs.user_id = p_user_id
      and theirs.left_at is null
  );
$$;

create function app.is_round_member(p_round_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.round_members rm
    where rm.round_id = p_round_id and rm.user_id = (select auth.uid())
  );
$$;

-- Current members of the party see the round; someone who has left keeps access to the
-- rounds they are locked into, so they can still read the result they took part in.
create function app.can_read_round(p_round_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.rounds r
    where r.id = p_round_id and app.is_party_member(r.party_id)
  ) or app.is_round_member(p_round_id);
$$;

create function app.can_read_checkin(p_checkin_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.checkins c
    where c.id = p_checkin_id and app.can_read_round(c.round_id)
  );
$$;

-- An activity is visible to the people who shared a round with its owner, and only for the
-- stretch of time that round covers. Outside any shared round it stays private.
create function app.can_read_activity(p_user_id uuid, p_started_at timestamptz)
returns boolean language sql stable security definer set search_path = '' as $$
  select p_user_id = (select auth.uid())
    or exists (
      select 1
      from public.round_members mine
      join public.round_members theirs on theirs.round_id = mine.round_id
      join public.rounds r on r.id = mine.round_id
      where mine.user_id = (select auth.uid())
        and theirs.user_id = p_user_id
        and p_started_at >= r.starts_at
        and p_started_at < r.ends_at
    );
$$;

-- A reported item disappears for the person who reported it, straight away.
create function app.is_hidden_for_viewer(p_target_type public.report_target, p_target_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.reports rep
    where rep.target_type = p_target_type
      and rep.target_id = p_target_id
      and rep.reporter_id = (select auth.uid())
  );
$$;

-- Deadline helpers ---------------------------------------------------------------

create function app.steps_window_open(p_round_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.rounds r
    where r.id = p_round_id
      and now() >= r.starts_at
      and now() < r.ends_at + app.step_sync_grace()
  );
$$;

create function app.checkin_window_open(p_round_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.rounds r
    where r.id = p_round_id and now() >= r.starts_at and now() < r.ends_at
  );
$$;

create function app.vote_window_open(p_checkin_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.checkins c
    where c.id = p_checkin_id and now() < c.created_at + app.vote_window()
  );
$$;

revoke all on all functions in schema app from public;
grant execute on all functions in schema app to authenticated, service_role;

-- Grants -------------------------------------------------------------------------
-- Start from nothing, then hand out exactly what each client role needs. `anon` keeps no
-- table access at all: everything in this product requires a signed-in member.

revoke all on all tables in schema public from anon, authenticated;

grant select on
  public.profiles,
  public.parties,
  public.memberships,
  public.invites,
  public.rounds,
  public.round_members,
  public.daily_step_summaries,
  public.activities,
  public.checkins,
  public.votes,
  public.reactions,
  public.reports,
  public.daily_points,
  public.weekly_results,
  public.rating_history,
  public.cards
to authenticated;

-- The raw facts a client submits, and nothing else.
grant insert, update on public.profiles to authenticated;
grant insert, update on public.daily_step_summaries to authenticated;
grant insert, update, delete on public.activities to authenticated;
grant insert, delete on public.checkins to authenticated;
grant insert, delete on public.votes to authenticated;
grant insert, delete on public.reactions to authenticated;
grant insert on public.reports to authenticated;

-- Policies: identity ----------------------------------------------------------------

create policy "profiles are visible to the people you share a party with"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or app.shares_party_with(id));

create policy "a user creates only their own profile"
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()) and deleted_at is null);

create policy "a user edits only their own live profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()) and deleted_at is null)
  with check (id = (select auth.uid()) and deleted_at is null);

-- Policies: party ---------------------------------------------------------------------
-- Read-only for clients. Creating a party, issuing an invite, joining and leaving all go
-- through Edge Functions so the server stays the only writer of membership.

create policy "parties are visible to their members"
  on public.parties for select to authenticated
  using (app.is_party_member(id));

create policy "memberships are visible to the party and to their owner"
  on public.memberships for select to authenticated
  using (user_id = (select auth.uid()) or app.is_party_member(party_id));

create policy "invites are visible to party members"
  on public.invites for select to authenticated
  using (app.is_party_member(party_id));

-- Policies: round ---------------------------------------------------------------------

create policy "rounds are visible to the party and to their locked members"
  on public.rounds for select to authenticated
  using (app.can_read_round(id));

create policy "the locked member list is visible to the round"
  on public.round_members for select to authenticated
  using (app.can_read_round(round_id));

-- Policies: steps ----------------------------------------------------------------------

create policy "step summaries are visible to the round"
  on public.daily_step_summaries for select to authenticated
  using (app.can_read_round(round_id));

create policy "a member syncs their own steps before the deadline"
  on public.daily_step_summaries for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and app.is_round_member(round_id)
    and app.steps_window_open(round_id)
  );

create policy "a member re-syncs their own steps before the deadline"
  on public.daily_step_summaries for update to authenticated
  using (user_id = (select auth.uid()) and app.steps_window_open(round_id))
  with check (
    user_id = (select auth.uid())
    and app.is_round_member(round_id)
    and app.steps_window_open(round_id)
  );

-- Policies: activities -------------------------------------------------------------------

create policy "activities are visible inside a shared round"
  on public.activities for select to authenticated
  using (app.can_read_activity(user_id, started_at));

create policy "a user syncs their own activities"
  on public.activities for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "a user re-syncs their own activities"
  on public.activities for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "a user removes their own activities"
  on public.activities for delete to authenticated
  using (user_id = (select auth.uid()));

-- Policies: check-ins, votes, reactions ----------------------------------------------------

create policy "check-ins are visible to the round unless the viewer reported them"
  on public.checkins for select to authenticated
  using (
    app.can_read_round(round_id)
    and not app.is_hidden_for_viewer('checkin', id)
  );

create policy "a member checks in for themselves while the round runs"
  on public.checkins for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and app.is_round_member(round_id)
    and app.checkin_window_open(round_id)
  );

create policy "a member removes their own check-in"
  on public.checkins for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "votes are visible with the check-in they verify"
  on public.votes for select to authenticated
  using (app.can_read_checkin(checkin_id));

create policy "a member verifies someone else's check-in within 24 hours"
  on public.votes for insert to authenticated
  with check (
    voter_id = (select auth.uid())
    and app.can_read_checkin(checkin_id)
    and app.vote_window_open(checkin_id)
  );

create policy "a member takes back their own vote within 24 hours"
  on public.votes for delete to authenticated
  using (voter_id = (select auth.uid()) and app.vote_window_open(checkin_id));

create policy "reactions are visible with the check-in they belong to"
  on public.reactions for select to authenticated
  using (app.can_read_checkin(checkin_id));

create policy "a member reacts as themselves"
  on public.reactions for insert to authenticated
  with check (user_id = (select auth.uid()) and app.can_read_checkin(checkin_id));

create policy "a member removes their own reaction"
  on public.reactions for delete to authenticated
  using (user_id = (select auth.uid()));

-- Policies: moderation ------------------------------------------------------------------

create policy "a reporter sees only their own reports"
  on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()));

create policy "a member reports content they can see"
  on public.reports for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and status = 'open'
    and (target_type <> 'checkin' or app.can_read_checkin(target_id))
  );

-- Policies: server-computed tables ---------------------------------------------------------
-- Read-only by construction: these tables carry no write grant for any client role, and the
-- select policy is the only policy they have.

create policy "daily points are visible to the round"
  on public.daily_points for select to authenticated
  using (app.can_read_round(round_id));

create policy "weekly results are visible to the round"
  on public.weekly_results for select to authenticated
  using (app.can_read_round(round_id));

create policy "rating history is visible to the party"
  on public.rating_history for select to authenticated
  using (app.is_party_member(party_id) or app.can_read_round(round_id));

create policy "cards are visible to their owner and to the round"
  on public.cards for select to authenticated
  using (
    user_id = (select auth.uid())
    or (round_id is not null and app.can_read_round(round_id))
  );
