import React from 'react';
import { Pressable, Text, StyleSheet, ViewStyle, TextStyle, ActivityIndicator } from 'react-native';
import { brand } from '../../theme/colors';

interface ButtonProps {
  title: string;
  onPress: () => void;
  disabled?: boolean;
  testID?: string;
  style?: ViewStyle;
  loading?: boolean;
}

export function PrimaryButton({ title, onPress, disabled, testID, style, loading }: ButtonProps) {
  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.primaryButton,
        pressed && !disabled && !loading && styles.primaryButtonPressed,
        (disabled || loading) && styles.primaryButtonDisabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator size="small" color="#FFFFFF" />
      ) : (
        <Text style={styles.primaryButtonText}>{title}</Text>
      )}
    </Pressable>
  );
}

export function SecondaryButton({ title, onPress, disabled, testID, style, loading }: ButtonProps) {
  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.secondaryButton,
        pressed && !disabled && !loading && styles.secondaryButtonPressed,
        (disabled || loading) && styles.secondaryButtonDisabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator size="small" color={brand.primary} />
      ) : (
        <Text style={styles.secondaryButtonText}>{title}</Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  primaryButton: {
    backgroundColor: brand.primary,
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 16,
    minHeight: 52,
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
  },
  primaryButtonPressed: {
    opacity: 0.9,
  },
  primaryButtonDisabled: {
    backgroundColor: brand.primary700,
    opacity: 0.6,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: brand.primary,
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 16,
    minHeight: 52,
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
  },
  secondaryButtonPressed: {
    opacity: 0.9,
    backgroundColor: 'rgba(124, 58, 237, 0.05)',
  },
  secondaryButtonDisabled: {
    borderColor: brand.primary,
    opacity: 0.6,
  },
  secondaryButtonText: {
    color: brand.primary,
    fontSize: 16,
    fontWeight: '600',
  },
});
