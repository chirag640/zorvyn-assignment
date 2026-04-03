-- Ensure finance tables emit realtime events for cross-device sync.

begin;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'finance_transactions'
    ) then
      alter publication supabase_realtime add table public.finance_transactions;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'finance_goal_settings'
    ) then
      alter publication supabase_realtime add table public.finance_goal_settings;
    end if;
  end if;
end
$$;

commit;
