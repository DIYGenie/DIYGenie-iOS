import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { fetchProject, fetchPlan } from '../lib/api';
import Toast from '../components/Toast';
import { brand } from '../../theme/colors';

export default function PlanScreen({ navigation, route }) {
  const { id } = route.params;
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expandedSteps, setExpandedSteps] = useState({});
  const [toast, setToast] = useState({ visible: false, message: '', type: 'success' });

  useEffect(() => {
    loadProject();
  }, [id]);

  const loadProject = async () => {
    try {
      setLoading(true);
      
      // Fetch project basic info first
      const projectData = await fetchProject(id);
      
      // Then fetch the plan using the dedicated /plan endpoint
      const planData = await fetchPlan(id);
      
      // Merge the data
      const mergedData = {
        ...projectData,
        ...(planData.plan && { plan: planData.plan }),
        ...(planData.plan_text && { plan_text: planData.plan_text }),
      };
      
      if (!mergedData.plan && !mergedData.plan_text) {
        setToast({
          visible: true,
          message: 'Plan not ready yet',
          type: 'error',
        });
        setTimeout(() => navigation.goBack(), 1500);
        return;
      }
      
      setProject(mergedData);
    } catch (error) {
      console.error('Failed to load plan:', error);
      setToast({
        visible: true,
        message: error.message || 'Failed to load plan',
        type: 'error',
      });
      setTimeout(() => navigation.goBack(), 1500);
    } finally {
      setLoading(false);
    }
  };

  const showToast = (message, type = 'success') => {
    setToast({ visible: true, message, type });
  };

  const toggleStep = (index) => {
    setExpandedSteps(prev => ({
      ...prev,
      [index]: !prev[index],
    }));
  };

  const handleShareExport = () => {
    showToast('Share/Export feature coming soon!', 'success');
  };

  if (loading) {
    return (
      <LinearGradient colors={['#8B5CF6', '#3B82F6']} style={styles.container}>
        <SafeAreaView style={styles.safeArea}>
          <View style={styles.header}>
            <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
              <Ionicons name="arrow-back" size={24} color="#FFF" />
            </TouchableOpacity>
            <Text style={styles.headerTitle}>Build Plan</Text>
            <View style={{ width: 40 }} />
          </View>
          <View style={styles.centerContent}>
            <ActivityIndicator size="large" color="#FFF" />
            <Text style={styles.loadingText}>Loading plan...</Text>
          </View>
        </SafeAreaView>
      </LinearGradient>
    );
  }

  if (!project || (!project.plan && !project.plan_text)) {
    return null;
  }

  const plan = project.plan;
  const planText = project.plan_text;

  return (
    <LinearGradient colors={['#8B5CF6', '#3B82F6']} style={styles.container}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Ionicons name="arrow-back" size={24} color="#FFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Build Plan</Text>
          <TouchableOpacity onPress={handleShareExport} style={styles.shareButton}>
            <Ionicons name="share-outline" size={24} color="#FFF" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
          <View style={styles.content}>
            <Text style={styles.planTitle}>{plan?.title || project.name || 'Your Project'}</Text>

            {/* If we have plan_text (stub), display it */}
            {planText && !plan && (
              <View style={styles.plainTextCard}>
                <Text style={styles.plainText}>{planText}</Text>
              </View>
            )}

            {/* Otherwise, display the structured plan */}
            {plan && (
              <>
              <View style={styles.summaryGrid}>
              {plan.est_cost && (
                <View style={styles.summaryCard}>
                  <Ionicons name="cash-outline" size={24} color="#F97316" />
                  <Text style={styles.summaryLabel}>Est. Cost</Text>
                  <Text style={styles.summaryValue}>{plan.est_cost}</Text>
                </View>
              )}
              
              {plan.est_time && (
                <View style={styles.summaryCard}>
                  <Ionicons name="time-outline" size={24} color="#F97316" />
                  <Text style={styles.summaryLabel}>Est. Time</Text>
                  <Text style={styles.summaryValue}>{plan.est_time}</Text>
                </View>
              )}
              
              {plan.difficulty && (
                <View style={styles.summaryCard}>
                  <Ionicons name="bar-chart-outline" size={24} color="#F97316" />
                  <Text style={styles.summaryLabel}>Difficulty</Text>
                  <Text style={styles.summaryValue}>{plan.difficulty}</Text>
                </View>
              )}
            </View>

            {plan.steps && plan.steps.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Build Steps</Text>
                {plan.steps.map((step, index) => (
                  <TouchableOpacity
                    key={index}
                    style={styles.stepCard}
                    onPress={() => toggleStep(index)}
                    activeOpacity={0.8}
                  >
                    <View style={styles.stepHeader}>
                      <View style={styles.stepNumber}>
                        <Text style={styles.stepNumberText}>{index + 1}</Text>
                      </View>
                      <Text style={styles.stepTitle}>{step.title || step.name || `Step ${index + 1}`}</Text>
                      <Ionicons
                        name={expandedSteps[index] ? 'chevron-up' : 'chevron-down'}
                        size={20}
                        color="rgba(255, 255, 255, 0.6)"
                      />
                    </View>
                    {expandedSteps[index] && step.description && (
                      <Text style={styles.stepDescription}>{step.description}</Text>
                    )}
                  </TouchableOpacity>
                ))}
              </View>
            )}

            {plan.tools && plan.tools.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Required Tools</Text>
                <View style={styles.listCard}>
                  {plan.tools.map((tool, index) => (
                    <View key={index} style={styles.listItem}>
                      <Ionicons name="construct-outline" size={18} color="#F97316" />
                      <Text style={styles.listItemText}>
                        {typeof tool === 'string' ? tool : tool.name || 'Tool'}
                        {tool.qty && ` (${tool.qty})`}
                      </Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {plan.materials && plan.materials.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Materials</Text>
                <View style={styles.listCard}>
                  {plan.materials.map((material, index) => (
                    <View key={index} style={styles.listItem}>
                      <Ionicons name="cube-outline" size={18} color="#F97316" />
                      <Text style={styles.listItemText}>
                        {typeof material === 'string' ? material : material.name || 'Material'}
                        {material.qty && ` - ${material.qty}`}
                        {material.unit && ` ${material.unit}`}
                      </Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {plan.safety && plan.safety.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Safety Notes</Text>
                <View style={[styles.listCard, styles.safetyCard]}>
                  {plan.safety.map((note, index) => (
                    <View key={index} style={styles.listItem}>
                      <Ionicons name="shield-checkmark-outline" size={18} color="#EF4444" />
                      <Text style={styles.listItemText}>{note}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {plan.tips && plan.tips.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Pro Tips</Text>
                <View style={styles.listCard}>
                  {plan.tips.map((tip, index) => (
                    <View key={index} style={styles.listItem}>
                      <Ionicons name="bulb-outline" size={18} color={brand.primary} />
                      <Text style={styles.listItemText}>{tip}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}
              </>
            )}

            <View style={{ height: 40 }} />
          </View>
        </ScrollView>
      </SafeAreaView>

      <Toast
        visible={toast.visible}
        message={toast.message}
        type={toast.type}
        onHide={() => setToast({ ...toast, visible: false })}
      />
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  shareButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFF',
  },
  scrollView: {
    flex: 1,
  },
  content: {
    padding: 20,
  },
  centerContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  planTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFF',
    marginBottom: 24,
  },
  summaryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 24,
    gap: 12,
  },
  summaryCard: {
    flex: 1,
    minWidth: 100,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 8,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFF',
    marginTop: 4,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFF',
    marginBottom: 12,
  },
  stepCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  stepHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  stepNumber: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F97316',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  stepNumberText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFF',
  },
  stepTitle: {
    flex: 1,
    fontSize: 16,
    fontWeight: '600',
    color: '#FFF',
  },
  stepDescription: {
    marginTop: 12,
    paddingLeft: 44,
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    lineHeight: 20,
  },
  listCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
  },
  safetyCard: {
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.3)',
  },
  listItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  listItemText: {
    flex: 1,
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    marginLeft: 12,
    lineHeight: 20,
  },
  plainTextCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 20,
    marginBottom: 24,
  },
  plainText: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.9)',
    lineHeight: 24,
  },
});
