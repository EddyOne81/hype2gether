-- Invariant (CONTRIBUTING.md engineering rule 4): every table in `public` has RLS enabled and at least one policy.
begin;

create extension if not exists pgtap with schema extensions;

select plan(2);

select is(
  (
    select coalesce(array_agg(c.relname::text order by c.relname), '{}')
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity
  ),
  '{}'::text[],
  'every table in public has row level security enabled'
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
        from pg_policies p
        where p.schemaname = 'public'
          and p.tablename = c.relname
      )
  ),
  '{}'::text[],
  'every table in public has at least one policy'
);

select * from finish();

rollback;
