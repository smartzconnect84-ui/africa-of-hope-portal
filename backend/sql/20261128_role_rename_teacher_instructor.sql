-- Rename the stored teaching role from "Teacher" to "Teacher-Instructor".
--
-- Must run in the same window as the frontend release: the client compares the
-- literal role string, so a gap leaves signed-in teachers without their
-- dashboards. One transaction keeps policies, functions, the roles row, the
-- permission matrix and profiles consistent.
--
-- roles is a real table (profiles.role and role_permissions.role reference it).
-- profiles has ON UPDATE CASCADE but role_permissions does not, so the new role
-- row is created first and the children are moved onto it explicitly.
begin;

-- 1. RLS policies that compare the role literal.
do $$
declare p record;
declare stmt text;
begin
  for p in
    select schemaname, tablename, policyname,
           coalesce(qual, '') as qual, coalesce(with_check, '') as chk
    from pg_policies
    where schemaname = 'public'
      and (coalesce(qual, '') like '%''Teacher''%' or coalesce(with_check, '') like '%''Teacher''%')
  loop
    stmt := format('alter policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    if p.qual <> '' then
      stmt := stmt || format(' using (%s)', replace(p.qual, '''Teacher''', '''Teacher-Instructor'''));
    end if;
    if p.chk <> '' then
      stmt := stmt || format(' with check (%s)', replace(p.chk, '''Teacher''', '''Teacher-Instructor'''));
    end if;
    execute stmt;
  end loop;
end $$;

-- 2. Functions whose bodies compare the role literal.
do $$
declare f record;
begin
  for f in
    select pg_get_functiondef(p.oid) as def
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosrc like '%''Teacher''%'
  loop
    execute replace(f.def, '''Teacher''', '''Teacher-Instructor''');
  end loop;
end $$;

-- 3. The role catalogue row, keeping label/description/sort.
insert into public.roles (name, label, description, is_system, sort)
select 'Teacher-Instructor', 'Teacher-Instructor', description, is_system, sort
from public.roles
where name = 'Teacher'
on conflict (name) do nothing;

-- 4. The permission matrix copied onto the new role.
insert into public.role_permissions (role, permission)
select 'Teacher-Instructor', permission
from public.role_permissions
where role = 'Teacher'
on conflict do nothing;

-- 5. Accounts, then retire the old role.
update public.profiles set role = 'Teacher-Instructor' where role = 'Teacher';
delete from public.role_permissions where role = 'Teacher';
delete from public.roles where name = 'Teacher';

commit;
