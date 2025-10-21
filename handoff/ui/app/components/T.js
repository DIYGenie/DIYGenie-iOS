import React from 'react';
import { Text, StyleSheet } from 'react-native';
import { typography } from '../../theme/typography';

export default function T({ style, ...props }) {
  return <Text style={[styles.text, style]} {...props} />;
}

const styles = StyleSheet.create({
  text: {
    fontFamily: typography.fontFamily.inter,
    fontSize: typography.fontSize.md,
    color: '#0F172A',
  },
});
