-- Smart Reminders Platform (Single-Company) - Initial Schema Draft
-- NOTE: This is a draft scaffold to be finalized during implementation.

-- 1) Core reference tables
create table if not exists public.departments (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name_ar text not null,
  name_en text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, -- system_admin, general_manager, dept_manager, supervisor, employee
  name_ar text not null,
  name_en text not null
);

-- 2) Profiles (mapped to auth.users)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  department_id uuid references public.departments(id),
  role_code text not null references public.roles(code),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 3) Templates + versions
create table if not exists public.templates (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  department_id uuid not null references public.departments(id),
  name_ar text not null,
  name_en text not null,
  date_mode text not null check (date_mode in ('due','expiry','both')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.template_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.templates(id) on delete cascade,
  version int not null,
  change_reason text not null,
  policy_json jsonb not null default '{}'::jsonb,
  fields_json jsonb not null default '[]'::jsonb, -- up to 10 fields
  recipients_json jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(template_id, version)
);

-- 4) Items
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.templates(id),
  template_version_id uuid references public.template_versions(id),
  title text not null,
  reference_no text,
  priority text not null default 'normal' check (priority in ('low','normal','high','critical')),
  owner_id uuid not null references auth.users(id),
  department_id uuid not null references public.departments(id),
  due_date date,
  expiry_date date,
  status text not null default 'new' check (status in ('new','acknowledged','in_progress','pending_approval','closed')),
  acknowledged_at timestamptz,
  closed_at timestamptz,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.item_field_values (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  field_key text not null,
  value jsonb,
  unique(item_id, field_key)
);

-- 5) Requests (Change / Closure / Delegation)
create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  request_type text not null check (request_type in ('change','closure','delegation')),
  item_id uuid references public.items(id) on delete cascade,
  requested_by uuid not null references auth.users(id),
  assigned_to uuid references auth.users(id),
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  reason text not null,
  payload jsonb not null default '{}'::jsonb, -- diff, delegation dates, etc.
  decision_reason text,
  decided_by uuid references auth.users(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

-- 6) Notifications + Audit
create table if not exists public.notification_log (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references public.items(id) on delete set null,
  channel text not null check (channel in ('in_app','whatsapp','telegram','email')),
  to_ref text,
  status text not null check (status in ('sent','failed','queued')),
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id),
  entity_type text not null,
  entity_id uuid,
  action text not null,
  before jsonb,
  after jsonb,
  reason text,
  created_at timestamptz not null default now()
);

-- 7) Settings (single company)
create table if not exists public.system_settings (
  id int primary key default 1,
  company_name_ar text not null,
  company_name_en text not null,
  platform_name_ar text not null,
  platform_name_en text not null,
  send_window_start time not null default '07:00',
  send_window_end time not null default '20:00',
  ai_weekly_email text,
  ai_weekly_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
