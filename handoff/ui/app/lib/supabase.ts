import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

const url  = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const anon = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

// Debug: Verify environment variables are loaded
console.log('[supabase:init]', {
  url_defined: !!url,
  url_length: url?.length || 0,
  anon_defined: !!anon,
  anon_length: anon?.length || 0,
});

if (!url || !anon) {
  console.error('[supabase:init] MISSING ENV VARS', {
    EXPO_PUBLIC_SUPABASE_URL: url,
    EXPO_PUBLIC_SUPABASE_ANON_KEY: anon ? '[REDACTED]' : undefined,
  });
}

export const supabase = createClient(url, anon, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
