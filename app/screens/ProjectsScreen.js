import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, RefreshControl, Image, ActivityIndicator, InteractionManager, DeviceEventEmitter, Alert, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useFocusEffect } from '@react-navigation/native';
import { Screen, Card, Badge, ui, space } from '../ui/components';
import { brand, colors } from '../../theme/colors';
import { spacing, layout } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { fetchProjectCards, fetchProjectPlanMarkdown } from '../lib/api';
import { useUser } from '../lib/useUser';
import { log } from '../lib/logger';

export default function ProjectsScreen({ navigation }) {
  const { userId } = useUser();
  const [activeFilter, setActiveFilter] = useState('All');
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(false);

  // Unified loader using new cards endpoint
  const fetchProjects = useCallback(async () => {
    setLoading(true);
    try {
      const items = await fetchProjectCards(userId);
      setProjects(items);
      log('[projects] fetched cards', items.length);
    } catch (e) {
      log('[projects] cards endpoint failed → fallback empty', String(e?.message || e));
      setProjects([]);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    if (userId) fetchProjects();
  }, [userId, fetchProjects]);

  // Listen for project deletion events
  useEffect(() => {
    const subscription = DeviceEventEmitter.addListener('projects:refresh', () => {
      log('[projects] delete event → refetch');
      fetchProjects();
    });

    return () => {
      subscription.remove();
    };
  }, [fetchProjects]);

  // Auto-refresh list whenever this screen gains focus
  useFocusEffect(
    useCallback(() => {
      if (userId) {
        log('[projects] focus → refetch');
        fetchProjects();
      }
      return () => {};
    }, [userId, fetchProjects])
  );

  const handleFilterPress = (filter) => {
    setActiveFilter(filter);
  };

  const handleStartProject = () => {
    navigation.navigate('NewProject');
  };

  const filteredProjects = projects.filter(project => {
    if (activeFilter === 'All') return true;
    if (activeFilter === 'Active') return project.status === 'active';
    if (activeFilter === 'Completed') return project.status === 'completed';
    return true;
  });

  const showEmptyState = filteredProjects.length === 0;

  return (
    <Screen>
      <SafeAreaView style={styles.container}>
        <ScrollView 
          contentContainerStyle={{ padding: space.lg, paddingBottom: 120 }}
          style={{ backgroundColor: "#fff" }}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl refreshing={loading} onRefresh={fetchProjects} />
          }
        >
        {/* Header Section */}
        <View style={styles.headerSection}>
          <Text style={styles.title}>Projects</Text>
          <Text style={styles.subtitle}>Manage all your DIY projects in one place</Text>
        </View>

        {/* Search Bar */}
        <View style={styles.searchContainer}>
          <Ionicons name="search" size={20} color={colors.textSecondary} style={styles.searchIcon} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search projects…"
            placeholderTextColor={colors.textSecondary}
            editable={false}
          />
        </View>

        {/* Filter Pills */}
        <View style={styles.filterRow}>
          {['All', 'Active', 'Completed'].map((filter) => (
            <TouchableOpacity
              key={filter}
              style={[
                styles.filterPill,
                activeFilter === filter ? styles.filterPillActive : styles.filterPillInactive
              ]}
              onPress={() => handleFilterPress(filter)}
            >
              <Text
                style={[
                  styles.filterText,
                  activeFilter === filter ? styles.filterTextActive : styles.filterTextInactive
                ]}
              >
                {filter}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Projects List or Empty State */}
        {showEmptyState ? (
          <View style={styles.emptyState}>
            <View style={styles.emptyIllustration}>
              <Ionicons name="folder-outline" size={64} color="#9CA3AF" />
            </View>
            <Text style={styles.emptyTitle}>No projects yet</Text>
            <Text style={styles.emptySubtitle}>Start by scanning your room or uploading a photo.</Text>

            <TouchableOpacity style={styles.startProjectButton} onPress={handleStartProject}>
              <Text style={styles.startProjectText}>Start Your First Project</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.projectsList}>
            {filteredProjects.map((project) => (
              <ProjectCard key={project.id} project={project} navigation={navigation} />
            ))}
          </View>
        )}
      </ScrollView>
      </SafeAreaView>
    </Screen>
  );
}

function ProjectCard({ project, navigation }) {
  const projectName = project.name || 'Untitled Project';
  const status = project.status;
  const imageSource = project.preview_thumb_url ?? project.preview_url ?? null;
  
  const handlePress = async () => {
    try {
      await fetchProjectPlanMarkdown(project.id);
      const parent = navigation.getParent?.();
      parent?.navigate('Projects', { screen: 'ProjectsList' });
      InteractionManager.runAfterInteractions(() => {
        parent?.navigate('Projects', { screen: 'ProjectDetails', params: { id: project.id } });
      });
    } catch (e) {
      const parent = navigation.getParent?.();
      parent?.navigate('Projects', { screen: 'ProjectDetails', params: { id: project.id } });
    }
  };
  
  return (
    <Card onPress={handlePress} style={{ marginBottom: space.md }}>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        {/* Thumbnail */}
        <View style={{ position: 'relative' }}>
          {imageSource ? (
            <Image 
              source={{ uri: imageSource }} 
              style={styles.thumbnailImage}
              resizeMode="cover"
            />
          ) : (
            <View style={styles.thumbnailPlaceholder} />
          )}
        </View>
        
        {/* Content */}
        <View style={{ flex: 1, marginLeft: 12 }}>
          <Text style={[ui.h2, { marginBottom: 6 }]} numberOfLines={1}>{projectName}</Text>
          <Badge
            text={status === "preview_ready" ? "Preview ready" : status === "plan_ready" ? "Plan ready" : "In progress"}
            tone={status?.includes("ready") ? "success" : "muted"}
          />
        </View>
        
        {/* Chevron */}
        <Ionicons name="chevron-forward" size={20} color={colors.textSecondary} />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 24,
  },
  headerSection: {
    marginBottom: 16,
  },
  title: {
    fontSize: 22,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.interMedium,
    color: '#475569',
    lineHeight: 21,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bg,
    borderRadius: 16,
    paddingHorizontal: spacing.md,
    height: 44,
    marginTop: 16,
    marginBottom: 16,
  },
  searchIcon: {
    marginRight: spacing.sm,
  },
  searchInput: {
    flex: 1,
    fontSize: typography.fontSize.md,
    fontFamily: typography.fontFamily.inter,
    color: colors.textPrimary,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  filterPill: {
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  filterPillActive: {
    backgroundColor: brand.primary,
  },
  filterPillInactive: {
    backgroundColor: '#F3F4F6',
  },
  filterText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.manropeBold,
  },
  filterTextActive: {
    color: colors.white,
  },
  filterTextInactive: {
    color: '#374151',
  },
  projectsList: {
    gap: 16,
    paddingBottom: spacing.xxxl,
  },
  projectCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    flexDirection: 'row',
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
  },
  thumbnailPlaceholder: {
    width: 64,
    height: 64,
    backgroundColor: '#E5E7EB',
    borderRadius: 12,
  },
  thumbnailImage: {
    width: 64,
    height: 64,
    borderRadius: 12,
  },
  thumbnailSkeleton: {
    width: 64,
    height: 64,
    backgroundColor: '#F3F4F6',
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cardContent: {
    flex: 1,
    justifyContent: 'center',
  },
  cardTitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#111827',
    marginBottom: 4,
  },
  cardSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#475569',
    marginBottom: 8,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
    paddingHorizontal: 24,
  },
  emptyIllustration: {
    marginBottom: 24,
  },
  emptyTitle: {
    fontSize: 18,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#374151',
    marginBottom: 8,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#6B7280',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 20,
  },
  startProjectButton: {
    backgroundColor: colors.white,
    borderWidth: 2,
    borderColor: brand.primary,
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 32,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 3,
    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.06)',
  },
  startProjectText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: brand.primary,
  },
});
