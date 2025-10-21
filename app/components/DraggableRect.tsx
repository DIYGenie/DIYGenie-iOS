import React, { useCallback, useMemo, useRef, useState } from 'react';
import { View, PanResponder, StyleSheet } from 'react-native';

type NormRect = { x: number; y: number; w: number; h: number }; // 0..1
type PxRect = { x: number; y: number; w: number; h: number };
type Size = { w: number; h: number };

function clamp(v: number, lo: number, hi: number) {
  'worklet'; // harmless hint if RN reanimated exists
  return Math.max(lo, Math.min(hi, v));
}

export default function DraggableRect({
  initial = { x: 0.2, y: 0.2, w: 0.5, h: 0.35 },
  onChange,
  style,
}: {
  initial?: NormRect;
  onChange?: (norm: NormRect) => void;
  style?: any;
}) {
  const [container, setContainer] = useState<Size>({ w: 1, h: 1 });
  const [rect, setRect] = useState<PxRect>({ x: 0, y: 0, w: 0, h: 0 });
  const ready = useRef(false);
  const MIN_SIDE = 120; // px – initial rectangle won't be tiny

  const toNorm = useCallback(
    (r: PxRect): NormRect => ({
      x: r.x / container.w,
      y: r.y / container.h,
      w: r.w / container.w,
      h: r.h / container.h,
    }),
    [container.w, container.h]
  );

  const fromNorm = useCallback(
    (n: NormRect): PxRect => ({
      x: n.x * container.w,
      y: n.y * container.h,
      w: n.w * container.w,
      h: n.h * container.h,
    }),
    [container.w, container.h]
  );

  const update = useCallback(
    (next: PxRect) => {
      const clamped: PxRect = {
        x: clamp(next.x, 0, container.w - 24),
        y: clamp(next.y, 0, container.h - 24),
        w: clamp(next.w, 24, container.w),
        h: clamp(next.h, 24, container.h),
      };
      // keep in bounds
      clamped.w = Math.min(clamped.w, container.w - clamped.x);
      clamped.h = Math.min(clamped.h, container.h - clamped.y);

      console.log('[roi bounds] clamping to container:', { container, next, clamped });
      setRect(clamped);
      const norm = toNorm(clamped);
      console.log('[scan overlay] region selected', norm);
      onChange?.(norm);
    },
    [container.w, container.h, onChange, toNorm]
  );

  const dragResponder = useMemo(
    () =>
      PanResponder.create({
        // Let children (corner handles) win first.
        onStartShouldSetPanResponderCapture: () => false,
        onMoveShouldSetPanResponderCapture: () => false,
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: (_e, g) => Math.abs(g.dx) + Math.abs(g.dy) > 2,
        onPanResponderTerminationRequest: () => false,
        onPanResponderMove: (_e, g) => {
          update({ ...rect, x: rect.x + g.dx, y: rect.y + g.dy });
        },
      }),
    [rect, update]
  );

  function handleHandleDrag(which: 'tl' | 'tr' | 'bl' | 'br') {
    return PanResponder.create({
      // Corner handles must capture the gesture immediately
      onStartShouldSetPanResponderCapture: () => true,
      onMoveShouldSetPanResponderCapture: () => true,
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderTerminationRequest: () => false,
      onPanResponderMove: (_e, g) => {
        let { x, y, w, h } = rect;
        if (which === 'tl') {
          const nx = clamp(x + g.dx, 0, x + w - 24);
          const ny = clamp(y + g.dy, 0, y + h - 24);
          w = w - (nx - x);
          h = h - (ny - y);
          x = nx;
          y = ny;
        } else if (which === 'tr') {
          const ny = clamp(y + g.dy, 0, y + h - 24);
          const nw = clamp(w + g.dx, 24, container.w - x);
          h = h - (ny - y);
          y = ny;
          w = nw;
        } else if (which === 'bl') {
          const nx = clamp(x + g.dx, 0, x + w - 24);
          const nh = clamp(h + g.dy, 24, container.h - y);
          w = w - (nx - x);
          x = nx;
          h = nh;
        } else {
          // br
          const nw = clamp(w + g.dx, 24, container.w - x);
          const nh = clamp(h + g.dy, 24, container.h - y);
          w = nw;
          h = nh;
        }
        update({ x, y, w, h });
      },
    });
  }

  return (
    <View
      style={[{ width: '100%', aspectRatio: 4 / 3, overflow: 'visible' }, style]}
      pointerEvents="box-none"
      onLayout={(e) => {
        const { width, height } = e.nativeEvent.layout;
        const sz = { w: width, h: height };
        setContainer(sz);
        console.log('[roi bounds] container measured:', sz);
        if (!ready.current && width > 0 && height > 0) {
          ready.current = true;
          // Start centered with a reasonable minimum size
          const base = fromNorm(initial); // px from provided normalized initial
          const w0 = Math.max(base.w, MIN_SIDE);
          const h0 = Math.max(base.h, MIN_SIDE);
          const x0 = Math.max((sz.w - w0) / 2, 0);
          const y0 = Math.max((sz.h - h0) / 2, 0);
          const px = { x: x0, y: y0, w: Math.min(w0, sz.w), h: Math.min(h0, sz.h) };
          setRect(px);
          console.log('[roi bounds] initial box:', px);
          onChange?.(toNorm(px));
        }
      }}
    >
      {/* Rect */}
      <View
        {...dragResponder.panHandlers}
        pointerEvents="auto"
        style={[
          styles.rect,
          {
            left: rect.x,
            top: rect.y,
            width: rect.w,
            height: rect.h,
          },
        ]}
      >
        {/* Handles */}
        <View {...handleHandleDrag('tl').panHandlers} pointerEvents="auto" style={[styles.handle, styles.tl]} />
        <View {...handleHandleDrag('tr').panHandlers} pointerEvents="auto" style={[styles.handle, styles.tr]} />
        <View {...handleHandleDrag('bl').panHandlers} pointerEvents="auto" style={[styles.handle, styles.bl]} />
        <View {...handleHandleDrag('br').panHandlers} pointerEvents="auto" style={[styles.handle, styles.br]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  rect: {
    position: 'absolute',
    borderWidth: 3,
    borderColor: 'rgba(147, 51, 234, 0.8)',
    borderRadius: 12,
    backgroundColor: 'rgba(147, 51, 234, 0.4)',
  },
  handle: {
    position: 'absolute',
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#7C3AED',
    shadowOpacity: 0.2,
    shadowRadius: 2,
  },
  tl: { left: -14, top: -14 },
  tr: { right: -14, top: -14 },
  bl: { left: -14, bottom: -14 },
  br: { right: -14, bottom: -14 },
});
