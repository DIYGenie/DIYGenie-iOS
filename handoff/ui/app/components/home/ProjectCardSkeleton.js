import React from 'react';
import { View, StyleSheet } from 'react-native';
import { colors } from '../../../theme/colors';
import Skeleton from '../ui/Skeleton';

export default function ProjectCardSkeleton({ count = 2 }) {
  return (
    <View style={styles.container}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={index} style={styles.card}>
          <Skeleton width={56} height={56} borderRadius={12} />
          <View style={styles.content}>
            <Skeleton width="55%" height={16} borderRadius={8} style={styles.title} />
            <Skeleton width="35%" height={12} borderRadius={6} />
          </View>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 16,
  },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    minHeight: 88,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 2,
  },
  content: {
    flex: 1,
    marginLeft: 16,
    justifyContent: 'center',
  },
  title: {
    marginBottom: 8,
  },
});
