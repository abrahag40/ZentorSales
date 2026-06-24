-- ============================================================================
-- ZENTOR · La Biblia del Vendedor — Esquema de base de datos (Supabase)
-- Ejecuta TODO este archivo en Supabase → SQL Editor → New query → Run.
-- Crea las tablas, la seguridad (RLS) y los disparadores de alta de usuario.
-- ============================================================================

-- ---------- Tablas ----------------------------------------------------------

create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  full_name  text,
  role       text not null default 'vendedor' check (role in ('vendedor','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.progress (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  studied    jsonb not null default '{}'::jsonb,   -- { "capId": true }
  checks     jsonb not null default '{}'::jsonb,   -- checklist de cierre
  roi        jsonb,                                -- calculadora de ROI
  updated_at timestamptz not null default now()
);

-- ---------- Función: ¿el usuario actual es admin? ---------------------------
-- SECURITY DEFINER para evitar recursión de políticas al leer profiles.

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------- Seguridad a nivel de fila (RLS) ---------------------------------

alter table public.profiles enable row level security;
alter table public.progress enable row level security;

-- profiles: cada quien ve/edita lo suyo; el admin ve a todos.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- progress: cada quien ve/edita lo suyo; el admin ve a todos (solo lectura).
drop policy if exists progress_select on public.progress;
create policy progress_select on public.progress
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists progress_insert on public.progress;
create policy progress_insert on public.progress
  for insert with check (user_id = auth.uid());

drop policy if exists progress_update on public.progress;
create policy progress_update on public.progress
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- Anti-escalada: un vendedor no puede auto-ascenderse a admin -----

create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    new.role := old.role;  -- ignora el cambio de rol si no es admin
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_profile_role on public.profiles;
create trigger trg_guard_profile_role
  before update on public.profiles
  for each row execute function public.guard_profile_role();

-- ---------- Alta automática de perfil al registrarse -----------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- HAZTE ADMINISTRADOR
-- Después de entrar UNA vez con tu correo (para que exista tu perfil), corre:
--
--   update public.profiles set role = 'admin' where email = 'abrahag40@gmail.com';
--
-- ============================================================================
