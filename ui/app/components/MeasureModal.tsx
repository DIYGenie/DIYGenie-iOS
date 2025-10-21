import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Modal, View, Image, PanResponder, StyleSheet, Text, Pressable, LayoutChangeEvent, TextInput, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { getScanScalePxPerIn, setScanScalePxPerIn } from '../lib/measure';

type Pt = { x: number; y: number };

function clamp(v: number, min: number, max: number) {
  return Math.max(min, Math.min(max, v));
}
function dist(a: Pt, b: Pt) {
  const dx = a.x - b.x, dy = a.y - b.y;
  return Math.sqrt(dx*dx + dy*dy);
}

export default function MeasureModal({
  visible,
  scanId,
  imageUrl,
  regionId = null,
  onCancel,
  onSaveLine,
}: {
  visible: boolean;
  scanId: string;
  imageUrl: string;
  regionId?: string | null;
  onCancel: () => void;
  onSaveLine: (points: [Pt, Pt], valueInches: number) => void | Promise<void>;
}) {
  const [wrapW, setWrapW] = useState(0);
  const [wrapH, setWrapH] = useState(0);
  const [scalePxPerIn, setScale] = useState<number | null>(null);
  const [refInches, setRefInches] = useState<string>('');

  const p1 = useRef<Pt>({ x: 80, y: 120 });
  const p2 = useRef<Pt>({ x: 240, y: 120 });
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (visible && scanId) {
      getScanScalePxPerIn(scanId).then(setScale).catch(() => {});
    }
  }, [visible, scanId]);

  function onWrapLayout(e: LayoutChangeEvent) {
    const { width, height } = e.nativeEvent.layout;
    setWrapW(width); setWrapH(height);
    p1.current = { x: clamp(p1.current.x, 0, width), y: clamp(p1.current.y, 0, height) };
    p2.current = { x: clamp(p2.current.x, 0, width), y: clamp(p2.current.y, 0, height) };
    setTick(t => t + 1);
  }

  const pan1 = useMemo(() => PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderMove: (_e, g) => {
      p1.current = {
        x: clamp(p1.current.x + g.dx, 0, wrapW),
        y: clamp(p1.current.y + g.dy, 0, wrapH),
      };
      setTick(t => t + 1);
    },
  }), [wrapW, wrapH]);

  const pan2 = useMemo(() => PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderMove: (_e, g) => {
      p2.current = {
        x: clamp(p2.current.x + g.dx, 0, wrapW),
        y: clamp(p2.current.y + g.dy, 0, wrapH),
      };
      setTick(t => t + 1);
    },
  }), [wrapW, wrapH]);

  const pxLen = dist(p1.current, p2.current);
  const inches = scalePxPerIn ? (pxLen / scalePxPerIn) : null;

  async function handleSetReference() {
    const val = parseFloat(refInches);
    if (!val || val <= 0) {
      Alert.alert('Enter a positive number (inches)');
      return;
    }
    const newScale = pxLen / val;
    try {
      await setScanScalePxPerIn(scanId, newScale);
      setScale(newScale);
      Alert.alert('Calibrated', `Saved ${newScale.toFixed(3)} px/in`);
    } catch (e:any) {
      Alert.alert('Calibration failed', e?.message ?? 'Unknown error');
    }
  }

  async function handleSave() {
    if (!scalePxPerIn) {
      Alert.alert('Set reference first', 'Enter a known length and press "Set reference" so we can convert to inches.');
      return;
    }
    if (!wrapW || !wrapH) return;
    const n1: Pt = { x: p1.current.x / wrapW, y: p1.current.y / wrapH };
    const n2: Pt = { x: p2.current.x / wrapW, y: p2.current.y / wrapH };
    const valueInches = pxLen / scalePxPerIn;
    await onSaveLine([n1, n2] as [Pt, Pt], valueInches);
  }

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={S.backdrop}>
        <KeyboardAvoidingView behavior={Platform.select({ ios: 'padding', android: undefined })} style={S.sheetWrap}>
          <View style={S.sheet}>
            <Text style={S.title}>Measure</Text>
            <View style={S.imageWrap} onLayout={onWrapLayout}>
              {!!imageUrl && <Image source={{ uri: imageUrl }} style={S.image} resizeMode="contain" />}

              {/* The line */}
              <View style={[
                S.line,
                { left: Math.min(p1.current.x, p2.current.x),
                  top:  Math.min(p1.current.y, p2.current.y),
                  width: Math.max(2, Math.abs(p1.current.x - p2.current.x)),
                  height: Math.max(2, Math.abs(p1.current.y - p2.current.y)),
                }
              ]} />

              {/* Endpoints */}
              <View {...pan1.panHandlers} style={[S.handle, { transform: [{ translateX: p1.current.x - HANDLE/2 }, { translateY: p1.current.y - HANDLE/2 }] }]} />
              <View {...pan2.panHandlers} style={[S.handle, { transform: [{ translateX: p2.current.x - HANDLE/2 }, { translateY: p2.current.y - HANDLE/2 }] }]} />

              <View style={S.badge}>
                <Text style={S.badgeText}>
                  {scalePxPerIn ? `${(inches ?? 0).toFixed(1)} in` : `${Math.round(pxLen)} px`}
                </Text>
              </View>
            </View>

            {/* Calibration row (only when not calibrated yet) */}
            {!scalePxPerIn && (
              <View style={S.calRow}>
                <TextInput
                  placeholder="Reference length (in)"
                  keyboardType="decimal-pad"
                  value={refInches}
                  onChangeText={setRefInches}
                  style={S.input}
                />
                <Pressable onPress={handleSetReference} style={[S.btn, S.primary]}>
                  <Text style={S.btnText}>Set reference</Text>
                </Pressable>
              </View>
            )}

            <View style={S.row}>
              <Pressable onPress={onCancel} style={[S.btn, S.ghost]}>
                <Text style={[S.btnText, S.ghostText]}>Cancel</Text>
              </Pressable>
              <Pressable onPress={handleSave} style={[S.btn, S.primary]}>
                <Text style={S.btnText}>Save measurement</Text>
              </Pressable>
            </View>
          </View>
        </KeyboardAvoidingView>
      </View>
    </Modal>
  );
}

