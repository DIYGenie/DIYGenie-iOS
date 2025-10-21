import React, { useRef, useState } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../theme/colors';
import PressableScale from './ui/PressableScale';

export default function HowItWorksTile({
  icon = 'create-outline',
  label,
  onPress,
  a11yLabel,
  stepNumber,
}) {
  const [isPressed, setIsPressed] = useState(false);
  const opacityAnim = useRef(new Animated.Value(0.7)).current;

  const handlePressIn = () => {
    setIsPressed(true);
    Animated.timing(opacityAnim, {
      toValue: 1,
      duration: 120,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = () => {
    setIsPressed(false);
    Animated.timing(opacityAnim, {
      toValue: 0.7,
      duration: 120,
      useNativeDriver: true,
    }).start();
  };

  const accessibilityLabel = stepNumber 
    ? `${label} (step ${stepNumber} of 4)` 
    : a11yLabel;

  return (
    <PressableScale
      onPress={onPress}
      haptic="light"
      scaleTo={0.98}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[
        styles.tile,
        { backgroundColor: isPressed ? colors.diy.tilePressed : colors.diy.tileBg }
      ]}
    >
      <Animated.View style={{ opacity: opacityAnim }}>
        <Ionicons name={icon} size={22} color={colors.brand} />
      </Animated.View>
      <Text style={styles.label}>{label}</Text>
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  tile: {
    minHeight: 72,
    minWidth: '48%',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.diy.tileBorder,
    paddingVertical: 14,
    paddingHorizontal: 14,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 6,
  },
  label: {
    fontSize: 15,
    fontWeight: '600',
    color: '#1F1F1F',
  },
});
