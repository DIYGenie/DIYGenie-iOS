import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import StatusBadge from './StatusBadge';
import { colors } from '../../theme/colors';
import { typography } from '../../theme/typography';

export default function SummaryCard({ project }) {
  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric' 
    });
  };

  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>Summary</Text>

      <View style={styles.row}>
        <Text style={styles.label}>Description</Text>
        <Text style={styles.value} numberOfLines={2}>
          {project.description || 'No description'}
        </Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Budget</Text>
        <Text style={styles.value}>{project.budget || 'N/A'}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Skill Level</Text>
        <Text style={styles.value}>{project.skill || 'N/A'}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Status</Text>
        <StatusBadge status={project.status} hasInputImage={!!project.input_image_url} />
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Created</Text>
        <Text style={styles.value}>{formatDate(project.created_at)}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    marginTop: 16,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    marginBottom: 16,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.bg,
  },
  label: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
    flex: 1,
  },
  value: {
    fontSize: 14,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    flex: 1,
    textAlign: 'right',
  },
});
