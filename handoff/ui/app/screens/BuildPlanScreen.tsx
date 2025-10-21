import React, { useMemo } from 'react';
import { SafeAreaView, View, Text, ScrollView, StyleSheet, TouchableOpacity, Platform, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { buildPlanFromProject, serializePlanToText } from '../lib/plan';
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { brand } from '../../theme/colors';

export default function BuildPlanScreen({ route, navigation }) {
  const { project, projectId } = route.params;
  const plan = useMemo(() => buildPlanFromProject(project), [project]);
  const projectName = project?.name || 'DIY Project';

  const handleSaveToPhone = async () => {
    try {
      const planText = serializePlanToText(plan, projectName);
      const filename = `plan-${projectId || 'project'}.txt`;

      if (Platform.OS === 'web') {
        const blob = new Blob([planText], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        Alert.alert('Success', 'Build plan downloaded!');
      } else {
        const fileUri = `${FileSystem.cacheDirectory}${filename}`;
        await FileSystem.writeAsStringAsync(fileUri, planText, {
          encoding: FileSystem.EncodingType.UTF8,
        });
        
        const canShare = await Sharing.isAvailableAsync();
        if (canShare) {
          await Sharing.shareAsync(fileUri, {
            mimeType: 'text/plain',
            dialogTitle: 'Save Build Plan',
            UTI: 'public.plain-text',
          });
        } else {
          Alert.alert('Success', 'Build plan saved to cache!');
        }
      }
    } catch (error) {
      console.error('Error saving plan:', error);
      Alert.alert('Error', 'Could not save build plan. Please try again.');
    }
  };

  const handleGoBack = () => {
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.screen}>
      <View style={styles.header}>
        <TouchableOpacity onPress={handleGoBack} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#0F172A" />
        </TouchableOpacity>
        <View style={styles.headerTextContainer}>
          <Text style={styles.headerTitle}>Detailed Build Plan</Text>
          <Text style={styles.headerSubtitle}>{projectName}</Text>
        </View>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator
      >
        <Section title="Overview" icon="list-outline">
          {plan.overview.map((item, idx) => (
            <View key={idx} style={styles.bulletRow}>
              <Text style={styles.bulletNumber}>{idx + 1}.</Text>
              <Text style={styles.bulletText}>{item}</Text>
            </View>
          ))}
        </Section>

        <Section title="Materials & Tools" icon="hammer-outline">
          <Text style={styles.subsectionTitle}>Materials</Text>
          {plan.materials.map((mat, idx) => (
            <View key={`mat-${idx}`} style={styles.materialRow}>
              <View style={styles.materialInfo}>
                <Text style={styles.materialName}>{mat.name}</Text>
                <Text style={styles.materialDetails}>
                  {mat.qty} {mat.unit} @ ${mat.unitPrice.toFixed(2)} each
                </Text>
              </View>
              <Text style={styles.materialPrice}>
                ${(mat.qty * mat.unitPrice).toFixed(2)}
              </Text>
            </View>
          ))}
          
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Estimated Total</Text>
            <Text style={styles.totalValue}>${plan.estimatedTotal.toFixed(2)}</Text>
          </View>

          <Text style={[styles.subsectionTitle, { marginTop: 20 }]}>Tools Needed</Text>
          {plan.tools.map((tool, idx) => (
            <View key={`tool-${idx}`} style={styles.toolRow}>
              <Text style={styles.toolText}>• {tool.name}</Text>
              {tool.substitute && (
                <Text style={styles.toolSubstitute}>(substitute: {tool.substitute})</Text>
              )}
            </View>
          ))}
        </Section>

        <Section title="Cut List" icon="cut-outline">
          {plan.cutList.map((item, idx) => (
            <View key={idx} style={styles.cutListItem}>
              <Text style={styles.cutListPart}>{item.part}</Text>
              <View style={styles.cutListDetails}>
                <Text style={styles.cutListSpec}>Quantity: {item.qty}</Text>
                <Text style={styles.cutListSpec}>Length: {item.length}</Text>
                <Text style={styles.cutListSpec}>Width: {item.width}</Text>
                <Text style={styles.cutListSpec}>Thickness: {item.thickness}</Text>
              </View>
              {item.notes && (
                <Text style={styles.cutListNotes}>Note: {item.notes}</Text>
              )}
            </View>
          ))}
        </Section>

        <Section title="Build Steps" icon="construct-outline">
          {plan.steps.map((step, idx) => (
            <View key={idx} style={styles.stepContainer}>
              <View style={styles.stepHeader}>
                <View style={styles.stepNumberBadge}>
                  <Text style={styles.stepNumberText}>{step.stepNumber}</Text>
                </View>
                <Text style={styles.stepTitle}>{step.title}</Text>
              </View>
              <Text style={styles.stepDescription}>{step.description}</Text>
              {step.estimatedTime && (
                <View style={styles.stepTimeRow}>
                  <Ionicons name="time-outline" size={14} color="#9CA3AF" />
                  <Text style={styles.stepTime}>{step.estimatedTime}</Text>
                </View>
              )}
            </View>
          ))}
        </Section>

        <TouchableOpacity style={styles.saveButton} onPress={handleSaveToPhone}>
          <Ionicons name="download-outline" size={20} color="#fff" />
          <Text style={styles.saveButtonText}>Save to phone</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

function Section({ title, icon, children }) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Ionicons name={icon} size={24} color={brand.primary} />
        <Text style={styles.sectionTitle}>{title}</Text>
      </View>
      <View style={styles.sectionContent}>
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#F6F7FB',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    padding: 8,
    marginRight: 12,
  },
  headerTextContainer: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0F172A',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  scroll: {
    flex: 1,
  },
  content: {
    padding: 16,
    paddingBottom: 96,
  },
  section: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    paddingBottom: 12,
    borderBottomWidth: 2,
    borderBottomColor: '#F3F4F6',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0F172A',
    marginLeft: 12,
  },
  sectionContent: {
    gap: 8,
  },
  bulletRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  bulletNumber: {
    fontSize: 16,
    fontWeight: '700',
    color: brand.primary,
    marginRight: 12,
    minWidth: 24,
  },
  bulletText: {
    flex: 1,
    fontSize: 16,
    color: '#374151',
    lineHeight: 24,
  },
  subsectionTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#0F172A',
    marginTop: 8,
    marginBottom: 12,
  },
  materialRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  materialInfo: {
    flex: 1,
  },
  materialName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0F172A',
    marginBottom: 4,
  },
  materialDetails: {
    fontSize: 14,
    color: '#6B7280',
  },
  materialPrice: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0F172A',
    marginLeft: 16,
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 2,
    borderTopColor: '#E5E7EB',
  },
  totalLabel: {
    fontSize: 18,
    fontWeight: '700',
    color: '#374151',
  },
  totalValue: {
    fontSize: 26,
    fontWeight: '800',
    color: brand.primary,
  },
  toolRow: {
    marginBottom: 6,
  },
  toolText: {
    fontSize: 16,
    color: '#374151',
    lineHeight: 24,
  },
  toolSubstitute: {
    fontSize: 14,
    color: '#9CA3AF',
    fontStyle: 'italic',
    marginLeft: 12,
    marginTop: 2,
  },
  cutListItem: {
    padding: 12,
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: brand.primary,
  },
  cutListPart: {
    fontSize: 17,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: 8,
  },
  cutListDetails: {
    gap: 4,
  },
  cutListSpec: {
    fontSize: 14,
    color: '#4B5563',
  },
  cutListNotes: {
    fontSize: 13,
    color: '#9CA3AF',
    fontStyle: 'italic',
    marginTop: 6,
  },
  stepContainer: {
    marginBottom: 20,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  stepHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  stepNumberBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  stepNumberText: {
    fontSize: 18,
    fontWeight: '800',
    color: '#fff',
  },
  stepTitle: {
    flex: 1,
    fontSize: 18,
    fontWeight: '700',
    color: '#0F172A',
  },
  stepDescription: {
    fontSize: 15,
    color: '#4B5563',
    lineHeight: 22,
    marginLeft: 48,
    marginBottom: 6,
  },
  stepTimeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 48,
    gap: 6,
  },
  stepTime: {
    fontSize: 13,
    color: '#9CA3AF',
    fontStyle: 'italic',
  },
  saveButton: {
    backgroundColor: '#10B981',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    marginTop: 8,
    shadowColor: '#10B981',
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
    gap: 8,
  },
  saveButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '700',
  },
});
