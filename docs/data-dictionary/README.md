# قاموس البيانات (Data Dictionary)

مصطلحات أساسية (AR/EN):
- Item = عنصر
- Template = قالب
- Policy Version = نسخة سياسة
- Change Request = طلب تعديل
- Closure Request = طلب إغلاق
- Delegation Request = طلب تفويض
- Recipient = مستلم
- Overdue = متأخر عن الاستحقاق
- Expired = منتهي

## جداول النظام الأساسية

### 1) departments
- `id` (uuid, PK)
- `code` (text, unique): القيم الأساسية الحالية: `HR`, `MNT`, `LEGAL`, `COL`
- `name_ar`, `name_en`
- `created_at`, `updated_at`

### 2) roles
- `id` (uuid, PK)
- `code` (text, unique):
  - `system_admin`
  - `general_manager`
  - `dept_manager`
  - `supervisor`
  - `employee`
- `name_ar`, `name_en`
- `updated_at`

### 3) profiles (امتداد auth.users)
- `user_id` (uuid, PK, FK -> `auth.users.id`)
- `full_name`
- `department_id` (FK -> `departments.id`)
- `role_code` (FK -> `roles.code`)
- `is_active`
- `created_at`, `updated_at`

### 4) templates
- `id` (uuid, PK)
- `code` (text, unique)
- `department_id` (FK -> `departments.id`)
- `name_ar`, `name_en`
- `date_mode` (`due` / `expiry` / `both`)
- `is_active`
- `created_at`, `updated_at`

### 5) template_versions
- `id` (uuid, PK)
- `template_id` (FK -> `templates.id`)
- `version` (unique per template)
- `change_reason`
- `policy_json`, `fields_json`, `recipients_json`
- `created_by` (FK -> `auth.users.id`)
- `created_at`, `updated_at`

### 6) items
- `id` (uuid, PK)
- `template_id` (FK -> `templates.id`)
- `template_version_id` (FK مركب لضمان التطابق مع القالب)
- `title`, `reference_no`
- `priority` (`low` / `normal` / `high` / `critical`)
- `owner_id` (FK -> `auth.users.id`)
- `department_id` (FK -> `departments.id`)
- `due_date`, `expiry_date`
- `status` (`new` / `acknowledged` / `in_progress` / `pending_approval` / `closed`)
- `acknowledged_at`, `closed_at`
- `notes`
- `created_by` (FK -> `auth.users.id`)
- `created_at`, `updated_at`

### 7) item_field_values
- `id` (uuid, PK)
- `item_id` (FK -> `items.id`)
- `field_key`
- `value` (jsonb)
- قيد فريد: (`item_id`, `field_key`)

### 8) requests
- `id` (uuid, PK)
- `request_type` (`change` / `closure` / `delegation`)
- `item_id` (FK -> `items.id`)
- `requested_by`, `assigned_to` (FK -> `auth.users.id`)
- `status` (`pending` / `approved` / `rejected` / `cancelled`)
- `reason`
- `payload` (jsonb)
- `decision_reason`, `decided_by`, `decided_at`
- `created_at`, `updated_at`

### 9) notification_log
- `id` (uuid, PK)
- `item_id` (FK -> `items.id`, on delete set null)
- `channel` (`in_app` / `whatsapp` / `telegram` / `email`)
- `to_ref`
- `status` (`sent` / `failed` / `queued`)
- `meta` (jsonb)
- `created_at`

### 10) audit_log
- `id` (uuid, PK)
- `actor_id` (FK -> `auth.users.id`)
- `entity_type`, `entity_id`, `action`
- `before`, `after` (jsonb)
- `reason`
- `created_at`

### 11) system_settings (single-company)
- `id` (int, PK + CHECK `id = 1`)
- `company_name_ar`, `company_name_en`
- `platform_name_ar`, `platform_name_en`
- `send_window_start`, `send_window_end`
- `timezone` (default: `Asia/Riyadh`)
- `ai_weekly_email`, `ai_weekly_enabled`
- `updated_at`

## ملخص صلاحيات RLS (القراءة)
- `profiles`: المستخدم يقرأ نفسه، والمشرف/مدير القسم يقرأ نفس القسم، والمدير العام/مدير النظام يقرأ الجميع.
- `items`: الموظف يرى عناصره، المشرف يرى عناصره + قسمه، مدير القسم يرى عناصر قسمه، المدير العام/مدير النظام يرى الجميع.
- `requests`: مقدم الطلب يرى طلباته، المعيّن للموافقة يرى المعيّن له، المشرف/مدير القسم يرى طلبات العناصر التابعة لقسمه، المدير العام/مدير النظام يرى الجميع.
- `templates` و `template_versions`: قراءة متاحة للجميع (authenticated)، بينما الإنشاء/التحديث/الحذف محصور في `system_admin` و`general_manager` و`dept_manager` (ضمن القسم لمدير القسم).
