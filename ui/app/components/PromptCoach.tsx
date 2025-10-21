import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, ScrollView } from 'react-native';

type Tip = { text: string; tag?: string };
type Props = {
  tips: Tip[];
  loading?: boolean;
  onApply?: (text: string) => void;
  onRefresh?: () => void;
};

export default function PromptCoach({ tips, loading, onApply, onRefresh }: Props) {
  return (
    <View style={{ marginTop: 12 }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <Text style={{ fontWeight: '700', fontSize: 16 }}>Improve your prompt</Text>
        <TouchableOpacity onPress={onRefresh} accessibilityRole="button">
          <Text style={{ textDecorationLine: 'underline' }}>{loading ? 'Loading…' : 'Refresh'}</Text>
        </TouchableOpacity>
      </View>

      {loading ? <ActivityIndicator /> : null}

      {!loading && tips.length === 0 ? (
        <Text style={{ opacity: 0.6 }}>Tips will appear after you add a photo or describe your project.</Text>
      ) : (
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 4 }}>
          {tips.map((t, i) => (
            <TouchableOpacity
              key={i}
              onPress={() => onApply?.(t.text)}
              style={{
                paddingVertical: 8,
                paddingHorizontal: 12,
                borderRadius: 9999,
                borderWidth: 1,
                borderColor: '#DDD',
                marginRight: 8,
              }}
            >
              <Text>{t.text}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      )}
    </View>
  );
}
