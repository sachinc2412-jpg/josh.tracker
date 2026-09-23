-- V3 upgrade: rerunnable; preserves all existing V2 rows.
-- Run once in your existing Supabase project's SQL Editor.
-- Preserves tracker_state as a read-only migration source and backup.
-- State and deduplication records are isolated by auth.uid().
begin;
create table if not exists public.josh_v2_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.josh_v2_events (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  created_at timestamptz not null default now(),
  primary key(user_id,event_id)
);
alter table public.josh_v2_state enable row level security;
alter table public.josh_v2_events enable row level security;
drop policy if exists owner_state on public.josh_v2_state;
create policy owner_state on public.josh_v2_state for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists owner_events on public.josh_v2_events;
create policy owner_events on public.josh_v2_events for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update on public.josh_v2_state to authenticated;
grant select, insert on public.josh_v2_events to authenticated;
revoke all on public.josh_v2_state, public.josh_v2_events from anon;

create or replace function public.josh_sync_v2(p_ops jsonb, p_seed jsonb)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  uid uuid := auth.uid();
  s jsonb;
  op jsonb;
  accepted integer;
  k text;
  d text;
begin
  if uid is null then raise exception 'Sign in required'; end if;
  if jsonb_typeof(p_ops) <> 'array' or jsonb_array_length(p_ops) > 250 then
    raise exception 'Invalid operation batch';
  end if;
  if jsonb_typeof(p_seed->'habits') <> 'object' or jsonb_typeof(p_seed->'log') <> 'object'
    or jsonb_typeof(p_seed->'prefs') <> 'object' or jsonb_typeof(p_seed->'goal') <> 'object' then
    raise exception 'Invalid state';
  end if;
  insert into public.josh_v2_state(user_id,state) values(uid,p_seed)
    on conflict(user_id) do nothing;
  select state into s from public.josh_v2_state where user_id = uid for update;
  for op in select value from jsonb_array_elements(p_ops) loop
    if coalesce(op->>'id','') = '' or jsonb_typeof(op->'value') <> 'object' then
      raise exception 'Invalid operation';
    end if;
    insert into public.josh_v2_events(user_id,event_id) values(uid,op->>'id') on conflict do nothing;
    get diagnostics accepted = row_count;
    if accepted = 0 then continue; end if;
    k := op->>'key'; d := op->>'day';
    case op->>'type'
      when 'habit' then
        if coalesce(k,'') = '' then raise exception 'Invalid habit'; end if;
        s := jsonb_set(s,array['habits',k],op->'value',true);
      when 'log' then
        if coalesce(k,'') = '' or coalesce(d,'') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Invalid log'; end if;
        s := jsonb_set(s,array['log',d],coalesce(s#>array['log',d],'{}'::jsonb) || jsonb_build_object(k,op->'value'),true);
      when 'journal' then
        if coalesce(k,'') = '' or coalesce(d,'') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Invalid journal'; end if;
        s := jsonb_set(s,'{journal}',coalesce(s->'journal','{}'::jsonb),true);
        s := jsonb_set(s,array['journal',d],coalesce(s#>array['journal',d],'{}'::jsonb) || jsonb_build_object(k,op->'value'),true);
      when 'review' then
        if coalesce(k,'') = '' then raise exception 'Invalid review'; end if;
        s := jsonb_set(s,'{reviews}',coalesce(s->'reviews','{}'::jsonb) || jsonb_build_object(k,op->'value'),true);
      when 'rest' then
        if coalesce(d,'') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Invalid rest date'; end if;
        s := jsonb_set(s,'{restDays}',coalesce(s->'restDays','{}'::jsonb) || jsonb_build_object(d,op->'value'),true);
      when 'prefs' then s := jsonb_set(s,'{prefs}',(s->'prefs') || (op->'value'));
      when 'goal' then s := jsonb_set(s,'{goal}',(s->'goal') || (op->'value'));
      else raise exception 'Unknown operation';
    end case;
  end loop;
  update public.josh_v2_state set state = s, updated_at = now() where user_id = uid;
  return s;
end;
$$;
revoke all on function public.josh_sync_v2(jsonb,jsonb) from public, anon;
grant execute on function public.josh_sync_v2(jsonb,jsonb) to authenticated;
commit;
