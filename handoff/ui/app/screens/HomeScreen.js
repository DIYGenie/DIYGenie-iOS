import React, { useEffect, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, useWindowDimensions, Linking, Platform, Alert, InteractionManager, RefreshControl, FlatList, Image, Pressable, ActivityIndicator } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { brand, colors } from '../../theme/colors.ts';
import { spacing, layout } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { fetchProjectCards, fetchProjectPlanMarkdown, createProjectAndReturnId } from '../lib/api';
import { useUser } from '../lib/useUser';
import PressableScale from '../components/ui/PressableScale';
import ProjectCardSkeleton from '../components/home/ProjectCardSkeleton';
import EmptyState from '../components/ui/EmptyState';
import { track } from '../lib/track';
import { log } from '../lib/logger';

// Shadow helpers for depth and polish
const shadow16 = {
  shadowColor: '#000',
  shadowOpacity: 0.08,
  shadowRadius: 12,
  shadowOffset: { width: 0, height: 6 },
  elevation: 4,
};

const shadow24 = {
  shadowColor: '#000',
  shadowOpacity: 0.10,
  shadowRadius: 16,
  shadowOffset: { width: 0, height: 10 },
  elevation: 6,
};

// Hero carousel data
const HERO_SLIDES = [
  {
    id: '1',
    image: 'https://picsum.photos/seed/diygenie1/1200/800',
    caption: 'See your space transform',
  },
  {
    id: '2',
    image: 'https://picsum.photos/seed/diygenie2/1200/800',
    caption: 'Measure with your iPhone',
  },
  {
    id: '3',
    image: 'https://picsum.photos/seed/diygenie3/1200/800',
    caption: 'Get a build plan in minutes',
  },
];

// Hero carousel component
function HeroCarousel() {
  const [activeSlide, setActiveSlide] = useState(0);
  const { width: winW } = useWindowDimensions();
  const carouselWidth = winW - 32; // Account for marginHorizontal 16

  const renderSlide = ({ item }) => (
    <View style={[heroStyles.heroCard, { width: carouselWidth }]}>
      <Image source={{ uri: item.image }} style={heroStyles.slideImage} />
      <LinearGradient
        colors={['transparent', 'rgba(0,0,0,0.6)']}
        style={heroStyles.gradient}
      >
        <Text style={heroStyles.caption}>{item.caption}</Text>
      </LinearGradient>
    </View>
  );

  const onViewableItemsChanged = useRef(({ viewableItems }) => {
    if (viewableItems.length > 0) {
      setActiveSlide(viewableItems[0].index || 0);
    }
  }).current;

  const viewabilityConfig = useRef({
    itemVisiblePercentThreshold: 50,
  }).current;

  return (
    <View style={heroStyles.container}>
      <FlatList
        data={HERO_SLIDES}
        renderItem={renderSlide}
        keyExtractor={(item) => item.id}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onViewableItemsChanged={onViewableItemsChanged}
        viewabilityConfig={viewabilityConfig}
        snapToInterval={carouselWidth}
        decelerationRate="fast"
      />
      <View style={heroStyles.pagination}>
        {HERO_SLIDES.map((_, index) => (
          <View
            key={index}
            style={[
              heroStyles.dot,
              activeSlide === index && heroStyles.dotActive,
            ]}
          />
        ))}
      </View>
    </View>
  );
}

// Progress bar component
function ProgressBar() {
  return (
    <View style={progressStyles.container}>
      <Text style={progressStyles.text}>
        1 Describe • 2 Scan • 3 Preview • 4 Build
      </Text>
    </View>
  );
}

// Template cards data
const TEMPLATES = [
  {
    key: 'shelf',
    name: 'Shelf',
    blurb: 'Clean, modern storage',
  },
  {
    key: 'accent_wall',
    name: 'Accent Wall',
    blurb: 'Add depth and contrast',
  },
  {
    key: 'mudroom_bench',
    name: 'Mudroom Bench',
    blurb: 'Entryway organization',
  },
];

