import React from 'react';
import { View, Text, Pressable } from 'react-native';

export default function SummaryCard({ title, subtitle, onPress }: {
  title: string;
  subtitle?: string;
  onPress?: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        backgroundColor: '#F4F3FF',
        borderRadius: 16,
        padding: 16,
      }}
    >
      <Text style={{ fontSize: 18, fontWeight: '700', marginBottom: 4 }}>{title}</Text>
      {!!subtitle && <Text style={{ color: '#6B7280' }}>{subtitle}</Text>}
    </Pressable>
  );
}
