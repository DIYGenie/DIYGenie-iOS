import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Image, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { brand, colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';

export default function ProjectPreview({ navigation, route }) {
  const { imageUri, description, budget, skill } = route.params;

  const handleLooksGood = () => {
    Alert.alert('Next: AI planning', 'AI will analyze your photo and generate a step-by-step plan for your project.');
  };

  const handleBack = () => {
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Back Button */}
        <TouchableOpacity style={styles.backButton} onPress={handleBack}>
          <Ionicons name="arrow-back" size={24} color={colors.textPrimary} />
        </TouchableOpacity>

        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Project Preview</Text>
          <Text style={styles.subtitle}>Review your project details before continuing</Text>
        </View>

        {/* Selected Image */}
        <View style={styles.imageContainer}>
          <Image source={{ uri: imageUri }} style={styles.selectedImage} />
        </View>

        {/* Project Details */}
        <View style={styles.detailsContainer}>
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Description</Text>
            <Text style={styles.detailValue}>{description}</Text>
          </View>
          
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Budget</Text>
            <Text style={styles.detailValue}>{budget}</Text>
          </View>
          
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Skill Level</Text>
            <Text style={styles.detailValue}>{skill}</Text>
          </View>
        </View>

        {/* Looks Good Button */}
        <View style={styles.buttonContainer}>
          <TouchableOpacity style={styles.looksGoodButton} onPress={handleLooksGood}>
            <Text style={styles.looksGoodText}>Looks Good</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  backButton: {
    alignSelf: 'flex-start',
    padding: 8,
    marginBottom: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 22,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.interMedium,
    color: '#475569',
    textAlign: 'center',
    lineHeight: 20,
  },
  imageContainer: {
    alignItems: 'center',
    marginBottom: 32,
  },
  selectedImage: {
    width: '100%',
    height: 240,
    borderRadius: 16,
    backgroundColor: '#F3F4F6',
  },
  detailsContainer: {
    marginBottom: 32,
  },
  detailItem: {
    backgroundColor: colors.white,
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
    // Web-specific shadow
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
  },
  detailLabel: {
    fontSize: 12,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#6B7280',
    marginBottom: 4,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  detailValue: {
    fontSize: 16,
    fontFamily: typography.fontFamily.inter,
    color: colors.textPrimary,
    lineHeight: 22,
  },
  buttonContainer: {
    paddingVertical: 24,
    paddingBottom: 32,
  },
  looksGoodButton: {
    backgroundColor: brand.primary,
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 32,
    alignItems: 'center',
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    // Web-specific shadow
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
  },
  looksGoodText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.white,
  },
});