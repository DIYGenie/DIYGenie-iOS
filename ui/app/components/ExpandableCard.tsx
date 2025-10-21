import React, { useState, memo, ReactNode } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';

interface ExpandableCardProps {
  title: string;
  count?: number;
  children: ReactNode;
  previewCount?: number;
  footer?: ReactNode;
  defaultOpen?: boolean;
}

function ExpandableCard({ 
  title, 
  count, 
  children, 
  previewCount = 3, 
  footer,
  defaultOpen = false 
}: ExpandableCardProps) {
  const [open, setOpen] = useState(defaultOpen);

  const childArray = React.Children.toArray(children);
  const visible = open ? childArray : childArray.slice(0, previewCount);
  const remaining = Math.max(0, childArray.length - visible.length);

  return (
    <View style={styles.card}>
      <Pressable onPress={() => setOpen(v => !v)} style={styles.header}>
        <Text style={styles.title}>{title}</Text>
        {count !== undefined && (
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{count}</Text>
          </View>
        )}
      </Pressable>

      <View style={styles.body}>
        {visible}
        {!open && remaining > 0 && (
          <Text style={styles.more}>+{remaining} more…</Text>
        )}
      </View>

      {footer && <View style={styles.footer}>{footer}</View>}
    </View>
  );
}

export default memo(ExpandableCard);

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginBottom: 14,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  title: { 
    fontSize: 18, 
    fontWeight: '700', 
    color: '#13151A',
    flex: 1,
  },
  badge: {
    backgroundColor: '#F0AD4E',
    paddingHorizontal: 10,
    height: 26,
    minWidth: 26,
    borderRadius: 13,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { 
    color: '#fff', 
    fontWeight: '700',
    fontSize: 14,
  },
  body: { 
    paddingTop: 4, 
    gap: 8 
  },
  more: { 
    marginTop: 6, 
    color: '#6B7280',
    fontSize: 14,
  },
  footer: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
});
