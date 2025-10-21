import React, { useRef } from 'react';
import { Pressable, Animated } from 'react-native';
import * as Haptics from 'expo-haptics';

export default function PressableScale({
  onPress,
  onPressIn: customPressIn,
  onPressOut: customPressOut,
  children,
  scaleTo = 0.98,
  haptic = 'light',
  style,
  ...props
}) {
  const scaleAnim = useRef(new Animated.Value(1)).current;

  const handlePressIn = () => {
    Animated.timing(scaleAnim, {
      toValue: scaleTo,
      duration: 120,
      useNativeDriver: true,
    }).start();
    customPressIn?.();
  };

  const handlePressOut = () => {
    Animated.timing(scaleAnim, {
      toValue: 1,
      duration: 120,
      useNativeDriver: true,
    }).start();
    customPressOut?.();
  };

  const handlePress = () => {
    if (haptic !== 'none') {
      const impactStyle = haptic === 'medium' 
        ? Haptics.ImpactFeedbackStyle.Medium 
        : Haptics.ImpactFeedbackStyle.Light;
      Haptics.impactAsync(impactStyle);
    }
    onPress?.();
  };

  return (
    <Pressable
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      onPress={handlePress}
      android_ripple={{ 
        color: 'rgba(0,0,0,0.08)', 
        borderless: false 
      }}
      {...props}
    >
      <Animated.View style={[style, { transform: [{ scale: scaleAnim }] }]}>
        {children}
      </Animated.View>
    </Pressable>
  );
}
