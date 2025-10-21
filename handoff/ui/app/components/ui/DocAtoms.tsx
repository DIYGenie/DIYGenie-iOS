import React from 'react';
import { View, Text } from 'react-native';

export const Section = ({ title, children }: { title: string; children: any }) => (
  <View style={{ backgroundColor: '#F8FAFF', borderRadius: 16, padding: 16, marginBottom: 14 }}>
    <Text style={{ fontSize: 20, fontWeight: '700', marginBottom: 8 }}>{title}</Text>
    {children}
  </View>
);

export const Bullets = ({ items }: { items: string[] }) => (
  <View style={{ gap: 6 }}>
    {items.map((t, i) => <Text key={i}>{'\u2022'} {t}</Text>)}
  </View>
);

export const Paragraph = ({ children }: { children: any }) => (
  <Text style={{ marginBottom: 8, lineHeight: 20 }}>{children}</Text>
);

export const DimText = ({ children, style }: { children: any; style?: any }) => (
  <Text style={[{ color: '#6B7280' }, style]}>{children}</Text>
);

export const Subtle = ({ children }: { children: any }) => (
  <Text style={{ color: '#6B7280', fontStyle: 'italic', marginTop: 6 }}>{children}</Text>
);

export const Step = ({ n, title, children }: { n: number; title?: string; children: any }) => (
  <View style={{ marginBottom: 12 }}>
    <Text style={{ fontWeight: '700', marginBottom: 6 }}>{n}. {title ?? 'Step'}</Text>
    {children}
  </View>
);
