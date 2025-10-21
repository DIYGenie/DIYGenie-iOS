import React, { memo, useMemo } from 'react';
import { View, Text } from 'react-native';

type Props = {
  widthPx: number;
  pxPerIn: number;
  primaryColor?: string;
  labelEvery?: number;
};

const RulerOverlay: React.FC<Props> = memo(({ widthPx, pxPerIn, primaryColor = '#6D28D9', labelEvery = 6 }) => {
  if (!widthPx || !pxPerIn || pxPerIn <= 0) return null;

  const inches = Math.max(0, Math.floor(widthPx / pxPerIn));
  const ticks = useMemo(() => {
    const arr = [];
    for (let i = 0; i <= inches; i++) {
      const left = Math.round(i * pxPerIn);
      const isLabeled = i % labelEvery === 0;
      arr.push({ i, left, isLabeled });
    }
    return arr;
  }, [inches, pxPerIn, labelEvery]);

  return (
    <View
      pointerEvents="none"
      style={{
        position: 'absolute',
        left: 0, right: 0, bottom: 0,
        height: 28,
        backgroundColor: 'rgba(255,255,255,0.55)',
        borderTopWidth: 1,
        borderColor: 'rgba(0,0,0,0.08)',
      }}
    >
      {/* baseline */}
      <View style={{
        position: 'absolute',
        left: 0, right: 0, bottom: 6,
        height: 2, backgroundColor: primaryColor, opacity: 0.6,
      }} />
      {/* ticks */}
      {ticks.map(t => (
        <View key={t.i} style={{ position: 'absolute', left: t.left, bottom: 6, alignItems: 'center' }}>
          <View style={{ width: 2, height: 12, backgroundColor: primaryColor, opacity: 0.9 }} />
          {t.isLabeled && (
            <Text style={{ fontSize: 10, marginTop: 2, color: '#111827', opacity: 0.8 }}>{t.i}"</Text>
          )}
        </View>
      ))}
    </View>
  );
});

export default RulerOverlay;
