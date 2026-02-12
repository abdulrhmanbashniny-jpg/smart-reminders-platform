import Link from 'next/link';
import { requireUser } from '../lib/server/auth';

export default async function Home() {
  await requireUser();

  return (
    <section className="card">
      <h1>منصة التذكيرات الذكية</h1>
      <p>مرحبا بك 👋 — هذه نسخة تأسيسية (Scaffolding) للبدء بالتنفيذ.</p>
      <ul>
        <li>✅ Work Queue (قريبًا)</li>
        <li>✅ Item Details (قريبًا)</li>
        <li>✅ Approvals Inbox (قريبًا)</li>
        <li>✅ Templates & Policies (قريبًا)</li>
      </ul>
      <p>
        جرّب صفحة <Link href="/me">/me</Link> لمراجعة الصلاحية والقسم الحاليين.
      </p>
      <p className="hint">
        التوثيق: افتح مجلد <code>/docs</code> داخل المستودع.
      </p>
    </section>
  );
}
