-- levia: banco de dados (cole tudo no Supabase > SQL Editor > New query > Run)
-- Privacidade: peso, plano, fotos do corpo e alimentação ficam em app_state/private_files,
-- que só a própria pessoa consegue ler. Amigos e grupos veem apenas os treinos registrados (checkins).

create extension if not exists pgcrypto;

create table if not exists public.profiles(
  id uuid primary key references auth.users on delete cascade,
  name text not null default '',
  avatar jsonb,
  friend_code text unique not null default upper(substr(md5(gen_random_uuid()::text),1,6)),
  created_at timestamptz default now());

create table if not exists public.app_state(
  user_id uuid primary key references auth.users on delete cascade,
  data jsonb not null,
  updated_at timestamptz default now());

create table if not exists public.private_files(
  user_id uuid references auth.users on delete cascade,
  key text,
  data text not null,
  updated_at timestamptz default now(),
  primary key(user_id, key));

create table if not exists public.friendships(
  user_id uuid references auth.users on delete cascade,
  friend_id uuid references auth.users on delete cascade,
  created_at timestamptz default now(),
  primary key(user_id, friend_id));

create table if not exists public.groups(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null default upper(substr(md5(gen_random_uuid()::text),1,6)),
  owner uuid references auth.users on delete cascade default auth.uid(),
  starts date default current_date,
  ends date,
  created_at timestamptz default now());

create table if not exists public.group_members(
  group_id uuid references public.groups on delete cascade,
  user_id uuid references auth.users on delete cascade,
  joined_at timestamptz default now(),
  primary key(group_id, user_id));

create table if not exists public.checkins(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade default auth.uid(),
  kind text, title text, minutes int, note text, photo text,
  created_at timestamptz default now());
create index if not exists checkins_user_time on public.checkins(user_id, created_at desc);

create table if not exists public.reactions(
  checkin_id uuid references public.checkins on delete cascade,
  user_id uuid references auth.users on delete cascade default auth.uid(),
  created_at timestamptz default now(),
  primary key(checkin_id, user_id));

-- funções auxiliares (rodam com permissão do sistema, mas só respondem sim/não)
create or replace function public.is_friend(a uuid, b uuid) returns boolean language sql stable security definer set search_path=public as
$$ select exists(select 1 from friendships where (user_id=a and friend_id=b) or (user_id=b and friend_id=a)) $$;
create or replace function public.is_member(g uuid, u uuid) returns boolean language sql stable security definer set search_path=public as
$$ select exists(select 1 from group_members where group_id=g and user_id=u) $$;
create or replace function public.shares_group(a uuid, b uuid) returns boolean language sql stable security definer set search_path=public as
$$ select exists(select 1 from group_members m1 join group_members m2 on m1.group_id=m2.group_id where m1.user_id=a and m2.user_id=b) $$;

alter table public.profiles enable row level security;
alter table public.app_state enable row level security;
alter table public.private_files enable row level security;
alter table public.friendships enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.checkins enable row level security;
alter table public.reactions enable row level security;

-- perfis: nome e bichinho (sem dados sensíveis)
drop policy if exists p_profiles_read on public.profiles;
create policy p_profiles_read on public.profiles for select to authenticated using (true);
drop policy if exists p_profiles_ins on public.profiles;
create policy p_profiles_ins on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists p_profiles_upd on public.profiles;
create policy p_profiles_upd on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- dados privados: só a dona
drop policy if exists p_state on public.app_state;
create policy p_state on public.app_state for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists p_files on public.private_files;
create policy p_files on public.private_files for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- amizades
drop policy if exists p_fr_read on public.friendships;
create policy p_fr_read on public.friendships for select to authenticated using (user_id = auth.uid() or friend_id = auth.uid());
drop policy if exists p_fr_del on public.friendships;
create policy p_fr_del on public.friendships for delete to authenticated using (user_id = auth.uid() or friend_id = auth.uid());

