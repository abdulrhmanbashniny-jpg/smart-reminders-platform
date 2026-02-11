import { supabaseAdmin } from './supabaseAdmin';

export const APP_ROLES = [
  'system_admin',
  'general_manager',
  'dept_manager',
  'supervisor',
  'employee',
] as const;

export type AppRole = (typeof APP_ROLES)[number];

export type UserProfile = {
  user_id: string;
  department_id: string | null;
  role_code: AppRole;
  is_active: boolean;
};

export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('user_id, department_id, role_code, is_active')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data as UserProfile | null;
}

export function isAdminOrGeneralManager(role: AppRole): boolean {
  return role === 'system_admin' || role === 'general_manager';
}

export function canManageTemplates(role: AppRole): boolean {
  return isAdminOrGeneralManager(role) || role === 'dept_manager';
}
