import { useRef } from 'react';
import { Animated } from 'react-native';

export function useShake() {
  const x = useRef(new Animated.Value(0)).current;
  const shake = () => {
    x.setValue(0);
    Animated.sequence([
      Animated.timing(x, { toValue: 8, duration: 60, useNativeDriver: true }),
      Animated.timing(x, { toValue: -8, duration: 60, useNativeDriver: true }),
      Animated.timing(x, { toValue: 6, duration: 50, useNativeDriver: true }),
      Animated.timing(x, { toValue: -6, duration: 50, useNativeDriver: true }),
      Animated.timing(x, { toValue: 0, duration: 50, useNativeDriver: true }),
    ]).start();
  };
  const style = { transform: [{ translateX: x }] };
  return { shake, style };
}
