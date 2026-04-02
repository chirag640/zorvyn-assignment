-- Supabase core schema for auth-linked profile and finance features
-- Created: 2026-04-01

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text not null default 'User',
  avatar text,
  bio text,
  phone text,
  location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finance_transactions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12, 2) not null check (amount >= 0),
  type text not null check (type in ('expense', 'income')),
  category text not null,
  note text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finance_goal_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  weekly_savings_target numeric(12, 2) not null default 50 check (weekly_savings_target > 0),
  weekly_spend_limit numeric(12, 2) not null default 120 check (weekly_spend_limit > 0),
  monthly_savings_goal numeric(12, 2) not null default 500 check (monthly_savings_goal > 0),
  daily_spend_limit numeric(12, 2) not null default 25 check (daily_spend_limit > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_finance_transactions_user_occurred_at
  on public.finance_transactions(user_id, occurred_at desc);

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists trg_finance_transactions_set_updated_at on public.finance_transactions;
create trigger trg_finance_transactions_set_updated_at
before update on public.finance_transactions
for each row
execute function public.set_updated_at();

drop trigger if exists trg_finance_goal_settings_set_updated_at on public.finance_goal_settings;
create trigger trg_finance_goal_settings_set_updated_at
before update on public.finance_goal_settings
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.finance_transactions enable row level security;
alter table public.finance_goal_settings enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles
  for select
  using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles
  for insert
  with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
  on public.profiles
  for delete
  using (auth.uid() = id);

drop policy if exists finance_transactions_select_own on public.finance_transactions;
create policy finance_transactions_select_own
  on public.finance_transactions
  for select
  using (auth.uid() = user_id);

drop policy if exists finance_transactions_insert_own on public.finance_transactions;
create policy finance_transactions_insert_own
  on public.finance_transactions
  for insert
  with check (auth.uid() = user_id);

drop policy if exists finance_transactions_update_own on public.finance_transactions;
create policy finance_transactions_update_own
  on public.finance_transactions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists finance_transactions_delete_own on public.finance_transactions;
create policy finance_transactions_delete_own
  on public.finance_transactions
  for delete
  using (auth.uid() = user_id);

drop policy if exists finance_goal_settings_select_own on public.finance_goal_settings;
create policy finance_goal_settings_select_own
  on public.finance_goal_settings
  for select
  using (auth.uid() = user_id);

drop policy if exists finance_goal_settings_insert_own on public.finance_goal_settings;
create policy finance_goal_settings_insert_own
  on public.finance_goal_settings
  for insert
  with check (auth.uid() = user_id);

drop policy if exists finance_goal_settings_update_own on public.finance_goal_settings;
create policy finance_goal_settings_update_own
  on public.finance_goal_settings
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'name', split_part(coalesce(new.email, 'User'), '@', 1), 'User')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists avatars_read_all on storage.objects;
create policy avatars_read_all
  on storage.objects
  for select
  using (bucket_id = 'avatars');

drop policy if exists avatars_write_own on storage.objects;
create policy avatars_write_own
  on storage.objects
  for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own
  on storage.objects
  for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

commit;
