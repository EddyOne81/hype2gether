-- Invariant: the server-authoritative tables are unwritable by construction.
--
-- Row level security alone is not enough here. A policy can be added by mistake, but a table
-- with no INSERT/UPDATE/DELETE grant for any client role cannot be written at all, whatever
-- the policies say. This test guards that second layer, plus the hardening every helper
-- function in `app` depends on.
begin;

create extension if not exists pgtap with schema extensions;

select plan(5);

select is(
  (
    select coalesce(array_agg(distinct table_name::text order by table_name::text), '{}')
    from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'anon'
  ),
  '{}'::text[],
  'anonymous clients have no access to any table in public'
);

-- CONTRIBUTING.md engineering rule 1: only server code writes points, results and ratings.
select is(
  (
    select coalesce(array_agg(distinct table_name::text || ':' || privilege_type::text
                              order by table_name::text || ':' || privilege_type::text), '{}')
    from information_schema.role_table_grants
    where table_schema = 'public'
      and grantee = 'authenticated'
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
      and table_name in (
        'daily_points', 'weekly_results', 'rating_history', 'cards',
        'rounds', 'round_members', 'parties', 'memberships', 'invites'
      )
  ),
  '{}'::text[],
  'clients hold no write grant on server-authoritative tables'
);

select is(
  (
    select coalesce(array_agg(table_name::text order by table_name::text), '{}')
    from information_schema.role_table_grants
    where table_schema = 'public'
      and grantee = 'authenticated'
      and privilege_type = 'UPDATE'
      and table_name = 'rounds'
  ),
  '{}'::text[],
  'a client can never move a round to another status'
);

-- Every security definer helper must pin its search_path, or a caller could shadow the
-- tables it reads and widen its own access.
select is(
  (
    select coalesce(array_agg(p.proname::text order by p.proname::text), '{}')
    from pg_proc p
    where p.pronamespace = 'app'::regnamespace
      and p.prosecdef
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, '{}')) as c(setting)
        where c.setting like 'search\_path=%'
      )
  ),
  '{}'::text[],
  'every security definer helper in app pins its search_path'
);

select is(
  (
    select coalesce(array_agg(c.relname::text order by c.relname), '{}')
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not exists (
        select 1
        from information_schema.role_table_grants g
        where g.table_schema = 'public'
          and g.table_name = c.relname::text
          and g.grantee = 'authenticated'
          and g.privilege_type = 'SELECT'
      )
  ),
  '{}'::text[],
  'every table in public is readable by signed-in members, subject to its policies'
);

select * from finish();

rollback;
