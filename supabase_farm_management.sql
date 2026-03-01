-- ============================================================
-- FARM MANAGEMENT SQL FUNCTIONS
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. UPDATE FARM NAME (admin-only)
-- ============================================================
create or replace function public.update_farm(
  p_farm_id uuid,
  p_new_name text
)
returns void
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from farm_members fm
    where fm.farm_id = p_farm_id
      and fm.user_id = auth.uid()
      and fm.role = 'admin'
  ) then
    raise exception 'Only admins can update the farm';
  end if;

  update farms
  set name = p_new_name
  where id = p_farm_id;
end;
$$;

grant execute on function public.update_farm(uuid, text) to authenticated;


-- 2. ADD FARM WORKER by email (admin-only, always 'worker' role)
-- ============================================================
create or replace function public.add_farm_worker(
  p_farm_id uuid,
  p_email text
)
returns void
language plpgsql
security definer
as $$
declare
  target_user_id uuid;
begin
  if not exists (
    select 1 from farm_members fm
    where fm.farm_id = p_farm_id
      and fm.user_id = auth.uid()
      and fm.role = 'admin'
  ) then
    raise exception 'Only admins can add workers';
  end if;

  select id into target_user_id
  from profiles
  where email = p_email;

  if target_user_id is null then
    raise exception 'No user found with this email';
  end if;

  if exists (
    select 1 from farm_members
    where farm_id = p_farm_id
      and user_id = target_user_id
  ) then
    raise exception 'User is already a member of this farm';
  end if;

  insert into farm_members (farm_id, user_id, role, added_by)
  values (p_farm_id, target_user_id, 'worker', auth.uid());
end;
$$;

grant execute on function public.add_farm_worker(uuid, text) to authenticated;


-- 3. REMOVE FARM WORKER (admin-only)
-- ============================================================
create or replace function public.remove_farm_worker(
  p_farm_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from farm_members fm
    where fm.farm_id = p_farm_id
      and fm.user_id = auth.uid()
      and fm.role = 'admin'
  ) then
    raise exception 'Only admins can remove workers';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'Admin cannot remove themselves';
  end if;

  delete from farm_members
  where farm_id = p_farm_id
    and user_id = p_user_id;
end;
$$;

grant execute on function public.remove_farm_worker(uuid, uuid) to authenticated;


-- 4. DELETE FARM (admin-only, cascades everything)
-- ============================================================
create or replace function public.delete_farm(
  p_farm_id uuid
)
returns void
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from farm_members fm
    where fm.farm_id = p_farm_id
      and fm.user_id = auth.uid()
      and fm.role = 'admin'
  ) then
    raise exception 'Only admins can delete the farm';
  end if;

  delete from cattle_profiles
  where cattle_id in (select id from cattle where farm_id = p_farm_id);

  delete from cattle_health_readings where farm_id = p_farm_id;
  delete from alerts where farm_id = p_farm_id;
  delete from approvals where farm_id = p_farm_id;
  delete from cattle where farm_id = p_farm_id;
  delete from farm_members where farm_id = p_farm_id;
  delete from farms where id = p_farm_id;
end;
$$;

grant execute on function public.delete_farm(uuid) to authenticated;


-- 5. GET FARM WORKERS (list all members with email & role)
-- ============================================================
create or replace function public.get_farm_workers(
  p_farm_id uuid
)
returns table (
  user_id uuid,
  email text,
  full_name text,
  role text,
  created_at timestamptz
)
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from farm_members fm
    where fm.farm_id = p_farm_id
      and fm.user_id = auth.uid()
  ) then
    raise exception 'You are not a member of this farm';
  end if;

  return query
  select fm.user_id, p.email, p.full_name, fm.role, fm.created_at
  from farm_members fm
  join profiles p on p.id = fm.user_id
  where fm.farm_id = p_farm_id
  order by fm.created_at;
end;
$$;

grant execute on function public.get_farm_workers(uuid) to authenticated;


-- ============================================================
-- 6. ADMIN DELETE CATTLE POLICIES
-- Allow admins to delete cattle and related records
-- ============================================================

CREATE POLICY "admins_can_delete_cattle"
ON cattle FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM farm_members fm
  WHERE fm.farm_id = cattle.farm_id
    AND fm.user_id = auth.uid() AND fm.role = 'admin'
));

CREATE POLICY "admins_can_delete_health_readings"
ON cattle_health_readings FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM farm_members fm
  WHERE fm.farm_id = cattle_health_readings.farm_id
    AND fm.user_id = auth.uid() AND fm.role = 'admin'
));

CREATE POLICY "admins_can_delete_alerts"
ON alerts FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM farm_members fm
  WHERE fm.farm_id = alerts.farm_id
    AND fm.user_id = auth.uid() AND fm.role = 'admin'
));

CREATE POLICY "admins_can_delete_approvals"
ON approvals FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM farm_members fm
  WHERE fm.farm_id = approvals.farm_id
    AND fm.user_id = auth.uid() AND fm.role = 'admin'
));

CREATE POLICY "admins_can_delete_cattle_profiles"
ON cattle_profiles FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM cattle c
  JOIN farm_members fm ON fm.farm_id = c.farm_id
  WHERE c.id = cattle_profiles.cattle_id
    AND fm.user_id = auth.uid() AND fm.role = 'admin'
));
