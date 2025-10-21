import { View, Text, TouchableOpacity } from 'react-native';

export default function DetailCard({
  title,
  subtitle,
  onPress,
}: {
  title: string;
  subtitle?: string;
  onPress?: () => void;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.85}
      style={{
        backgroundColor: '#fff',
        borderRadius: 16,
        padding: 16,
        marginBottom: 12,
        shadowColor: '#000',
        shadowOpacity: 0.06,
        shadowRadius: 8,
        shadowOffset: { height: 4, width: 0 },
        elevation: 2,
      }}
    >
      <Text style={{ fontSize: 18, fontWeight: '700' }}>{title}</Text>
      {!!subtitle && (
        <Text style={{ opacity: 0.7, marginTop: 4 }} numberOfLines={2}>
          {subtitle}
        </Text>
      )}
    </TouchableOpacity>
  );
}
