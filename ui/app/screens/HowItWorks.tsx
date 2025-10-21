import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../theme/colors';
import { spacing, layout } from '../../theme/spacing';
import { typography } from '../../theme/typography';

interface HowItWorksProps {
  navigation: any;
}

export default function HowItWorks({ navigation }: HowItWorksProps) {
  const handleContinue = () => {
    navigation.navigate('NewProject');
  };

  const handleSkip = () => {
    navigation.navigate('NewProject');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        {/* Title */}
        <Text style={styles.title}>How DIY Genie Works</Text>
        
        {/* Step Cards Grid */}
        <View style={styles.stepCardsGrid}>
          <View style={styles.stepCardRow}>
            <View style={styles.stepCard}>
              <Ionicons name="camera" size={20} color={colors.muted} style={styles.stepIcon} />
              <Text style={styles.stepText}>Add your room</Text>
            </View>
            
            <View style={styles.stepCard}>
              <Ionicons name="create" size={20} color={colors.muted} style={styles.stepIcon} />
              <Text style={styles.stepText}>Tell us the goal</Text>
            </View>
          </View>
          
          <View style={styles.stepCardRow}>
            <View style={styles.stepCard}>
              <Ionicons name="sparkles" size={20} color={colors.muted} style={styles.stepIcon} />
              <Text style={styles.stepText}>See & preview</Text>
            </View>
            
            <View style={styles.stepCard}>
              <Ionicons name="clipboard" size={20} color={colors.muted} style={styles.stepIcon} />
              <Text style={styles.stepText}>Get your plan</Text>
            </View>
          </View>
        </View>
        
        {/* Bottom Action Row */}
        <View style={styles.actionRow}>
          <TouchableOpacity style={styles.skipButton} onPress={handleSkip}>
            <Text style={styles.skipText}>Skip</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.continueButton} onPress={handleContinue}>
            <Text style={styles.continueText}>Continue</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 48,
    paddingBottom: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 22,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: 48,
  },
  stepCardsGrid: {
    width: '100%',
    marginBottom: 48,
  },
  stepCardRow: {
    flexDirection: 'row',
    gap: 16,
    marginBottom: 16,
  },
  stepCard: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 120,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.08,
    shadowRadius: 24,
    elevation: 3,
    // Web-specific shadow
    boxShadow: '0px 4px 24px rgba(0, 0, 0, 0.08)',
  },
  stepIcon: {
    marginBottom: 12,
  },
  stepText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    textAlign: 'center',
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
  },
  skipButton: {
    paddingVertical: 16,
    paddingHorizontal: 24,
  },
  skipText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textSecondary,
  },
  continueButton: {
    backgroundColor: colors.accent,
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 32,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.08,
    shadowRadius: 24,
    elevation: 3,
    // Web-specific shadow
    boxShadow: '0px 4px 24px rgba(0, 0, 0, 0.08)',
  },
  continueText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.white,
  },
});