-- Private bucket for check-in photos.
--
-- Objects are named {party_id}/{round_id}/{user_id}/{file}, so the path itself carries the
-- tenancy and a policy can authorise an object without joining back through the check-in row.
-- The bucket is never public: the app reads photos through short-lived signed URLs.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'checkins',
  'checkins',
  false,
  10485760,
  array['image/jpeg', 'image/heic', 'image/heif', 'image/png']
)
on conflict (id) do nothing;

-- Path readers. Both return null for a path that is not shaped like a check-in photo, and a
-- null round or owner never satisfies a policy.
create function app.checkin_object_round(p_name text)
returns uuid language plpgsql immutable set search_path = '' as $$
declare
  parts text[];
begin
  parts := pg_catalog.string_to_array(p_name, '/');
  if pg_catalog.array_length(parts, 1) is distinct from 4 then
    return null;
  end if;
  return parts[2]::uuid;
exception
  when others then return null;
end;
$$;

create function app.checkin_object_owner(p_name text)
returns uuid language plpgsql immutable set search_path = '' as $$
declare
  parts text[];
begin
  parts := pg_catalog.string_to_array(p_name, '/');
  if pg_catalog.array_length(parts, 1) is distinct from 4 then
    return null;
  end if;
  return parts[3]::uuid;
exception
  when others then return null;
end;
$$;

grant execute on function app.checkin_object_round(text) to authenticated, service_role;
grant execute on function app.checkin_object_owner(text) to authenticated, service_role;

create policy "check-in photos are readable inside the round"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'checkins'
    and app.can_read_round(app.checkin_object_round(name))
  );

create policy "a member uploads check-in photos under their own prefix"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'checkins'
    and app.checkin_object_owner(name) = (select auth.uid())
    and app.is_round_member(app.checkin_object_round(name))
    and app.checkin_window_open(app.checkin_object_round(name))
  );

create policy "a member removes their own check-in photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'checkins'
    and app.checkin_object_owner(name) = (select auth.uid())
  );
