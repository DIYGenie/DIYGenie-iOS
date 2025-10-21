import React from 'react';
import { View, Text } from 'react-native';

export default function Markdown({ content }: { content: string }) {
  if (!content) return null;
  const lines = content.split('\n');
  return (
    <View style={{ gap: 6 }}>
      {lines.map((ln, i) => {
        if (ln.startsWith('### ')) {
          return <Text key={i} style={{ fontSize: 16, fontWeight: '700', marginTop: 8 }}>{ln.slice(4)}</Text>;
        }
        if (ln.startsWith('## ')) {
          return <Text key={i} style={{ fontSize: 18, fontWeight: '800', marginTop: 10 }}>{ln.slice(3)}</Text>;
        }
        if (ln.startsWith('# ')) {
          return <Text key={i} style={{ fontSize: 20, fontWeight: '900', marginTop: 12 }}>{ln.slice(2)}</Text>;
        }
        if (ln.startsWith('- ')) {
          return <Text key={i} style={{ fontSize: 14 }}>• {ln.slice(2)}</Text>;
        }
        if (ln.trim() === '') {
          return <View key={i} style={{ height: 4 }} />;
        }
        return <Text key={i} style={{ fontSize: 14, lineHeight: 20 }}>{ln}</Text>;
      })}
    </View>
  );
}
