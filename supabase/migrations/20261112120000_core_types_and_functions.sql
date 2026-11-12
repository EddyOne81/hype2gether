-- Core building blocks shared by every domain.
--
-- Two rules shape this whole schema (docs/adr/0008):
--   1. No scoring logic ever lives in SQL. The database stores facts, enforces identity,
--      deadlines and shapes; `packages/scoring` decides points, places and ratings.
--   2. Security helpers live outside `public` so PostgREST never exposes them, and are
--      `security definer` with an empty search_path so policies can read membership tables
--      without recursing through those tables' own policies.

create extension if not exists btree_gist with schema extensions;

create schema if not exists app;
revoke all on schema app from public;
grant usage on schema app to authenticated, service_role;

comment on schema app is
  'Private helpers for row level security. Not exposed through the Data API (see supabase/config.toml, api.schemas).';

-- Enumerations -------------------------------------------------------------

create type public.sport as enum ('walk', 'run', 'ride');
create type public.round_status as enum ('active', 'provisional', 'final');
create type public.result_status as enum ('provisional', 'final');
create type public.point_flag as enum ('implausible_steps');
create type public.card_kind as enum ('weekly_winner', 'weekly_summary', 'solo_weekly', 'activity');
create type public.report_target as enum ('checkin');
create type public.report_status as enum ('open', 'reviewed', 'dismissed');

comment on type public.point_flag is
  'Why a day was flagged for the party to see. A flag never changes points by itself.';

-- Generic trigger functions ------------------------------------------------

create function app.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create function app.assert_valid_timezone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    raise exception 'Unknown time zone: %', new.timezone using errcode = '22023';
  end if;
  return new;
end;
$$;

-- Rows that must never change once written. Deletes still cascade from the parent row.
create function app.reject_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Table %.% is append-only', tg_table_schema, tg_table_name
    using errcode = '42501';
end;
$$;

-- The calendar day a moment falls on in a party's time zone. Bucketing facts into days is a
-- game rule owned by `packages/scoring`; this exists only so the database can verify what a
-- client claims, never to compute a score.
create function app.day_in_timezone(p_at timestamptz, p_timezone text)
returns date
language sql
stable
set search_path = ''
as $$
  select (p_at at time zone p_timezone)::date;
$$;
