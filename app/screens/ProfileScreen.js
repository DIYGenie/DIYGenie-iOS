import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Pressable, AppState, Linking, Alert, Platform, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import Constants from 'expo-constants';
import { brand, colors } from '../../theme/colors';
import { spacing, layout } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { supabase } from '../lib/storage';
import { PrimaryButton } from '../components/Buttons';
import { useAuth } from '../hooks/useAuth';

const BASE = process.env.EXPO_PUBLIC_BASE_URL || 'http://localhost:5000';
const ENDPOINTS = {
  entitlementsShort: `${BASE}/me/entitlements`,
  entitlementsWithId: (id) => `${BASE}/me/entitlements/${id}`,
  checkout: `${BASE}/api/billing/checkout`,
  portal: `${BASE}/api/billing/portal`,
  devUpgrade: `${BASE}/api/billing/upgrade`,
};

const CURRENT_USER_ID = 'e4cb3591-7272-46dd-b1f6-d7cc4e2f3d24';

const TIER_INFO = {
  free:   { label: 'Free',   projects: 2,  previews: false, badgeColor: '#A0AEC0' },
  casual: { label: 'Casual', projects: 5,  previews: true,  badgeColor: '#6E8BFF' },
  pro:    { label: 'Pro',    projects: 25, previews: true,  badgeColor: '#6F4BFF' },
};

const api = async (url, opts = {}) => {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), 12000);
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    signal: controller.signal,
    ...opts,
  });
  clearTimeout(t);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  const ct = res.headers.get('content-type') || '';
  if (!ct.includes('application/json')) throw new Error('Non-JSON response');
  return res.json();
};

const openExternal = async (url) => {
  try {
    if (Platform.OS === 'web') {
      window.open(url, '_blank', 'noopener,noreferrer');
      return;
    }
    const can = await Linking.canOpenURL(url);
    if (!can) throw new Error('Cannot open URL');
    await Linking.openURL(url);
  } catch (e) {
    Alert.alert('Billing', 'Could not open link. Please try again.');
  }
};

function PlanCard({ title, priceText, subtitle, features, ctaText, onPress, popular, testID, disabled }) {
  return (
    <View
      style={[
        styles.planCardContainer,
        popular && styles.planCardPopular,
      ]}
    >
      <View style={styles.planCardHeader}>
        <Text style={styles.planCardTitle}>{title}</Text>
        {popular && (
          <View style={styles.popularBadge}>
            <Text style={styles.popularBadgeText}>Most popular</Text>
          </View>
        )}
      </View>
      
      <View style={styles.planCardPriceRow}>
        <Text style={styles.planCardPrice}>{priceText.split('/')[0]}</Text>
        <Text style={styles.planCardPricePeriod}>/{priceText.split('/')[1]}</Text>
      </View>
      
      <Text style={styles.planCardSubtitle}>{subtitle}</Text>
      
      <View style={styles.planCardFeatures}>
        {features.map((feature, idx) => (
          <View key={idx} style={styles.planCardFeature}>
            <Text style={styles.planCardFeatureCheck}>✓</Text>
            <Text style={styles.planCardFeatureText}>{feature}</Text>
          </View>
        ))}
      </View>
      
      <TouchableOpacity
        style={[styles.planCardCTA, disabled && styles.planCardCTADisabled]}
        onPress={onPress}
        disabled={disabled}
        accessible
        accessibilityRole="button"
        testID={testID}
      >
        <Text style={styles.planCardCTAText}>{ctaText}</Text>
      </TouchableOpacity>
    </View>
  );
}

