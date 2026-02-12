'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { ensureProfileForUser } from '../../lib/server/bootstrapProfile';
import { ACCESS_TOKEN_COOKIE, REFRESH_TOKEN_COOKIE } from '../../lib/server/auth';
import { createSupabaseServerClient } from '../../lib/server/supabaseClient';

const ONE_WEEK = 60 * 60 * 24 * 7;

export async function loginAction(formData: FormData) {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '').trim();
  const fullName = String(formData.get('full_name') ?? '').trim();

  if (!email || !password) {
    redirect('/login?error=يرجى%20إدخال%20البريد%20الإلكتروني%20وكلمة%20المرور');
  }

  const supabase = createSupabaseServerClient();
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.session || !data.user) {
    redirect('/login?error=فشل%20تسجيل%20الدخول%20تحقق%20من%20البيانات');
  }

  await ensureProfileForUser({
    userId: data.user.id,
    email: data.user.email,
    fullName,
  });

  const cookieStore = cookies();
  cookieStore.set(ACCESS_TOKEN_COOKIE, data.session.access_token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: ONE_WEEK,
  });
  cookieStore.set(REFRESH_TOKEN_COOKIE, data.session.refresh_token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: ONE_WEEK,
  });

  redirect('/');
}

export async function logoutAction() {
  const cookieStore = cookies();
  cookieStore.delete(ACCESS_TOKEN_COOKIE);
  cookieStore.delete(REFRESH_TOKEN_COOKIE);
  redirect('/login');
}
