import React, { useMemo, useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { Plan } from '../lib/plan';

const pill = (active: boolean) => ({
  paddingHorizontal: 14, paddingVertical: 8, borderRadius: 16,
  backgroundColor: active ? '#6D28D9' : '#EEF2FF', marginRight: 8,
});
const pillTxt = (active: boolean) => ({
  color: active ? 'white' : '#111827', fontWeight: '700' as const
});

export default function PlanTabs({ plan }: { plan: Plan }) {
  const tabs = useMemo(() => ([
    { key: 'Overview', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Overview</Text>
        <Text>{plan.overview ?? 'High-level summary will appear here.'}</Text>
      </View>
    )},
    { key: 'Materials', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Materials</Text>
        {(plan.materials?.length ? plan.materials : []).map((m, i) => (
          <Text key={i}>• {m.name}{m.qty ? ` — ${m.qty}${m.unit ? ` ${m.unit}` : ''}` : ''}</Text>
        ))}
        {!plan.materials?.length && <Text>No materials listed yet.</Text>}
      </View>
    )},
    { key: 'Cuts', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Cut list</Text>
        {(plan.cuts?.length ? plan.cuts : []).map((c, i) => (
          <Text key={i}>• {c.part}: {c.size}{c.qty ? `  ×${c.qty}` : ''}</Text>
        ))}
        {!plan.cuts?.length && <Text>No cut list yet.</Text>}
      </View>
    )},
    { key: 'Tools', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Tools</Text>
        {(plan.tools?.length ? plan.tools : []).map((t, i) => (<Text key={i}>• {typeof t === 'string' ? t : t.name}</Text>))}
        {!plan.tools?.length && <Text>No tools listed yet.</Text>}
      </View>
    )},
    { key: 'Steps', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Steps</Text>
        {(plan.steps?.length ? plan.steps : []).map((s, i) => (
          <View key={i} style={{ marginBottom:10 }}>
            <Text style={{ fontWeight:'700' }}>{i+1}. {s.title ?? 'Step'}</Text>
            {!!s.body && <Text>{s.body}</Text>}
          </View>
        ))}
        {!plan.steps?.length && <Text>No steps yet.</Text>}
      </View>
    )},
    { key: 'Time & Cost', render: () => (
      <View style={{ backgroundColor:'#fff', borderRadius:12, padding:16 }}>
        <Text style={{ fontWeight:'700', fontSize:18, marginBottom:8 }}>Time & Cost</Text>
        <Text>Estimated time: {plan.time_estimate_hours ?? '—'} hrs</Text>
        <Text>Estimated cost: {plan.cost_estimate_usd != null ? `$${plan.cost_estimate_usd}` : '—'}</Text>
      </View>
    )},
  ]), [plan]);

  const [active, setActive] = useState(0);

  return (
    <View style={{ marginTop: 16 }}>
      <View style={{ flexDirection:'row', marginBottom:12, flexWrap:'wrap' }}>
        {tabs.map((t, i) => (
          <Pressable key={t.key} onPress={() => setActive(i)} style={pill(i===active)}>
            <Text style={pillTxt(i===active)}>{t.key}</Text>
          </Pressable>
        ))}
      </View>
      {tabs[active].render()}
    </View>
  );
}
