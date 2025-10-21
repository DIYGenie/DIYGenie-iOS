import { supabase } from './supabase';

/**
 * Ensures a row exists in `profiles` keyed by `user_id` (your schema).
 * Returns the current user_id or throws if unauthenticated.
 */
export async function ensureProfile() {
  const { data: sessionData, error: sErr } = await supabase.auth.getSession();
  if (sErr) throw sErr;

  const uid = sessionData?.session?.user?.id;
  if (!uid) throw new Error('AUTH_REQUIRED');

  // Your schema uses profiles.user_id (NOT profiles.id)
  const { data: existing, error: selErr } = await supabase
    .from('profiles')
    .select('user_id')
    .eq('user_id', uid)
    .maybeSingle();

  if (selErr) throw selErr;

  if (!existing) {
    const { error: insErr } = await supabase
      .from('profiles')
      .insert({ user_id: uid });
    if (insErr) throw insErr;
  }

  return uid;
}

/**
 * Helper for places that only need the uid and want to be sure a profile row exists.
 */
export async function ensureUserId(): Promise<string> {
  return ensureProfile();
}
