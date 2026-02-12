-- Auth bootstrap support: first authenticated user can become system admin.

alter table public.system_settings
  add column if not exists bootstrap_admin_user_id uuid references auth.users(id);
