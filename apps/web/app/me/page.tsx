import { requireUser } from '../../lib/server/auth';
import { supabaseAdmin } from '../../lib/server/supabaseAdmin';

export default async function MePage() {
  const user = await requireUser();

  const { data: profile, error } = await supabaseAdmin
    .from('profiles')
    .select('full_name, role_code, departments(name_ar, code)')
    .eq('user_id', user.id)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (
    <section className="card">
      <h1>ملفي</h1>
      <p>الاسم: {profile?.full_name || user.email}</p>
      <p>الدور: {profile?.role_code ?? 'غير محدد'}</p>
      <p>
        القسم:{' '}
        {profile?.departments
          ? `${profile.departments.name_ar} (${profile.departments.code})`
          : 'غير محدد'}
      </p>
      <p className="hint">User ID: {user.id}</p>
    </section>
  );
}
