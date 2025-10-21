import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { brand, colors } from '../../theme/colors';
import { spacing, layout } from '../../theme/spacing';
import { typography } from '../../theme/typography';

const { width, height } = Dimensions.get('window');

// Calculate responsive icon size (25-30% of available vertical space above title)
const getIconSize = () => {
  // Use roughly 25% of screen height for the icon, with min/max bounds
  const responsiveSize = Math.min(Math.max(height * 0.25, 150), 300);
  return responsiveSize;
};

export default function WelcomeScreen({ navigation }) {
  const handleGetStarted = () => {
    navigation.replace('Main');
  };

  return (
    <LinearGradient
      colors={[colors.gradientStart, colors.gradientEnd]}
      style={styles.container}
      start={{ x: 0, y: 0 }}
      end={{ x: 0, y: 1 }}
    >
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.content}>
          {/* App Icon */}
          <View style={styles.iconContainer}>
            <Image
              source={require('../../assets/Icon.png')}
              style={styles.appIcon}
              resizeMode="contain"
            />
          </View>

          {/* Title */}
          <Text style={styles.title}>DIY Genie</Text>

          {/* Tagline */}
          <Text style={styles.tagline}>Wish. See. Build.</Text>

          {/* Spacer */}
          <View style={styles.spacer} />

          {/* CTA Button */}
          <TouchableOpacity
            style={styles.ctaButton}
            onPress={handleGetStarted}
            activeOpacity={0.8}
          >
            <Text style={styles.ctaButtonText}>Get Started</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: layout.containerPadding,
  },
  iconContainer: {
    marginBottom: spacing.xl,
  },
  appIcon: {
    width: getIconSize(),
    height: getIconSize(),
    // Add subtle drop shadow for depth
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 6,
    },
    shadowOpacity: 0.25,
    shadowRadius: 12,
    elevation: 10,
    // Web-specific shadow
    boxShadow: '0px 6px 12px rgba(0, 0, 0, 0.25)',
  },
  title: {
    fontSize: typography.fontSize.title,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: spacing.sm,
  },
  tagline: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.inter,
    color: '#374151',
    textAlign: 'center',
    marginBottom: spacing.xxl * 1.25,
  },
  spacer: {
    flex: 0.15,
  },
  ctaButton: {
    backgroundColor: brand.primary,
    paddingHorizontal: spacing.xxxl * 1.38,
    paddingVertical: spacing.md * 1.15,
    borderRadius: layout.borderRadius.full,
    marginBottom: spacing.xl,
    shadowColor: brand.primary,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
    // Web-specific shadow
    boxShadow: '0px 4px 8px rgba(0, 0, 0, 0.3)',
  },
  ctaButtonText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.white,
    textAlign: 'center',
  },
});