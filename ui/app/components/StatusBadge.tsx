import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { typography } from '../../theme/typography';
import { brand } from '../../theme/colors';

interface StatusBadgeProps {
  status: string;
  hasInputImage?: boolean;
}

export default function StatusBadge({ status, hasInputImage }: StatusBadgeProps) {
  let badgeText = '';
  let badgeColor = '#6B7280';

  if (status === 'draft' && !hasInputImage) {
    badgeText = 'Awaiting photo';
    badgeColor = '#6B7280';
  } else if (status === 'preview_requested') {
    badgeText = 'Preview requested';
    badgeColor = brand.primary;
  } else if (status === 'preview_ready') {
    badgeText = 'Preview ready';
    badgeColor = '#10B981';
  } else if (status === 'plan_requested') {
    badgeText = 'Plan requested';
    badgeColor = brand.primary;
  } else if (status === 'plan_ready') {
    badgeText = 'Plan ready';
    badgeColor = '#10B981';
  } else if (status === 'ready') {
    badgeText = 'Plan ready';
    badgeColor = '#10B981';
  }

  if (!badgeText) return null;

  return (
    <View style={[styles.badge, { backgroundColor: `${badgeColor}15` }]}>
      <Text style={[styles.badgeText, { color: badgeColor }]}>{badgeText}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  badgeText: {
    fontSize: 12,
    fontFamily: typography.fontFamily.manropeBold,
  },
});
