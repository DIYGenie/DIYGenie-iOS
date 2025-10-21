/**
 * App configuration - reads public environment variables only
 * Note: Only EXPO_PUBLIC_* vars are exposed to the client
 * Never put secrets here - use server-side env vars instead
 */

function getRequiredEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${key}\n` +
      `Please add it to your .env file or environment configuration.`
    );
  }
  return value;
}

function getOptionalEnv(key: string, defaultValue: string): string {
  return process.env[key] ?? defaultValue;
}

export const BASE_URL = getRequiredEnv('EXPO_PUBLIC_BASE_URL');
export const SUPABASE_URL = getRequiredEnv('EXPO_PUBLIC_SUPABASE_URL');
export const SUPABASE_ANON_KEY = getRequiredEnv('EXPO_PUBLIC_SUPABASE_ANON_KEY');
export const UPLOADS_BUCKET = getOptionalEnv('EXPO_PUBLIC_UPLOADS_BUCKET', 'uploads');

export const config = {
  BASE_URL,
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  UPLOADS_BUCKET,
} as const;