-- grupos
drop policy if exists p_g_read on public.groups;
create policy p_g_read on public.groups for select to authenticated using (owner = auth.uid() or public.is_member(id, auth.uid()));
drop policy if exists p_g_upd on public.groups;
create policy p_g_upd on public.groups for update to authenticated using (owner = auth.uid());
drop policy if exists p_g_del on public.groups;
create policy p_g_del on public.groups for delete to authenticated using (owner = auth.uid());
drop policy if exists p_gm_read on public.group_members;
create policy p_gm_read on public.group_members for select to authenticated using (public.is_member(group_id, auth.uid()));
drop policy if exists p_gm_del on public.group_members;
create policy p_gm_del on public.group_members for delete to authenticated using (user_id = auth.uid());

-- treinos: a pessoa, os amigos e quem está no mesmo grupo
drop policy if exists p_ck_read on public.checkins;
create policy p_ck_read on public.checkins for select to authenticated using (user_id = auth.uid() or public.is_friend(auth.uid(), user_id) or public.shares_group(auth.uid(), user_id));
drop policy if exists p_ck_ins on public.checkins;
create policy p_ck_ins on public.checkins for insert to authenticated with check (user_id = auth.uid());
drop policy if exists p_ck_upd on public.checkins;
create policy p_ck_upd on public.checkins for update to authenticated using (user_id = auth.uid());
drop policy if exists p_ck_del on public.checkins;
create policy p_ck_del on public.checkins for delete to authenticated using (user_id = auth.uid());

-- aplausos
drop policy if exists p_rx_read on public.reactions;
create policy p_rx_read on public.reactions for select to authenticated using (exists(select 1 from public.checkins c where c.id = checkin_id));
drop policy if exists p_rx_ins on public.reactions;
create policy p_rx_ins on public.reactions for insert to authenticated with check (user_id = auth.uid() and exists(select 1 from public.checkins c where c.id = checkin_id));
drop policy if exists p_rx_del on public.reactions;
create policy p_rx_del on public.reactions for delete to authenticated using (user_id = auth.uid());

-- ações por código
create or replace function public.add_friend(p_code text) returns json language plpgsql security definer set search_path=public as $$
declare f profiles;
begin
  select * into f from profiles where friend_code = upper(trim(p_code));
  if f.id is null or f.id = auth.uid() then return null; end if;
  insert into friendships(user_id, friend_id) values (auth.uid(), f.id) on conflict do nothing;
  return json_build_object('id', f.id, 'name', f.name);
end $$;

create or replace function public.create_group(p_name text, p_ends date default null) returns json language plpgsql security definer set search_path=public as $$
declare g groups;
begin
  if auth.uid() is null then return null; end if;
  insert into groups(name, owner, ends) values (left(trim(p_name),40), auth.uid(), p_ends) returning * into g;
  insert into group_members(group_id, user_id) values (g.id, auth.uid());
  return json_build_object('id', g.id, 'code', g.code);
end $$;

create or replace function public.join_group(p_code text) returns json language plpgsql security definer set search_path=public as $$
declare g groups;
begin
  select * into g from groups where code = upper(trim(p_code));
  if g.id is null or auth.uid() is null then return null; end if;
  insert into group_members(group_id, user_id) values (g.id, auth.uid()) on conflict do nothing;
  return json_build_object('id', g.id, 'code', g.code);
end $$;

-- ranking: 1 ponto por dia com treino registrado dentro do período do grupo
create or replace function public.leaderboard(g uuid) returns table(user_id uuid, name text, avatar jsonb, days bigint, minutes bigint)
language sql stable security definer set search_path=public as $$
  select m.user_id, p.name, p.avatar,
         count(distinct (c.created_at at time zone 'America/Sao_Paulo')::date) as days,
         coalesce(sum(c.minutes),0) as minutes
  from group_members m
  join groups gr on gr.id = m.group_id
  join profiles p on p.id = m.user_id
  left join checkins c on c.user_id = m.user_id
       and (c.created_at at time zone 'America/Sao_Paulo')::date >= gr.starts
       and (gr.ends is null or (c.created_at at time zone 'America/Sao_Paulo')::date <= gr.ends)
  where m.group_id = g and public.is_member(g, auth.uid())
  group by m.user_id, p.name, p.avatar
  order by days desc, minutes desc;
$$;

grant execute on function public.add_friend(text), public.create_group(text, date), public.join_group(text), public.leaderboard(uuid) to authenticated;
