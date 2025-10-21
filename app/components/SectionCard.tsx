import React, { ReactNode } from 'react';
import { View, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { brand } from '../../theme/colors';

type IconInput =
  | ReactNode
  | string
  | { name: string; size?: number; color?: string }
  | null
  | undefined;

type Props = {
  icon?: IconInput;
  title: ReactNode;
  summary?: string | ReactNode;
  countBadge?: number | string | ReactNode;
  children?: ReactNode;
  isOpen?: boolean;
  defaultOpen?: boolean;
  onToggle?: (open: boolean) => void;
};

function asIconEl(icon: IconInput): ReactNode {
  if (!icon) return null;
  if (React.isValidElement(icon)) return icon;
  
  if (typeof icon === 'string') {
    return <Ionicons name={icon as any} size={16} color={brand.primary} />;
  }
  
  if (typeof icon === 'object' && icon !== null && 'name' in icon && typeof (icon as any).name === 'string') {
    const cfg = icon as { name: string; size?: number; color?: string };
    return (
      <Ionicons
        name={cfg.name as any}
        size={cfg.size ?? 16}
        color={cfg.color ?? brand.primary}
      />
    );
  }
  
  console.warn('[SectionCard] Invalid icon format:', icon);
  return null;
}

function safeRenderNode(node: ReactNode): ReactNode {
  if (node == null) return null;
  if (typeof node === 'string' || typeof node === 'number' || typeof node === 'boolean') {
    return node;
  }
  if (React.isValidElement(node)) return node;
  if (Array.isArray(node)) return node;
  
  console.warn('[SectionCard] Invalid ReactNode (likely empty object):', node);
  return null;
}

export default function SectionCard({
  icon,
  title,
  summary,
  countBadge,
  children,
}: Props) {
  const iconEl = asIconEl(icon);
  const safeTitle = safeRenderNode(title);
  const safeSummary = safeRenderNode(summary);
  const safeBadge = safeRenderNode(countBadge);

  return (
    <View
      style={{
        backgroundColor: 'white',
        borderRadius: 12,
        padding: 16,
        marginHorizontal: 16,
        marginTop: 12,
        shadowColor: '#000',
        shadowOpacity: 0.05,
        shadowRadius: 8,
        shadowOffset: { width: 0, height: 2 },
        elevation: 2,
      }}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        {iconEl ? <View style={{ marginRight: 8 }}>{iconEl}</View> : null}

        {/* Title */}
        {typeof safeTitle === 'string' ? (
          <Text style={{ fontSize: 18, fontWeight: '700', color: '#14181F' }}>
            {safeTitle}
          </Text>
        ) : (
          safeTitle
        )}

        {/* Count badge */}
        {safeBadge != null ? (
          <View
            style={{
              marginLeft: 'auto',
              backgroundColor: '#F1EEFF',
              paddingHorizontal: 8,
              paddingVertical: 2,
              borderRadius: 999,
            }}
          >
            {typeof safeBadge === 'string' || typeof safeBadge === 'number' ? (
              <Text style={{ color: brand.primary, fontWeight: '600' }}>
                {String(safeBadge)}
              </Text>
            ) : (
              safeBadge
            )}
          </View>
        ) : null}
      </View>

      {/* Summary */}
      {safeSummary ? (
        <View style={{ marginTop: 6 }}>
          {typeof safeSummary === 'string' ? (
            <Text style={{ color: '#6B7280' }}>{safeSummary}</Text>
          ) : (
            safeSummary
          )}
        </View>
      ) : null}

      {/* Body */}
      {children ? <View style={{ marginTop: 12 }}>{children}</View> : null}
    </View>
  );
}