// Template cards section
function TemplateCards({ navigation, onTemplateCreate, userId }) {
  const [creating, setCreating] = useState(null);

  const handleCreateTemplate = async (template) => {
    setCreating(template.key);

    try {
      // Create project with template data
      const projectId = await createProjectAndReturnId({
        name: template.name,
        description: template.blurb,
        budget: '',
        skill_level: 'beginner',
      });

      // Navigate to Project Details
      const parent = navigation.getParent?.('root-tabs') || navigation.getParent?.();
      if (parent?.navigate) {
        parent.navigate('Projects', { screen: 'ProjectDetails', params: { id: projectId } });
      } else {
        navigation.navigate('Projects', { screen: 'ProjectDetails', params: { id: projectId } });
      }
    } catch (err) {
      log('[template create error]', err);
      Alert.alert('Error', 'Could not create project. Please try again.');
    } finally {
      setCreating(null);
    }
  };

  return (
    <View style={templateStyles.section}>
      <Text style={templateStyles.header}>Start with a template</Text>
      
      {TEMPLATES.map((template) => (
        <View key={template.key} style={templateStyles.card}>
          <View style={templateStyles.cardContent}>
            <Text style={templateStyles.cardTitle}>{template.name}</Text>
            <Text style={templateStyles.cardBlurb}>{template.blurb}</Text>
          </View>
          <Pressable
            onPress={() => {
              track({ userId, event: 'create_template', props: { template: template.key } });
              navigation.navigate('NewProject');
            }}
            disabled={creating === template.key}
            style={templateStyles.createChip}
            activeOpacity={0.9}
          >
            {creating === template.key ? (
              <ActivityIndicator size="small" color="white" />
            ) : (
              <Text style={templateStyles.createChipText}>Create</Text>
            )}
          </Pressable>
        </View>
      ))}
    </View>
  );
}

export default function HomeScreen({ navigation }) {
  const { userId } = useUser();
  const [recent, setRecent] = useState([]);
  const [loading, setLoading] = useState(false);
  const insets = useSafeAreaInsets();
  const { width: winW } = useWindowDimensions();
  const isVeryNarrow = winW < 360;

  // Use the same unified loader and then slice to "recent"
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const items = await fetchProjectCards(userId);
      setRecent(items.slice(0, 5)); // show top 5 newest
    } catch (e) {
      log('[home recent load error]', String(e?.message || e));
      setRecent([]);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => { 
    if (userId) load(); 
  }, [userId, load]);

  // Pull-to-refresh state + handler
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = useCallback(async () => {
    try {
      setRefreshing(true);
      await load();
    } finally {
      setRefreshing(false);
    }
  }, [load]);

  // Keep "Recent Projects" fresh when returning to Home
  useFocusEffect(
    useCallback(() => {
      if (userId) {
        log('[home] focus → refetch recent projects');
        load();
      }
      return () => {};
    }, [userId, load])
  );

  const handleNewProject = () => {
    navigation.navigate('NewProject');
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView 
        style={styles.scrollView} 
        contentContainerStyle={[styles.scrollContent, { paddingTop: insets.top + 12 }]}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Welcome Header */}
        <Text style={[styles.welcomeTitle, { fontSize: isVeryNarrow ? 26 : 28 }]}>Welcome back, Tye</Text>
        <Text style={styles.welcomeSubtitle}>Ready to start your next DIY project?</Text>

        {/* Hero Carousel */}
        <HeroCarousel />

        {/* Progress Bar */}
        <ProgressBar />

        {/* Template Cards */}
        <TemplateCards navigation={navigation} userId={userId} />

        {/* CTA Button */}
        <Pressable
          testID="home-cta"
          onPress={handleNewProject}
          accessibilityRole="button"
          accessibilityLabel="Start a New Project"
          style={styles.startProjectButton}
        >
          <Text style={styles.startProjectText}>Start a New Project</Text>
        </Pressable>

        {/* Section Header */}
        <Text style={styles.sectionHeader}>Recent Projects</Text>

        {/* Project Cards / Loading / Empty State */}
        {loading ? (
          <ProjectCardSkeleton count={2} />
        ) : recent.length === 0 ? (
          <EmptyState
            title="No projects yet"
            subtitle="Start your first DIY and it'll show up here."
            primaryLabel="Start a New Project"
            onPrimary={handleNewProject}
          />
        ) : (
          <View style={styles.projectsSection}>
            {recent.map((project) => (
              <ProjectCard key={project.id} project={project} navigation={navigation} />
            ))}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function ProjectCard({ project, navigation }) {
  const handlePress = async () => {
    const id = project?.id || project?.project_id;
    if (!id) return;

    const parent = navigation.getParent?.('root-tabs') || navigation.getParent?.();

    try {
      await fetchProjectPlanMarkdown(id);
      if (parent?.navigate) {
        parent.navigate('Projects', { screen: 'ProjectsList' });
        InteractionManager.runAfterInteractions(() => {
          parent.navigate('Projects', { screen: 'ProjectDetails', params: { id } });
        });
      } else {
        navigation.navigate('Projects', { screen: 'ProjectsList' });
        InteractionManager.runAfterInteractions(() => {
          navigation.navigate('Projects', { screen: 'ProjectDetails', params: { id } });
        });
      }
    } catch (e) {
      if (parent?.navigate) {
        parent.navigate('Projects', { screen: 'ProjectDetails', params: { id } });
      } else {
        navigation.navigate('Projects', { screen: 'ProjectDetails', params: { id } });
      }
    }
  };

  const statusText = project.status === 'plan_ready' 
    ? 'Plan ready' 
    : project.status === 'preview_ready' 
      ? 'Preview ready' 
      : 'In progress';
  
  const imageSource = project.preview_thumb_url ?? project.preview_url ?? null;

  return (
    <PressableScale
      onPress={handlePress}
      haptic="light"
      scaleTo={0.98}
      accessibilityRole="button"
      accessibilityLabel={`${project.name || 'Untitled Project'}, ${statusText}`}
      style={styles.projectCard}
    >
      {/* Thumbnail */}
      {imageSource ? (
        <Image source={{ uri: imageSource }} style={styles.thumbnailImage} resizeMode="cover" />
      ) : (
        <View style={styles.thumbnailPlaceholder} />
      )}
      
      {/* Content */}
      <View style={styles.cardContent}>
        {/* Title */}
        <Text style={styles.cardTitle}>{project.name || 'Untitled Project'}</Text>
        
        {/* Subtitle */}
        <Text style={styles.cardSubtitle}>{statusText}</Text>
      </View>
      
      {/* Chevron */}
      <Ionicons name="chevron-forward" size={20} color={colors.textSecondary} />
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  welcomeTitle: {
    fontFamily: typography.fontFamily.manropeBold,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: 4,
    letterSpacing: 0.2,
  },
  welcomeSubtitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.interMedium,
    color: 'rgba(15,23,42,0.6)',
    marginBottom: 8,
  },
  startProjectButton: {
    height: 56,
    borderRadius: 16,
    backgroundColor: brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 16,
    marginTop: 16,
    ...shadow24,
  },
  startProjectText: {
    color: 'white',
    fontSize: 17,
    fontWeight: '600',
    letterSpacing: 0.2,
    fontFamily: typography.fontFamily.manropeBold,
  },
  sectionHeader: {
    fontSize: 18,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginTop: 20,
    marginBottom: 16,
  },
  projectsSection: {
    gap: 16,
  },
  projectCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    minHeight: 88,
    flexDirection: 'row',
    alignItems: 'center',
    ...shadow16,
  },
  thumbnailPlaceholder: {
    width: 56,
    height: 56,
    backgroundColor: colors.muted,
    borderRadius: 12,
    marginRight: spacing.md,
  },
  thumbnailImage: {
    width: 56,
    height: 56,
    borderRadius: 12,
    marginRight: spacing.md,
  },
  cardContent: {
    flex: 1,
    justifyContent: 'center',
  },
  cardTitle: {
    fontSize: typography.fontSize.md,
    fontFamily: typography.fontFamily.manropeBold,
    color: colors.textPrimary,
    marginBottom: 4,
  },
  cardSubtitle: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
  },
  emptyText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: colors.textSecondary,
    textAlign: 'center',
    paddingVertical: 24,
  },
});

