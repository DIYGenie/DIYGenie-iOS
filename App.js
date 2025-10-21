import "react-native-gesture-handler";
import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { useFonts } from 'expo-font';
import {
  Manrope_400Regular,
  Manrope_700Bold,
} from '@expo-google-fonts/manrope';
import {
  Inter_400Regular,
  Inter_500Medium,
} from '@expo-google-fonts/inter';
import AppNavigator from './app/navigation/AppNavigator';
import { colors } from './theme/colors';
import { typography } from './theme/typography';
import { ErrorBoundary } from './app/components/ErrorBoundary';
import { softHealthCheck } from './app/lib/health';

if (process.env.APP_ENV === 'production') {
  const _log = console.log;
  console.debug = () => {};
  console.info = _log;
  console.warn = _log;
}

if (global.ErrorUtils && typeof global.ErrorUtils.setGlobalHandler === 'function') {
  global.ErrorUtils.setGlobalHandler((e, isFatal) => {
    console.error('[crash] global', { msg: String(e?.message||e), fatal: !!isFatal });
  });
}

function App() {
  let [fontsLoaded] = useFonts({
    Manrope_400Regular,
    Manrope_700Bold,
    Inter_400Regular,
    Inter_500Medium,
  });

  useEffect(() => { 
    softHealthCheck(); 
  }, []);

  if (!fontsLoaded) {
    return null;
  }

  return (
    <ErrorBoundary>
      <SafeAreaProvider>
        <NavigationContainer>
          <StatusBar style="light" />
          <AppNavigator />
        </NavigationContainer>
      </SafeAreaProvider>
    </ErrorBoundary>
  );
}

export default App;