const HANDLE = 22;

const S = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  sheetWrap: { flex: 1, justifyContent: 'flex-end' },
  sheet: { backgroundColor: 'white', padding: 16, borderTopLeftRadius: 16, borderTopRightRadius: 16, gap: 12, maxHeight: '90%' },
  title: { fontSize: 18, fontWeight: '600' },
  imageWrap: { width: '100%', aspectRatio: 1, backgroundColor: '#f3f4f6', borderRadius: 12, overflow: 'hidden', position: 'relative' },
  image: { position: 'absolute', width: '100%', height: '100%' },
  line: {
    position: 'absolute',
    borderColor: 'rgba(17,24,39,0.9)',
    borderWidth: 2,
  },
  handle: {
    position: 'absolute',
    width: HANDLE,
    height: HANDLE,
    backgroundColor: '#6d28d9',
    borderRadius: 11,
    borderWidth: 2,
    borderColor: 'white',
  },
  badge: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(17,24,39,0.9)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  badgeText: { color: 'white', fontSize: 12, fontWeight: '600' },
  calRow: { flexDirection: 'row', gap: 8, alignItems: 'center' },
  input: { flex: 1, borderWidth: 1, borderColor: '#e5e7eb', borderRadius: 10, paddingHorizontal: 12, paddingVertical: 10 },
  row: { flexDirection: 'row', gap: 12, justifyContent: 'flex-end', marginTop: 4 },
  btn: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 10 },
  primary: { backgroundColor: '#6d28d9' },
  btnText: { color: 'white', fontWeight: '600' },
  ghost: { backgroundColor: 'transparent', borderWidth: 1, borderColor: '#e5e7eb' },
  ghostText: { color: '#111827' },
});
