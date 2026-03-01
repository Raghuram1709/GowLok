-- ==========================================
-- 1. APPROVALS TABLE
-- ==========================================
create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid references public.farms(id) on delete cascade not null,
  entity_type text not null, -- e.g., 'cattle'
  entity_id uuid not null,   -- e.g., cattle.id
  action text not null,      -- e.g., 'create', 'update', 'delete'
  submitted_by uuid references public.profiles(id) on delete set null,
  status text check (status in ('pending', 'approved', 'rejected')) default 'pending' not null,
  reviewed_by uuid references public.profiles(id) on delete set null,
  review_notes text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- RLS for approvals
alter table public.approvals enable row level security;

create policy "farm_members_can_view_approvals"
on public.approvals for select to authenticated
using (exists (
  select 1 from public.farm_members fm
  where fm.farm_id = approvals.farm_id
    and fm.user_id = auth.uid()
));

-- Workers can insert pending approvals
create policy "workers_can_insert_approvals"
on public.approvals for insert to authenticated
with check (exists (
  select 1 from public.farm_members fm
  where fm.farm_id = farm_id
    and fm.user_id = auth.uid()
    and fm.role = 'worker'
));

-- Only admins can update approvals directly (to approve/reject)
create policy "admins_can_update_approvals"
on public.approvals for update to authenticated
using (exists (
  select 1 from public.farm_members fm
  where fm.farm_id = approvals.farm_id
    and fm.user_id = auth.uid()
    and fm.role = 'admin'
));

-- ==========================================
-- 2. SUBMIT_APPROVAL RPC
-- ==========================================
create or replace function public.submit_approval(
  p_farm_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_action text,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_approval_id uuid;
  v_role text;
  v_initial_status text := 'pending';
begin
  -- Check user's role in the farm
  select role into v_role from public.farm_members
  where farm_id = p_farm_id and user_id = auth.uid();

  if v_role is null then
    raise exception 'User is not a member of the farm';
  end if;

  -- If admin submits, automatically approve
  if v_role = 'admin' then
    v_initial_status := 'approved';
  end if;

  insert into public.approvals (
    farm_id, entity_type, entity_id, action, submitted_by, status, review_notes
  ) values (
    p_farm_id, p_entity_type, p_entity_id, p_action, auth.uid(), v_initial_status, p_notes
  ) returning id into v_approval_id;

  return v_approval_id;
end;
$$;

-- ==========================================
-- 3. REVIEW_APPROVAL RPC
-- ==========================================
create or replace function public.review_approval(
  approval_id uuid,
  new_status text,
  review_notes text default null
)
returns void
language plpgsql
security definer
as $$
declare
  v_farm_id uuid;
  v_current_status text;
begin
  -- Check if status is valid
  if new_status not in ('approved', 'rejected') then
    raise exception 'Invalid status. Must be approved or rejected.';
  end if;

  -- Get approval details
  select farm_id, status into v_farm_id, v_current_status
  from public.approvals where id = approval_id;

  if v_farm_id is null then
    raise exception 'Approval not found';
  end if;

  if v_current_status != 'pending' then
    raise exception 'Approval is no longer pending';
  end if;

  -- Check if user is admin
  if not exists (
    select 1 from public.farm_members
    where farm_id = v_farm_id and user_id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Only admins can review approvals';
  end if;

  -- Update approval status
  update public.approvals
  set
    status = new_status,
    reviewed_by = auth.uid(),
    review_notes = coalesce(review_approval.review_notes, approvals.review_notes),
    updated_at = now()
  where id = approval_id;
end;
$$;

-- ==========================================
-- 4. TRIGGER: AUTO-ACTIVATE CATTLE ON APPROVAL
-- ==========================================
-- Trigger function to execute when an approval is approved
create or replace function public.handle_cattle_approval()
returns trigger
language plpgsql
security definer
as $$
begin
  -- If status changes to 'approved', entity_type is 'cattle', and action is 'create'
  if new.status = 'approved' and old.status = 'pending' and new.entity_type = 'cattle' and new.action = 'create' then
    update public.cattle
    set is_active = true
    where id = new.entity_id;
  end if;
  return new;
end;
$$;

-- Attach trigger to approvals table
drop trigger if exists on_cattle_approval on public.approvals;
create trigger on_cattle_approval
  after update on public.approvals
  for each row
  when (old.status distinct from new.status)
  execute procedure public.handle_cattle_approval();

-- Ensure cattle inserted by admin bypass approval (optional safety net)
-- But the submit_approval RPC already handles admin auto-approve.
