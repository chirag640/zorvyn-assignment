begin;

alter table public.user_settings
  add column if not exists session_revoked_at timestamptz;

commit;
