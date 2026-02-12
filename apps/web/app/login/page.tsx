import { redirect } from 'next/navigation';
import { loginAction } from '../actions/auth';
import { getCurrentUser } from '../../lib/server/auth';

type LoginPageProps = {
  searchParams?: { error?: string };
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const user = await getCurrentUser();

  if (user) {
    redirect('/');
  }

  return (
    <section className="card auth-card">
      <h1>تسجيل الدخول</h1>
      <p className="hint">ادخل بحساب Supabase (البريد الإلكتروني + كلمة المرور).</p>

      {searchParams?.error ? <p className="error-text">{searchParams.error}</p> : null}

      <form action={loginAction} className="auth-form">
        <label htmlFor="email">البريد الإلكتروني</label>
        <input id="email" name="email" type="email" required />

        <label htmlFor="password">كلمة المرور</label>
        <input id="password" name="password" type="password" required />

        <label htmlFor="full_name">الاسم الكامل (يُستخدم في أول تسجيل فقط)</label>
        <input id="full_name" name="full_name" type="text" placeholder="مثال: أحمد علي" />

        <button type="submit">دخول</button>
      </form>
    </section>
  );
}
