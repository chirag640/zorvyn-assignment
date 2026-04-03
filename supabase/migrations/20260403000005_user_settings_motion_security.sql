begin;

alter table public.user_settings
  add column if not exists reduce_motion_enabled boolean not null default false,
  add column if not exists inactivity_lock_enabled boolean not null default false,
  add column if not exists inactivity_timeout_minutes integer not null default 5
    check (inactivity_timeout_minutes between 1 and 120);

commit;
