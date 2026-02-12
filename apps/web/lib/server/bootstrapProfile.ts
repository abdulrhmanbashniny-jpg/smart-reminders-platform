import { supabaseAdmin } from './supabaseAdmin';
import { getDefaultFullName } from './auth';

type EnsureProfileArgs = {
  userId: string;
  email?: string;
  fullName?: string;
};

async function getHrDepartmentId(): Promise<string | null> {
  const { data, error } = await supabaseAdmin
    .from('departments')
    .select('id')
    .eq('code', 'HR')
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data?.id ?? null;
}

export async function ensureProfileForUser({ userId, email, fullName }: EnsureProfileArgs) {
  const { data: existingProfile, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (profileError) {
    throw profileError;
  }

  if (existingProfile) {
    return;
  }

  const safeFullName = fullName?.trim() || getDefaultFullName(email);

  const { data: claimedRows, error: claimError } = await supabaseAdmin
    .from('system_settings')
    .update({ bootstrap_admin_user_id: userId })
    .eq('id', 1)
    .is('bootstrap_admin_user_id', null)
    .select('bootstrap_admin_user_id');

  if (claimError) {
    throw claimError;
  }

  const claimedBootstrap = Boolean(
    claimedRows && claimedRows.length > 0 && claimedRows[0].bootstrap_admin_user_id === userId,
  );

  const departmentId = claimedBootstrap ? await getHrDepartmentId() : null;

  const { error: insertError } = await supabaseAdmin.from('profiles').insert({
    user_id: userId,
    full_name: safeFullName,
    role_code: claimedBootstrap ? 'system_admin' : 'employee',
    department_id: departmentId,
    is_active: true,
  });

  if (insertError) {
    throw insertError;
  }
}
