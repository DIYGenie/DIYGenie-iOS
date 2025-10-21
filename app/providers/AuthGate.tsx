import React, { useEffect, useState, PropsWithChildren } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { supabase } from '../lib/supabase';
import AuthScreen from '../screens/AuthScreen';

export default function AuthGate({ children }: PropsWithChildren) {
  const [loading, setLoading] = useState(true);
  const [signedIn, setSignedIn] = useState(false);

  useEffect(() => {
    let mounted = true;

    const init = async () => {
      const { data } = await supabase.auth.getSession();
      if (!mounted) return;
      setSignedIn(!!data.session);
      setLoading(false);
    };
    init();

    const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => {
      setSignedIn(!!session);
    });

    return () => {
      mounted = false;
      sub?.subscription?.unsubscribe();
    };
  }, []);

  if (loading) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  if (!signedIn) return <AuthScreen />;

  return <>{children}</>;
}
