/**
 * User hook - gets current authenticated user from Supabase
 * Falls back to development user if not authenticated
 */

import { useState, useEffect } from 'react';
import { supabase } from './storage';

const DEV_USER_ID = '4e599cea-dfe5-4a8f-9738-bea3631ee4e6';

export function useUser() {
  const [userId, setUserId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const getUser = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          setUserId(user.id);
        } else {
          // Development fallback
          setUserId(DEV_USER_ID);
        }
      } catch (error) {
        console.warn('Auth check failed, using dev user:', error);
        setUserId(DEV_USER_ID);
      } finally {
        setLoading(false);
      }
    };

    getUser();
  }, []);

  return { userId, loading };
}
