-- Seed: Departments + Roles + System Settings
insert into public.departments (code, name_ar, name_en) values
  ('HR', 'الموارد البشرية', 'Human Resources'),
  ('MNT', 'الصيانة', 'Maintenance'),
  ('LEGAL', 'الشؤون القانونية', 'Legal Affairs'),
  ('COL', 'إدارة التحصيل', 'Collections')
on conflict (code) do nothing;

insert into public.roles (code, name_ar, name_en) values
  ('system_admin','مدير النظام','System Admin'),
  ('general_manager','المدير العام','General Manager'),
  ('dept_manager','مدير القسم','Department Manager'),
  ('supervisor','مشرف','Supervisor'),
  ('employee','موظف','Employee')
on conflict (code) do nothing;

insert into public.system_settings (
  id,
  company_name_ar,
  company_name_en,
  platform_name_ar,
  platform_name_en,
  send_window_start,
  send_window_end,
  timezone
)
values (
  1,
  'مصنع جدة للدهانات والمعاجين',
  'Jeddah Paint Factory',
  'منصة التذكيرات الذكية',
  'Smart Reminders Platform',
  '07:00',
  '20:00',
  'Asia/Riyadh'
)
on conflict (id) do update set
  company_name_ar = excluded.company_name_ar,
  company_name_en = excluded.company_name_en,
  platform_name_ar = excluded.platform_name_ar,
  platform_name_en = excluded.platform_name_en,
  send_window_start = excluded.send_window_start,
  send_window_end = excluded.send_window_end,
  timezone = excluded.timezone;