export default function ProfileScreen() {
  const navigation = useNavigation();
  const { user, loading, signOut: authSignOut } = useAuth();
  const [busy, setBusy] = React.useState(false);
  const [ents, setEnts] = React.useState({ tier: 'free', remaining: 0, previewAllowed: false });
  const [showUpgradePicker, setShowUpgradePicker] = React.useState(false);
  const [lastSyncAt, setLastSyncAt] = React.useState(null);
  const [syncNote, setSyncNote] = React.useState('');
  const [toastMessage, setToastMessage] = React.useState('');
  const [tapCount, setTapCount] = React.useState(0);
  const [showDiag, setShowDiag] = React.useState(false);

  const fetchEntitlementsSafe = React.useCallback(async (userId) => {
    try {
      const r = await api(`/me/entitlements/${userId}`);
      return r; // expected: { tier, remaining, previewAllowed }
    } catch {
      console.warn('[entitlements] falling back to Free defaults');
      return { tier: 'Free', remaining: 2, previewAllowed: false, ok: true };
    }
  }, []);

  const getEntitlements = React.useCallback(async () => {
    const r = await fetchEntitlementsSafe(CURRENT_USER_ID);
    const data = r.data || r;
    setEnts({ tier: data.tier || 'Free', remaining: data.remaining ?? 2, previewAllowed: !!data.previewAllowed });
  }, [fetchEntitlementsSafe]);

  const openPortal = async () => {
    setBusy(true);
    try {
      const { url } = await api(ENDPOINTS.portal, {
        method: 'POST',
        body: JSON.stringify({ user_id: CURRENT_USER_ID }),
      });
      await openExternal(url);
    } catch (e) {
      if (String(e.message).startsWith('501')) {
        Alert.alert('Billing', 'Portal not available for this user yet.');
      } else {
        Alert.alert('Billing', 'Portal is unavailable. Try again later.');
      }
    } finally {
      setBusy(false);
    }
  };

  const openCheckout = async (tier) => {
    setBusy(true);
    try {
      const { url } = await api(ENDPOINTS.checkout, {
        method: 'POST',
        body: JSON.stringify({ tier, user_id: CURRENT_USER_ID }),
      });
      await openExternal(url);
    } catch (e) {
      if (String(e.message).startsWith('404') || String(e.message).startsWith('501')) {
        try {
          await api(ENDPOINTS.devUpgrade, {
            method: 'POST',
            body: JSON.stringify({ tier, user_id: CURRENT_USER_ID }),
          });
          Alert.alert('Billing', `Upgraded to ${tier} in dev mode. Syncing...`);
          await getEntitlements();
        } catch {
          Alert.alert('Billing', 'Upgrade fallback failed. Use Sync Plan or try again.');
        }
      } else {
        Alert.alert('Billing', 'Checkout is unavailable. Try again later.');
      }
    } finally {
      setBusy(false);
    }
  };

  React.useEffect(() => {
    getEntitlements();
  }, [getEntitlements]);

  React.useEffect(() => {
    const sub = AppState.addEventListener('change', (s) => {
      if (s === 'active') getEntitlements();
    });
    return () => sub.remove();
  }, [getEntitlements]);

  const handleSyncPlan = async () => {
    if (busy) return;
    setSyncNote('Syncing…');
    setBusy(true);
    try {
      await getEntitlements();
      const ts = new Date();
      setLastSyncAt(ts);
      setSyncNote('Synced just now');
      setTimeout(() => setSyncNote(''), 2500);
      console.log('[SyncPlan] refreshed at', ts.toISOString());
    } catch (e) {
      console.warn('[SyncPlan] failed', e);
      Alert.alert('Sync failed', 'Could not refresh your plan. Please try again.');
      setSyncNote('');
    } finally {
      setBusy(false);
    }
  };

  const handleAccountSettings = () => {
    Alert.alert('Coming soon', 'Account settings will land here.');
  };

  const handleBilling = () => {
    openPortal();
  };

  const handleHelp = async () => {
    const url = 'mailto:support@diygenieapp.com?subject=DIY%20Genie%20Support';
    try {
      const canOpen = await Linking.canOpenURL(url);
      if (canOpen) {
        await Linking.openURL(url);
      } else {
        Alert.alert('Help & Support', 'Please email us at support@diygenieapp.com');
      }
    } catch (e) {
      Alert.alert('Help & Support', 'Please email us at support@diygenieapp.com');
    }
  };

  const handleLogOut = async () => {
    try {
      await authSignOut();
      setToastMessage('Signed out');
      setTimeout(() => setToastMessage(''), 2000);
    } catch (e) {
      Alert.alert('Log out', 'Unable to sign out. Please try again.');
    }
  };

  const onVersionTap = () => {
    const n = tapCount + 1;
    setTapCount(n);
    if (n >= 7) setShowDiag(true);
    setTimeout(() => setTapCount(0), 1500);
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.gradientStart, colors.gradientEnd]}
        style={[styles.gradientHeader, { pointerEvents: 'none' }]}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
      />
      
      <SafeAreaView style={styles.safeArea}>
        <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
          {/* Profile Card */}
          <View style={styles.profileCard}>
            <View style={styles.avatarPlaceholder} />
            <Text style={styles.profileName}>Tye Kowalski</Text>
            <Text style={styles.profileSubtitle}>DIY Enthusiast</Text>
          </View>

          {/* Auth Card */}
          {loading ? (
            <View style={styles.authCard}>
              <ActivityIndicator size="small" color={brand.primary} />
            </View>
          ) : !user ? (
            <View style={styles.authCard}>
              <Ionicons name="shield-checkmark-outline" size={32} color={brand.primary} style={{ marginBottom: 8 }} />
              <Text style={styles.authCardTitle}>Sign in to save scans</Text>
              <Text style={styles.authCardSubtitle}>Create an account to save your room scans and projects securely.</Text>
              <TouchableOpacity
                style={styles.authCardButton}
                onPress={() => navigation.navigate('Auth')}
                accessibilityRole="button"
                accessibilityLabel="Sign in"
              >
                <Text style={styles.authCardButtonText}>Sign in</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.authCard}>
              <Ionicons name="checkmark-circle" size={32} color="#10B981" style={{ marginBottom: 8 }} />
              <Text style={styles.authCardTitle}>Signed in</Text>
              <Text style={styles.authCardSubtitle}>{user.email}</Text>
              <TouchableOpacity
                style={[styles.authCardButton, styles.authCardButtonSecondary]}
                onPress={handleLogOut}
                accessibilityRole="button"
                accessibilityLabel="Sign out"
              >
                <Text style={styles.authCardButtonTextSecondary}>Sign out</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Your Plan Section */}
          <Text style={styles.sectionTitle}>Your Plan</Text>
          <View style={[styles.planCard, { zIndex: 1, pointerEvents: 'auto' }]}>
            <View style={{ flexDirection:'row', alignItems:'center', justifyContent:'space-between' }}>
              <View style={{ flexShrink: 1, paddingRight: 12 }}>
                <View style={{ flexDirection:'row', alignItems:'center', marginBottom: 4 }}>
                  <Text style={{ fontSize:16, fontWeight:'700', marginRight:8 }}>Current Plan:</Text>
                  <View
                    testID="current-plan-badge"
                    style={{
                      paddingHorizontal:10, paddingVertical:4, borderRadius:999,
                      backgroundColor: (TIER_INFO[ents?.tier] || TIER_INFO.free).badgeColor + '20',
                      borderWidth:1, borderColor: (TIER_INFO[ents?.tier] || TIER_INFO.free).badgeColor
                    }}
                  >
                    <Text style={{ fontWeight:'700', color:'#1A1D21' }}>
                      {(TIER_INFO[ents?.tier] || TIER_INFO.free).label}
                    </Text>
                  </View>
                </View>
                <Text testID="current-plan-line" style={{ color:'#3B4450' }}>
                  {(() => {
                    const info = TIER_INFO[ents?.tier] || TIER_INFO.free;
                    return `${info.projects} projects/month` + (info.previews ? ' + previews' : ' (no previews)');
                  })()}
                </Text>
              </View>

              <Pressable
                onPress={openPortal}
                accessibilityRole="button"
                hitSlop={12}
                disabled={busy}
                testID="btn-manage-portal"
                style={{ paddingVertical: 8, paddingHorizontal: 6 }}
              >
                <Text style={{ color: brand.primary, fontWeight: '600' }}>Manage</Text>
              </Pressable>
            </View>
          </View>

          {ents.tier !== 'pro' && (
            <>
              <PrimaryButton
                title={showUpgradePicker ? 'Cancel' : 'Upgrade Plan'}
                onPress={() => setShowUpgradePicker(v => !v)}
                disabled={busy}
                style={styles.upgradeButton}
              />

              {showUpgradePicker && (
                <View style={styles.upgradeCardsContainer} testID="upgrade-cards">
                  <PlanCard
                    title="Pro"
                    priceText="$14.99/mo"
                    subtitle="Best for frequent builders"
                    features={[
                      '25 projects/month',
                      '1 visual preview per project',
                      'AR Scan access (stub)',
                      'Save & export plans',
                      'Priority improvements access',
                    ]}
                    ctaText="Start Pro — $14.99/mo"
                    popular
                    onPress={() => {
                      setShowUpgradePicker(false);
                      openCheckout('pro');
                    }}
                    testID="plan-pro-cta"
                    disabled={busy}
                  />
                  
                  <PlanCard
                    title="Casual"
                    priceText="$5.99/mo"
                    subtitle="Great for occasional projects"
                    features={[
                      '5 projects/month',
                      '1 visual preview per project',
                      'AR Scan access (stub)',
                      'Save & export plans',
                    ]}
                    ctaText="Start Casual — $5.99/mo"
                    onPress={() => {
                      setShowUpgradePicker(false);
                      openCheckout('casual');
                    }}
                    testID="plan-casual-cta"
                    disabled={busy}
                  />
                  
                  <Text style={styles.upgradeFootnote}>
                    Cancel anytime via{' '}
                    <Text
                      style={styles.upgradeFootnoteLink}
                      onPress={openPortal}
                    >
                      Manage
                    </Text>
                    {' '}(Stripe Portal).
                  </Text>
                </View>
              )}
            </>
          )}

          <Pressable
            onPress={handleSyncPlan}
            accessibilityRole="button"
            hitSlop={10}
            disabled={busy}
            testID="btn-sync-plan"
            style={{ alignSelf: 'center', paddingVertical: 8 }}
          >
            <Text style={{ color: brand.primary, fontWeight: '600' }}>
              {busy ? 'Syncing…' : 'Sync Plan'}
            </Text>
          </Pressable>
          {syncNote ? (
            <Text testID="sync-note" style={{ textAlign:'center', fontSize:12, opacity:0.8, marginTop:4 }}>
              {syncNote}
            </Text>
          ) : null}

          {/* Settings Section */}
          <Text style={styles.sectionTitle}>Settings</Text>
          
          <Pressable
            onPress={handleAccountSettings}
            accessibilityRole="button"
            hitSlop={10}
            disabled={busy}
            testID="row-account"
          >
            <View style={styles.settingsCard}>
              <View style={styles.settingsRow}>
                <Ionicons name="person-outline" size={24} color="#64748B" style={styles.settingsIcon} />
                <Text style={styles.settingsLabel}>Account Settings</Text>
                <Ionicons name="chevron-forward" size={20} color="#64748B" />
              </View>
            </View>
          </Pressable>

          <Pressable
            onPress={handleBilling}
            accessibilityRole="button"
            hitSlop={10}
            disabled={busy}
            testID="row-billing"
          >
            <View style={styles.settingsCard}>
              <View style={styles.settingsRow}>
                <Ionicons name="card-outline" size={24} color="#64748B" style={styles.settingsIcon} />
                <Text style={styles.settingsLabel}>Billing & Payments</Text>
                <Ionicons name="chevron-forward" size={20} color="#64748B" />
              </View>
            </View>
          </Pressable>

          <Pressable
            onPress={handleHelp}
            accessibilityRole="button"
            hitSlop={10}
            disabled={busy}
            testID="row-help"
          >
            <View style={styles.settingsCard}>
              <View style={styles.settingsRow}>
                <Ionicons name="help-circle-outline" size={24} color="#64748B" style={styles.settingsIcon} />
                <Text style={styles.settingsLabel}>Help & Support</Text>
                <Ionicons name="chevron-forward" size={20} color="#64748B" />
              </View>
            </View>
          </Pressable>

          <Pressable
            onPress={handleLogOut}
            accessibilityRole="button"
            hitSlop={10}
            disabled={busy}
            testID="row-logout"
          >
            <View style={styles.settingsCard}>
              <View style={styles.settingsRow}>
                <Ionicons name="log-out-outline" size={24} color="#DC2626" style={styles.settingsIcon} />
                <Text style={[styles.settingsLabel, styles.logoutLabel]}>Log Out</Text>
                <Ionicons name="chevron-forward" size={20} color="#DC2626" />
              </View>
            </View>
          </Pressable>

          {/* Version with 7-tap reveal */}
          <View style={{ marginTop: 24, marginBottom: 16, alignItems: 'center' }}>
            <TouchableOpacity onPress={onVersionTap}>
              <Text style={{ opacity: 0.6, fontSize: 14 }}>Version {Constants?.expoConfig?.version}</Text>
            </TouchableOpacity>
            
            {showDiag && (
              <TouchableOpacity
                onPress={() => navigation.navigate('Diagnostics')}
                style={{ marginTop: 12, backgroundColor: '#EEF2FF', padding: 10, borderRadius: 8 }}
              >
                <Text style={{ color: '#4F46E5', fontWeight: '600' }}>Open Diagnostics</Text>
              </TouchableOpacity>
            )}
          </View>
        </ScrollView>
      </SafeAreaView>

      {toastMessage ? (
        <View style={styles.toast}>
          <Text style={styles.toastText}>{toastMessage}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
  },
  gradientHeader: {
    height: 120,
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  safeArea: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
  },
  profileCard: {
    backgroundColor: colors.surface,
    borderRadius: 24,
    padding: 32,
    marginTop: -16,
    alignItems: 'center',
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
    marginBottom: 24,
  },
  avatarPlaceholder: {
    width: 72,
    height: 72,
    backgroundColor: '#E5E7EB',
    borderRadius: 36,
    marginBottom: 16,
  },
  profileName: {
    fontSize: 20,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginBottom: 4,
  },
  profileSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.interMedium,
    color: '#475569',
  },
  authCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    marginBottom: 24,
  },
  authCardTitle: {
    fontSize: 18,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    marginBottom: 8,
    textAlign: 'center',
  },
  authCardSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
    marginBottom: 16,
    textAlign: 'center',
  },
  authCardButton: {
    backgroundColor: brand.primary,
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 32,
  },
  authCardButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    fontFamily: typography.fontFamily.manropeSemiBold,
  },
  authCardButtonSecondary: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderColor: '#E5E7EB',
  },
  authCardButtonTextSecondary: {
    color: colors.textPrimary,
    fontSize: 16,
    fontWeight: '600',
    fontFamily: typography.fontFamily.manropeSemiBold,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginTop: 24,
    marginBottom: 16,
  },
  planCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
    marginBottom: 16,
  },
  planContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  planTitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#111827',
    marginBottom: 4,
  },
  planSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#475569',
  },
  manageButton: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: brand.primary,
  },
  disabledButton: {
    color: '#9CA3AF',
  },
  upgradeButton: {
    marginBottom: 12,
    shadowColor: brand.primary,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  upgradeButtonText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#FFFFFF',
  },
  upgradeCardsContainer: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
    gap: 16,
  },
  planCardContainer: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 20,
    borderWidth: 2,
    borderColor: '#E8E9EE',
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
  },
  planCardPopular: {
    borderColor: '#6F4BFF',
    backgroundColor: 'rgba(111, 75, 255, 0.06)',
  },
  planCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  planCardTitle: {
    fontSize: 20,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#111827',
  },
  popularBadge: {
    backgroundColor: brand.primary300,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  popularBadgeText: {
    fontSize: 11,
    fontFamily: typography.fontFamily.manropeBold,
    color: brand.primary700,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  planCardPriceRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 6,
  },
  planCardPrice: {
    fontSize: 32,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#111827',
  },
  planCardPricePeriod: {
    fontSize: 18,
    fontFamily: typography.fontFamily.inter,
    color: '#64748B',
  },
  planCardSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#64748B',
    marginBottom: 16,
  },
  planCardFeatures: {
    marginBottom: 20,
    gap: 10,
  },
  planCardFeature: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
  },
  planCardFeatureCheck: {
    fontSize: 16,
    color: '#6F4BFF',
    fontWeight: '700',
  },
  planCardFeatureText: {
    flex: 1,
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#374151',
    lineHeight: 20,
  },
  planCardCTA: {
    backgroundColor: brand.primary,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    minHeight: 52,
    justifyContent: 'center',
  },
  planCardCTADisabled: {
    backgroundColor: '#9CA3AF',
    opacity: 0.6,
  },
  planCardCTAText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#FFFFFF',
  },
  upgradeFootnote: {
    fontSize: 12,
    fontFamily: typography.fontFamily.inter,
    color: '#64748B',
    textAlign: 'center',
    marginTop: 8,
  },
  upgradeFootnoteLink: {
    color: brand.primary,
    fontFamily: typography.fontFamily.manropeBold,
  },
  syncButton: {
    alignItems: 'center',
    paddingVertical: 8,
    marginBottom: 8,
  },
  syncButtonText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.interMedium,
    color: brand.primary,
  },
  disabledText: {
    color: '#9CA3AF',
  },
  settingsCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
    marginBottom: 12,
  },
  settingsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingsIcon: {
    marginRight: 16,
  },
  settingsLabel: {
    flex: 1,
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
  },
  logoutLabel: {
    color: '#DC2626',
  },
  toast: {
    position: 'absolute',
    bottom: 40,
    left: 24,
    right: 24,
    backgroundColor: '#1F2937',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  toastText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontFamily: typography.fontFamily.inter,
  },
});
