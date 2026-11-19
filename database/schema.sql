-- Hogwarts Infinity: initial identity and classroom schema
-- Run this in the SQL Editor of a NEW, dedicated Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'جادوآموز',
  role text not null default 'student' check (role in ('student','teacher','admin')),
  house text check (house in ('gryffindor','slytherin','ravenclaw','hufflepuff')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classrooms (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete restrict,
  title text not null check (char_length(title) between 3 and 100),
  subject text not null default 'عمومی',
  room_code text not null unique default upper(encode(gen_random_bytes(5),'hex')),
  status text not null default 'scheduled' check (status in ('scheduled','live','ended')),
  starts_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.enrollments (
  classroom_id uuid not null references public.classrooms(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  primary key (classroom_id, student_id)
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'جادوآموز'),
    'student'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.classrooms enable row level security;
alter table public.enrollments enable row level security;

-- Profiles: a user may read the directory, but only update their own display name/house.
create policy "profiles readable by authenticated users"
on public.profiles for select to authenticated using (true);
create policy "users update own profile"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- A teacher may manage only classrooms they own. Students see scheduled/live classes.
create policy "authenticated users view classes"
on public.classrooms for select to authenticated using (true);
create policy "teachers create own classes"
on public.classrooms for insert to authenticated
with check (
  teacher_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('teacher','admin'))
);
create policy "teachers update own classes"
on public.classrooms for update to authenticated
using (
  teacher_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('teacher','admin'))
)
with check (
  teacher_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('teacher','admin'))
);
create policy "teachers delete own classes"
on public.classrooms for delete to authenticated
using (
  teacher_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('teacher','admin'))
);

-- Students enroll themselves. A class teacher can see its enrollment list.
create policy "students and class teachers view enrollments"
on public.enrollments for select to authenticated
using (
  student_id = (select auth.uid())
  or exists (
    select 1 from public.classrooms c
    where c.id = classroom_id and c.teacher_id = (select auth.uid())
  )
);
create policy "students enroll themselves"
on public.enrollments for insert to authenticated
with check (
  student_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'student')
);
create policy "students withdraw themselves"
on public.enrollments for delete to authenticated
using (student_id = (select auth.uid()));

-- Explicit Data API grants: tables remain protected by RLS.
grant usage on schema public to authenticated;
revoke update on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, house) on public.profiles to authenticated;
grant select, insert, update, delete on public.classrooms to authenticated;
grant select, insert, delete on public.enrollments to authenticated;

-- Promote a trusted teacher manually after creating their account:
-- update public.profiles set role = 'teacher' where id = '<AUTH-USER-UUID>';
