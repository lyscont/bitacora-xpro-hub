-- Bitácora XPRO HUB 2.1.0: ejecutar una vez en SQL Editor.
begin;
create table if not exists public.xpro_ai_history (
 id uuid primary key,
 owner uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 finished_at timestamptz,
 model text not null check(model in ('gpt-6-luna','gpt-6.1-terra','gpt-6.1-sol')),
 mode text not null check(mode in ('normal','recommendations','diagnostic')),
 status text not null default 'pending' check(status in ('pending','completed','partial','error','unknown')),
 input_tokens bigint check(input_tokens>=0),
 output_tokens bigint check(output_tokens>=0),
 cost_usd numeric(18,8) check(cost_usd>=0),
 input_rate numeric(12,6) not null,
 output_rate numeric(12,6) not null,
 question text check(char_length(question)<=2000),
 answer text check(char_length(answer)<=60000)
);
alter table public.xpro_ai_history enable row level security;
revoke all on public.xpro_ai_history from public, anon, authenticated;
grant select on public.xpro_ai_history to authenticated;
grant select, insert, update on public.xpro_ai_history to service_role;
drop policy if exists xpro_history_read_owner on public.xpro_ai_history;
create policy xpro_history_read_owner on public.xpro_ai_history for select to authenticated using ((select auth.uid())=owner);
create index if not exists xpro_history_owner_date on public.xpro_ai_history(owner,created_at desc,id desc);
create or replace function public.xpro_clear_ai_content(p_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
 update public.xpro_ai_history set question=null, answer=null
 where id=p_id and owner=auth.uid() and status<>'pending';
 return found;
end;
$$;
revoke all on function public.xpro_clear_ai_content(uuid) from public, anon, authenticated;
grant execute on function public.xpro_clear_ai_content(uuid) to authenticated;
commit;
