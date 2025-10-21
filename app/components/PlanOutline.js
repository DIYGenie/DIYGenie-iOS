import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../theme/colors';
import { typography } from '../../theme/typography';

export default function PlanOutline({ planData }) {
  if (!planData || !planData.overview) {
    return (
      <View style={styles.container}>
        <View style={styles.emptyState}>
          <Ionicons name="document-text-outline" size={32} color={colors.muted} />
          <Text style={styles.emptyText}>Plan details not available yet</Text>
        </View>
      </View>
    );
  }

  const { overview, materials, tools, tips } = planData;
  const stepCount = overview.steps?.length || 0;
  const materialCount = materials?.length || 0;
  const toolCount = tools?.length || 0;
  const tipCount = tips?.length || 0;

  const renderSection = (icon, title, count, items, renderItem) => (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <View style={styles.sectionTitleRow}>
          <Ionicons name={icon} size={20} color={colors.accent} />
          <Text style={styles.sectionTitle}>{title}</Text>
        </View>
        {count > 0 && (
          <View style={styles.countBadge}>
            <Text style={styles.countText}>{count}</Text>
          </View>
        )}
      </View>
      
      {items && items.length > 0 ? (
        <View style={styles.itemList}>
          {items.slice(0, 3).map((item, index) => (
            <Text key={index} style={styles.itemText} numberOfLines={1} ellipsizeMode="tail">
              {renderItem(item)}
            </Text>
          ))}
          {items.length > 3 && (
            <Text style={styles.moreText}>+{items.length - 3} more...</Text>
          )}
        </View>
      ) : (
        <Text style={styles.emptyItemText}>No items yet</Text>
      )}
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.outlineTitle}>Plan Outline</Text>
      
      <View style={styles.card}>
        {renderSection(
          'list-outline',
          'Overview',
          stepCount,
          overview.steps,
          (step) => step.title
        )}

        <View style={styles.divider} />

        {renderSection(
          'cube-outline',
          'Materials',
          materialCount,
          materials,
          (item) => `• ${item.qty} × ${item.name}`
        )}

        <View style={styles.divider} />

        {renderSection(
          'construct-outline',
          'Tools',
          toolCount,
          tools,
          (tool) => `• ${tool.name}`
        )}

        <View style={styles.divider} />

        {renderSection(
          'bulb-outline',
          'AI Tips',
          tipCount,
          tips,
          (tip) => `• ${tip.body}`
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 16,
  },
  outlineTitle: {
    fontSize: 18,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    marginBottom: 12,
    paddingHorizontal: 16,
  },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    marginHorizontal: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  section: {
    paddingVertical: 12,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  sectionTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  sectionTitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
  },
  countBadge: {
    backgroundColor: colors.accent,
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
    minWidth: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  countText: {
    fontSize: 12,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#FFF',
  },
  itemList: {
    gap: 6,
  },
  itemText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
    lineHeight: 20,
  },
  moreText: {
    fontSize: 13,
    fontFamily: typography.fontFamily.interItalic,
    color: colors.textSecondary,
    marginTop: 4,
  },
  emptyItemText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.muted,
    fontStyle: 'italic',
  },
  divider: {
    height: 1,
    backgroundColor: colors.muted,
    marginVertical: 8,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    backgroundColor: colors.surface,
    borderRadius: 16,
    marginHorizontal: 16,
  },
  emptyText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
    marginTop: 12,
  },
});
