import * as React from 'react';
import { BottomTabBarHeightContext } from '@react-navigation/bottom-tabs';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

/**
 * Safe tab-bar height:
 * - Inside a Tab navigator → the real height
 * - Outside a Tab navigator → use bottom safe-area (or 0)
 */
export default function useOptionalTabBarHeight() {
  // Read the context directly; undefined outside tabs
  // @ts-ignore - internal context is safe to read
  const ctx: number | undefined = React.useContext(BottomTabBarHeightContext);
  const { bottom } = useSafeAreaInsets();
  return typeof ctx === 'number' ? ctx : (bottom ?? 0);
}