// Hero carousel styles
const heroStyles = StyleSheet.create({
  container: {
    marginTop: 14,
    marginBottom: 8,
  },
  heroCard: {
    height: 210,
    borderRadius: 14,
    marginHorizontal: 16,
    overflow: 'hidden',
    backgroundColor: '#eee',
    ...shadow24,
  },
  slideImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  gradient: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '50%',
    justifyContent: 'flex-end',
    padding: 16,
  },
  caption: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '700',
    fontFamily: typography.fontFamily.manropeBold,
    textShadow: '0px 1px 6px rgba(0,0,0,0.35)',
  },
  pagination: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
    gap: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: 'rgba(0,0,0,0.12)',
  },
  dotActive: {
    backgroundColor: brand.primary,
    width: 16,
  },
});

// Progress bar styles
const progressStyles = StyleSheet.create({
  container: {
    marginTop: 6,
    marginHorizontal: 16,
    alignItems: 'center',
  },
  text: {
    fontSize: 13,
    color: '#6f7380',
    fontFamily: typography.fontFamily.inter,
  },
});

// Template cards styles
const templateStyles = StyleSheet.create({
  section: {
    marginTop: 18,
    marginBottom: 16,
  },
  header: {
    fontSize: 20,
    fontWeight: '700',
    color: brand.primary,
    marginHorizontal: 16,
    marginBottom: 10,
    fontFamily: typography.fontFamily.manropeBold,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 16,
    marginHorizontal: 16,
    marginBottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    ...shadow16,
  },
  cardContent: {
    flex: 1,
    paddingRight: 12,
  },
  cardTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#17181d',
    marginBottom: 4,
    fontFamily: typography.fontFamily.manropeBold,
  },
  cardBlurb: {
    fontSize: 14.5,
    color: '#7a7f89',
    fontFamily: typography.fontFamily.inter,
  },
  createChip: {
    paddingHorizontal: 16,
    height: 36,
    borderRadius: 999,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: brand.primary,
  },
  createChipText: {
    color: 'white',
    fontWeight: '700',
    fontSize: 14.5,
    fontFamily: typography.fontFamily.manropeBold,
  },
});
