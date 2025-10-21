import { supabase } from './supabase';

export async function getUserId(): Promise<string | null> {
  const { data, error } = await supabase.auth.getSession();
  if (error) return null;
  return data?.session?.user?.id ?? null;
}
