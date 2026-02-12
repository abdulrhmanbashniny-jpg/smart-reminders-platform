-- Task 1: Finalize schema hardening + RLS policies

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- Schema hardening
-- -----------------------------------------------------------------------------

alter table public.system_settings
  add column if not exists timezone text not null default 'Asia/Riyadh';

alter table public.system_settings
  drop constraint if exists system_settings_id_single_row,
  add constraint system_settings_id_single_row check (id = 1);

alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

alter table public.template_versions
  add column if not exists updated_at timestamptz not null default now();

alter table public.requests
  add column if not exists updated_at timestamptz not null default now();

-- Ensure template_version references align to the selected template.
alter table public.template_versions
  drop constraint if exists template_versions_template_id_id_unique,
  add constraint template_versions_template_id_id_unique unique (template_id, id);

alter table public.items
  drop constraint if exists items_template_version_match_fk,
  add constraint items_template_version_match_fk
    foreign key (template_id, template_version_id)
    references public.template_versions(template_id, id)
    on delete restrict;

-- -----------------------------------------------------------------------------
-- Indexing for common access paths
-- -----------------------------------------------------------------------------

create index if not exists idx_profiles_department_role_active
  on public.profiles (department_id, role_code)
  where is_active = true;

create index if not exists idx_items_owner on public.items (owner_id);
create index if not exists idx_items_department on public.items (department_id);
create index if not exists idx_items_status on public.items (status);
create index if not exists idx_items_due_date on public.items (due_date);
create index if not exists idx_items_expiry_date on public.items (expiry_date);

create index if not exists idx_requests_requested_by on public.requests (requested_by);
create index if not exists idx_requests_assigned_to on public.requests (assigned_to);
create index if not exists idx_requests_item_id on public.requests (item_id);
create index if not exists idx_requests_status on public.requests (status);

create index if not exists idx_templates_department_active
  on public.templates (department_id, is_active);

create index if not exists idx_template_versions_template_created
  on public.template_versions (template_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Updated-at triggers
-- -----------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

alter table public.departments
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists trg_departments_updated_at on public.departments;
create trigger trg_departments_updated_at
before update on public.departments
for each row execute function public.set_updated_at();

alter table public.roles
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists trg_roles_updated_at on public.roles;
create trigger trg_roles_updated_at
before update on public.roles
for each row execute function public.set_updated_at();

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_templates_updated_at on public.templates;
create trigger trg_templates_updated_at
before update on public.templates
for each row execute function public.set_updated_at();

drop trigger if exists trg_template_versions_updated_at on public.template_versions;
create trigger trg_template_versions_updated_at
before update on public.template_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_items_updated_at on public.items;
create trigger trg_items_updated_at
before update on public.items
for each row execute function public.set_updated_at();

drop trigger if exists trg_requests_updated_at on public.requests;
create trigger trg_requests_updated_at
before update on public.requests
for each row execute function public.set_updated_at();

drop trigger if exists trg_system_settings_updated_at on public.system_settings;
create trigger trg_system_settings_updated_at
before update on public.system_settings
for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS helper functions
-- -----------------------------------------------------------------------------

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role_code
  from public.profiles p
  where p.user_id = auth.uid()
    and p.is_active = true
  limit 1;
$$;

create or replace function public.current_user_department_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.department_id
  from public.profiles p
  where p.user_id = auth.uid()
    and p.is_active = true
  limit 1;
$$;

create or replace function public.is_gm_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('system_admin', 'general_manager'), false);
$$;

create or replace function public.can_read_profile(target_user_id uuid, target_department_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth.uid() = target_user_id
    or public.is_gm_or_admin()
    or (
      public.current_user_role() in ('supervisor', 'dept_manager')
      and public.current_user_department_id() = target_department_id
    );
$$;

create or replace function public.can_read_item(target_owner_id uuid, target_department_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_gm_or_admin()
    or (
      public.current_user_role() = 'employee'
      and auth.uid() = target_owner_id
    )
    or (
      public.current_user_role() = 'supervisor'
      and (
        auth.uid() = target_owner_id
        or public.current_user_department_id() = target_department_id
      )
    )
    or (
      public.current_user_role() = 'dept_manager'
      and public.current_user_department_id() = target_department_id
    );
$$;

create or replace function public.can_manage_templates_for_department(target_department_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_gm_or_admin()
    or (
      public.current_user_role() = 'dept_manager'
      and public.current_user_department_id() = target_department_id
    );
$$;

create or replace function public.can_read_request(
  target_requested_by uuid,
  target_assigned_to uuid,
  item_department_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_gm_or_admin()
    or (
      exists (
        select 1
        from public.profiles p
        where p.user_id = auth.uid()
          and p.is_active = true
      )
      and (
        auth.uid() = target_requested_by
        or auth.uid() = target_assigned_to
      )
    )
    or (
      public.current_user_role() in ('supervisor', 'dept_manager')
      and public.current_user_department_id() = item_department_id
    );
$$;

-- -----------------------------------------------------------------------------
-- RLS policies
-- -----------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.requests enable row level security;
alter table public.templates enable row level security;
alter table public.template_versions enable row level security;

drop policy if exists profiles_select_policy on public.profiles;
create policy profiles_select_policy
on public.profiles
for select
using (public.can_read_profile(user_id, department_id));

drop policy if exists items_select_policy on public.items;
create policy items_select_policy
on public.items
for select
using (public.can_read_item(owner_id, department_id));

drop policy if exists requests_select_policy on public.requests;
create policy requests_select_policy
on public.requests
for select
using (
  public.can_read_request(
    requested_by,
    assigned_to,
    (
      select i.department_id
      from public.items i
      where i.id = requests.item_id
      limit 1
    )
  )
);

drop policy if exists templates_select_policy on public.templates;
create policy templates_select_policy
on public.templates
for select
using (auth.role() = 'authenticated');

drop policy if exists templates_insert_policy on public.templates;
create policy templates_insert_policy
on public.templates
for insert
with check (public.can_manage_templates_for_department(department_id));

drop policy if exists templates_update_policy on public.templates;
create policy templates_update_policy
on public.templates
for update
using (public.can_manage_templates_for_department(department_id))
with check (public.can_manage_templates_for_department(department_id));

drop policy if exists templates_delete_policy on public.templates;
create policy templates_delete_policy
on public.templates
for delete
using (public.can_manage_templates_for_department(department_id));

drop policy if exists template_versions_select_policy on public.template_versions;
create policy template_versions_select_policy
on public.template_versions
for select
using (auth.role() = 'authenticated');

drop policy if exists template_versions_insert_policy on public.template_versions;
create policy template_versions_insert_policy
on public.template_versions
for insert
with check (
  exists (
    select 1
    from public.templates t
    where t.id = template_versions.template_id
      and public.can_manage_templates_for_department(t.department_id)
  )
);

drop policy if exists template_versions_update_policy on public.template_versions;
create policy template_versions_update_policy
on public.template_versions
for update
using (
  exists (
    select 1
    from public.templates t
    where t.id = template_versions.template_id
      and public.can_manage_templates_for_department(t.department_id)
  )
)
with check (
  exists (
    select 1
    from public.templates t
    where t.id = template_versions.template_id
      and public.can_manage_templates_for_department(t.department_id)
  )
);

drop policy if exists template_versions_delete_policy on public.template_versions;
create policy template_versions_delete_policy
on public.template_versions
for delete
using (
  exists (
    select 1
    from public.templates t
    where t.id = template_versions.template_id
      and public.can_manage_templates_for_department(t.department_id)
  )
);
