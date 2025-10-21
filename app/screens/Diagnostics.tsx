import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView, Platform, Linking } from 'react-native';
import Constants from 'expo-constants';
import { API_BASE } from '../lib/api';
import { softHealthCheck } from '../lib/health';

export default function Diagnostics(){
  const [last, setLast] = useState<any>(null);
  const [ping, setPing] = useState<number | null>(null);
  const [modes, setModes] = useState<any>(null);
  
  const info = {
    name: Constants?.expoConfig?.name,
    version: Constants?.expoConfig?.version,
    appEnv: (Constants?.expoConfig as any)?.extra?.appEnv,
    apiBase: API_BASE,
  };

  const buildNumber = Platform.OS === 'ios' 
    ? Constants?.expoConfig?.ios?.buildNumber 
    : Constants?.expoConfig?.android?.versionCode;

  const run = async () => {
    console.log('[diag] run health');
    try {
      const result = await softHealthCheck();
      setPing(result?.ms ?? null);
      setModes(result?.json?.modes ?? null);
      setLast(result?.json ?? { error: 'No response' });
    } catch (e) {
      setLast({ error: String(e) });
      setPing(null);
      setModes(null);
    }
  };

  const handleSupport = () => {
    const metadata = {
      version: info.version,
      appEnv: info.appEnv,
      device: `${Platform.OS} ${Platform.Version}`,
      apiBase: info.apiBase,
      modes: modes,
      lastError: (global as any).__lastError || null,
    };
    const body = `Please describe your issue:\n\n\n\n---\nDiagnostics:\n${JSON.stringify(metadata, null, 2)}`;
    const subject = `DIY Genie TestFlight Feedback v${info.version}`;
    const mailto = `mailto:support@diygenieapp.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    console.log('[diag] support');
    Linking.openURL(mailto);
  };

  const modesStr = modes 
    ? `decor8/${modes.decor8 || 'n/a'}, openai/${modes.openai || 'n/a'}`
    : 'n/a';

  return (
    <ScrollView contentContainerStyle={{ padding:16 }}>
      <Text style={{ fontSize:18, fontWeight:'700', marginBottom:8 }}>Diagnostics</Text>
      <Text>Name: {info.name}</Text>
      <Text>Version: {info.version}</Text>
      <Text>Env: {info.appEnv}</Text>
      <Text>API: {info.apiBase}</Text>

      <View style={{ marginTop:12, padding:10, backgroundColor:'#F3F4F6', borderRadius:8 }}>
        <Text style={{ fontSize:12, color:'#6B7280' }}>
          Build: {info.version} ({buildNumber || 'n/a'}) · Ping: {ping !== null ? `${ping}ms` : 'n/a'} · Mode: {modesStr}
        </Text>
      </View>

      <TouchableOpacity onPress={run}
        style={{ marginTop:16, backgroundColor:'#6D28D9', borderRadius:12, padding:12, alignItems:'center' }}>
        <Text style={{ color:'white', fontWeight:'600' }}>Run health</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={handleSupport}
        style={{ marginTop:12, backgroundColor:'#7C3AED', borderRadius:12, padding:12, alignItems:'center' }}>
        <Text style={{ color:'white', fontWeight:'600' }}>Contact Support</Text>
      </TouchableOpacity>

      <View style={{ marginTop:16, backgroundColor:'white', borderRadius:12, padding:12 }}>
        <Text style={{ fontWeight:'600', marginBottom:6 }}>Last result</Text>
        <Text selectable style={{ fontFamily:'Menlo' }}>
          {JSON.stringify(last ?? {}, null, 2)}
        </Text>
      </View>
    </ScrollView>
  );
}
