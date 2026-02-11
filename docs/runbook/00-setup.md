# إعداد المشروع (Setup)

## المتطلبات
- Node.js 18+
- حساب Supabase
- حساب Vercel

## المتغيرات (Environment)
أنشئ ملف `.env.local` داخل `apps/web` بناءً على:
- `apps/web/.env.example`

## تشغيل الواجهة محليًا
داخل `apps/web`:
- `npm install`
- `npm run dev`

> ملاحظة: تم تجهيز ملفات هيكلية فقط. توصيل Supabase + RLS + Edge Functions يتم في مراحل التنفيذ التالية.
