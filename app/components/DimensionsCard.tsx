import { View, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { MeasureResult } from '../lib/api';

export default function DimensionsCard({ measure }: { measure: MeasureResult | null }) {
  return (
    <View style={{ backgroundColor: '#F5F3FF', borderRadius: 20, padding: 16, marginHorizontal: 16, marginTop: 12 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 8 }}>
        <Ionicons name="expand-outline" size={18} color="#6D28D9" />
        <Text style={{ fontSize: 18, fontWeight: '700', marginLeft: 8 }}>Dimensions</Text>
      </View>
      {!measure ? (
        <Text style={{ color: '#6b7280' }}>Waiting for dimensions…</Text>
      ) : (
        <View style={{ gap: 6 }}>
          <Text>Width: <Text style={{ fontWeight: '700' }}>{measure.width_in.toFixed(0)} in</Text></Text>
          <Text>Height: <Text style={{ fontWeight: '700' }}>{measure.height_in.toFixed(0)} in</Text></Text>
          <Text>Pixels / inch: <Text style={{ fontWeight: '700' }}>{measure.px_per_in}</Text></Text>
          <Text style={{ color: '#6b7280', fontSize: 12 }}>
            Region: x {Math.round(measure.roi.x * 100)}% • y {Math.round(measure.roi.y * 100)}% • w {Math.round(measure.roi.w * 100)}% • h {Math.round(measure.roi.h * 100)}%
          </Text>
        </View>
      )}
    </View>
  );
}
