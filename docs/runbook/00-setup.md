# إعداد المشروع (Setup)

## المتطلبات
- Node.js 18+
- Docker (لتشغيل Supabase CLI محليًا)
- Supabase CLI
- حساب Supabase (Cloud Project)
- حساب Vercel (للنشر لاحقًا)

## 1) إعداد Supabase CLI
```bash
npm install -g supabase
supabase --version
```

## 2) ربط المشروع مع Supabase
من جذر المشروع:
```bash
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
```

## 3) تشغيل قاعدة البيانات محليًا (اختياري لكن موصى به)
```bash
supabase start
```

## 4) تشغيل المايجريشن + البذور (Seed)
### محليًا
```bash
supabase db reset
```
> الأمر ينفّذ كل ملفات `supabase/migrations` ثم `supabase/seed`.

### على مشروع Supabase السحابي
```bash
supabase db push
supabase db seed
```

## 5) التحقق من التنفيذ (SQL Validation)
نفّذ التالي من SQL Editor في Supabase Dashboard أو عبر `psql`:

```sql
-- الجداول الأساسية
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'departments','roles','profiles','templates','template_versions',
    'items','item_field_values','requests','notification_log','audit_log','system_settings'
  )
order by table_name;

-- تفعيل RLS على الجداول المطلوبة
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles','items','requests','templates','template_versions')
order by tablename;

-- السياسات المعرفة
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles','items','requests','templates','template_versions')
order by tablename, policyname;

-- فحص seed للإعدادات
select id, send_window_start, send_window_end, timezone
from public.system_settings;
```

## 6) متغيرات البيئة للواجهة (لاحقًا)
أنشئ ملف `.env.local` داخل `apps/web`:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (للاستخدام في server helpers فقط)

## 7) تشغيل الواجهة محليًا (اختياري في هذه المرحلة)
داخل `apps/web`:
```bash
npm install
npm run dev
```

## ملاحظات Supabase Dashboard (خطوات يدوية)
- من **Authentication > Users** أنشئ مستخدمين اختباريين.
- أضف لكل مستخدم سجلًا مقابلًا في جدول `public.profiles` مع `department_id` و`role_code` صحيحين.
- اختبر RLS عبر SQL Editor باستخدام `set local role authenticated;` و JWT Claims أو من خلال التطبيق لاحقًا.


## 8) إعداد روابط Supabase Auth للتطوير المحلي
من لوحة Supabase:
- **Authentication > URL Configuration**
- اضبط **Site URL** إلى:
  - `http://localhost:3000`
- أضف **Redirect URLs** التالية (على الأقل):
  - `http://localhost:3000`
  - `http://localhost:3000/login`
  - `http://127.0.0.1:3000`
  - `http://127.0.0.1:3000/login`

> حتى مع تسجيل الدخول بالبريد/كلمة المرور، ضبط هذه الروابط مبكرًا يمنع مشاكل إعادة التوجيه لاحقًا عند إضافة OAuth أو روابط magic link.

وتأكد أن ملف `apps/web/.env.local` يحتوي:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

## 9) إعداد قواعد الفروع (GitHub Branch Ruleset)
إذا ظهر لك في GitHub طلب تفعيل حماية الفروع، استخدم الإعدادات التالية على فرع `main`:

- **Require a pull request before merging** ✅
- **Require linear history** ✅
- **Block force pushes** ✅
- **Restrict deletions** ✅
- **Require status checks to pass** ✅ (بعد تفعيل CI checks)
- **Require signed commits** (اختياري حسب سياسة الفريق)

خطوات سريعة:
1. ادخل: `Settings > Rulesets > New branch ruleset`.
2. في **Target branches** اختر الفرع `main`.
3. فعّل القواعد أعلاه.
4. أضف نفسك/المدراء فقط في **Bypass list** إذا احتجت صلاحيات طوارئ.

> الهدف: منع التعديل المباشر على `main` وفرض المراجعة عبر Pull Request.

