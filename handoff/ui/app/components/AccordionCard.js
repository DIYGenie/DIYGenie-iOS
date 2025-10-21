// app/components/AccordionCard.js
import React, { useState, memo } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';

function AccordionCard({ title, count, items = [], renderItem }) {
  const [open, setOpen] = useState(false);

  const visible = open ? items : items.slice(0, 3);
  const remaining = Math.max(0, items.length - visible.length);

  return (
    <View style={styles.card}>
      <Pressable onPress={() => setOpen(v => !v)} style={styles.header}>
        <Text style={styles.title}>{title}</Text>
        <View style={styles.badge}><Text style={styles.badgeText}>{count ?? items.length}</Text></View>
      </Pressable>

      <View style={styles.body}>
        {visible.map((it, idx) => (
          <View key={idx} style={styles.row}>
            {renderItem ? renderItem(it, idx) : <Text style={styles.rowText}>• {String(it)}</Text>}
          </View>
        ))}
        {!open && remaining > 0 && (
          <Text style={styles.more}>+{remaining} more…</Text>
        )}
      </View>
    </View>
  );
}

export default memo(AccordionCard);

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
  title: { fontSize: 18, fontWeight: '700', color: '#13151A' },
  badge: {
    backgroundColor: '#F0AD4E',
    paddingHorizontal: 10,
    height: 26,
    minWidth: 26,
    borderRadius: 13,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { color: '#fff', fontWeight: '700' },
  body: { paddingTop: 4, gap: 8 },
  row: { flexDirection: 'row' },
  rowText: { fontSize: 16, color: '#2B2F37' },
  more: { marginTop: 6, color: '#6B7280' },
});
