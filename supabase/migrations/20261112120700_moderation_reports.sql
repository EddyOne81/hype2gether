-- Content reports (MOD-01).
--
-- Reporting is private: a reporter sees only their own reports, and the reported item is
-- hidden from them immediately (enforced in the `checkins` read policy). Review happens
-- server-side, so clients may insert a report but never change its status.

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  target_type public.report_target not null,
  target_id uuid not null,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason text,
  status public.report_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_one_per_reporter unique (target_type, target_id, reporter_id),
  constraint reports_reason_length check (reason is null or char_length(btrim(reason)) between 1 and 500)
);

comment on table public.reports is
  'Moderation queue. target_id is deliberately not a foreign key so more target types can be added later.';

create index reports_target_idx on public.reports (target_type, target_id);
create index reports_open_queue_idx on public.reports (created_at) where status = 'open';

create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function app.set_updated_at();

alter table public.reports enable row level security;
