import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Pressable, TextInput, Alert, Modal, ActivityIndicator, ScrollView, Image, TouchableOpacity, Platform, AppState, findNodeHandle, Keyboard, TouchableWithoutFeedback, KeyboardAvoidingView, InteractionManager, Animated } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import useOptionalTabBarHeight from '../hooks/useOptionalTabBarHeight';
import { useNavigation, useRoute, CompositeNavigationProp, useFocusEffect, CommonActions } from '@react-navigation/native';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import type { RootTabParamList } from '../navigation/RootTabs';
import type { ProjectsStackParamList } from '../navigation/ProjectsNavigator';
import * as Haptics from 'expo-haptics';
import * as ImagePicker from 'expo-image-picker';
import * as Linking from 'expo-linking';
import { brand, colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { api, apiRaw, requestProjectPreview, pollProjectReady, patchProject, submitPreview, getPreviewStatus } from '../lib/api';
import { PrimaryButton, SecondaryButton } from '../components/Buttons';
import { saveRoomScan } from '../features/scans/saveRoomScan';
import { useAuth } from '../hooks/useAuth';
import { uploadRoomScan } from '../lib/uploadRoomScan';
import { supabase } from '../lib/supabase';
import RoiModal from '../components/RoiModal';
import { saveRoomScanRegion } from '../lib/regions';
import MeasureModal from '../components/MeasureModal';
import { saveLineMeasurement } from '../lib/measure';
import { ensureProjectForDraft, loadNewProjectDraft, saveNewProjectDraft, clearNewProjectDraft, type NewProjectDraft } from '../lib/draft';
import { attachScanToProject } from '../lib/scans';
import { setLastScan as setLastScanEphemeral } from '../lib/ephemeral';
import { useShake } from '../hooks/useShake';
import { simpleToast } from '../lib/ui';

const USER_ID = (globalThis as any).__DEV_USER_ID__ || '00000000-0000-0000-0000-000000000001';

// V1: tools are AR-only (hide on Upload flow)
const __HIDE_MEDIA_TOOLS = true;

// Base URL configuration
const RAW_BASE = process.env.EXPO_PUBLIC_BASE_URL || 'http://localhost:5000';
const API_BASE_URL = RAW_BASE.startsWith('http') ? RAW_BASE : `https://${RAW_BASE}`;

// --- CTA Styles ---
const CTA = {
  wrap: { borderRadius: 16, paddingVertical: 18, paddingHorizontal: 20 },
  title: { fontSize: 18, fontWeight: '700' as const, letterSpacing: 0.2 },
  sub: { fontSize: 13, opacity: 0.8, marginTop: 6, lineHeight: 18 },
  primary: {
    backgroundColor: '#6D28D9',
    shadowColor: '#6D28D9',
    shadowOpacity: 0.25,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  secondary: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: 'rgba(109,40,217,0.25)',
  },
  disabled: { opacity: 0.55 },
  row: { flexDirection: 'column' as const },
};

type NavProp = CompositeNavigationProp<
  BottomTabNavigationProp<RootTabParamList>,
  NativeStackNavigationProp<ProjectsStackParamList>
>;

export default function NewProject({ navigation: navProp }: { navigation?: any }) {
  const navigation = useNavigation<NavProp>();
  const route = useRoute<any>();
  const { user } = useAuth();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [budget, setBudget] = useState('');
  const [skillLevel, setSkillLevel] = useState('');
  const [showBudgetDropdown, setShowBudgetDropdown] = useState(false);
  const [showSkillDropdown, setShowSkillDropdown] = useState(false);
  
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [draftId, setDraftId] = useState<string | null>(null);
  
  const hydratedRef = useRef(false);
  const saveTimerRef = useRef<NodeJS.Timeout | null>(null);
  const clearingRef = useRef(false);
  const [ents, setEnts] = useState<{ previewAllowed: boolean; remaining?: number } | null>(null);
  const [busy, setBusy] = useState(false);
  const [busyBuild, setBusyBuild] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [isPreviewing, setIsPreviewing] = useState(false);
  const [isBuilding, setIsBuilding] = useState(false);
  const [previewStatusMsg, setPreviewStatusMsg] = useState('');
  const [previewFailedOrTimeout, setPreviewFailedOrTimeout] = useState(false);
  
  const [toastMessage, setToastMessage] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  
  type LastScan = {
    scanId: string;
    imageUrl?: string;
    source?: 'ar' | 'upload';
    projectId?: string;
    roi?: { x: number; y: number; w: number; h: number };
    measure?: { width_in: number; height_in: number; px_per_in: number };
    measuring?: boolean;
  };
  
  const [lastScan, setLastScan] = useState<LastScan | null>(null);
  const [roiOpen, setRoiOpen] = useState(false);
  const [lastRegionId, setLastRegionId] = useState<string | null>(null);
  const [measureOpen, setMeasureOpen] = useState(false);
  
  const insets = useSafeAreaInsets();
  const tabBarHeight = useOptionalTabBarHeight();

  const scrollRef = React.useRef<ScrollView>(null);
  const descRef = React.useRef<TextInput>(null);
  const ctaRef = React.useRef<View>(null);
  const lastScanRef = useRef<LastScan | null>(null);
  
  type MissingKey = 'title' | 'description' | 'budget' | 'skill' | null;
  const [missing, setMissing] = useState<MissingKey>(null);
  const posRef = useRef<Record<string, number>>({});
  
  const titleShake = useShake();
  const descShake = useShake();
  const budgetShake = useShake();
  const skillShake = useShake();

  const budgetOptions = ['$', '$$', '$$$'];
  const skillOptions = ['Beginner', 'Intermediate', 'Advanced'];

  const canPreview = ents?.previewAllowed ?? false;

  const descOk = (description?.trim().length ?? 0) >= 10;
  const budgetOk = !!budget;
  const skillOk = !!skillLevel;
  const canProceed = descOk && budgetOk && skillOk;

  const labelFor: Record<Exclude<MissingKey, null>, string> = {
    title: 'Project Title',
    description: 'Project Description',
    budget: 'Budget',
    skill: 'Skill Level',
  };

  const firstMissing = (): MissingKey => {
    if (!title?.trim?.()) return 'title';
    if (!description || description.trim().length < 10) return 'description';
    if (!budget) return 'budget';
    if (!skillLevel) return 'skill';
    return null;
  };

  const handleBlocked = () => {
    const miss = firstMissing();
    if (!miss) return;
    setMissing(miss);
    
    // Shake the field
    ({ title: titleShake, description: descShake, budget: budgetShake, skill: skillShake } as any)[miss].shake();
    
    // Scroll into view
    const y = posRef.current[miss] ?? 0;
    scrollRef.current?.scrollTo({ y: Math.max(y - 24, 0), animated: true });
    
    // Message
    Alert.alert('Almost there', `Please fill in ${labelFor[miss]} to continue.`);
    
    // Clear outline after a short delay
    setTimeout(() => setMissing(null), 1400);
  };


  function hasValidForm() {
    return description.trim().length >= 10 && !!budget && !!skillLevel;
  }

  const canSubmit = (title?.trim()?.length ?? 0) >= 3 && (description?.trim()?.length ?? 0) >= 10 && !!budget && !!skillLevel;

  function resetForm() {
    try {
      setDraftId(null);
      setTitle('');
      setDescription('');
      setBudget('');
      setSkillLevel('');
      setPhotoUri(null);
      setLastScan(null);
      lastScanRef.current = null;
      setLastScanEphemeral(null);
      clearNewProjectDraft(); // wipe persisted draft
      console.log('[draft] cleared');
    } catch {}
  }

  function showToast(message: string, type: 'success' | 'error' = 'success') {
    setToastMessage(message);
    setToastType(type);
    setTimeout(() => setToastMessage(''), 2000);
  }

  const triggerHaptic = async (type = 'success') => {
    try {
      if (type === 'success') {
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } else {
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      }
    } catch (error) {
      // Haptics not available
    }
  };

  async function fetchEntitlementsSafe(userId: string) {
    try {
      const r = await api(`/me/entitlements/${userId}`);
      return r; // expected: { tier, remaining, previewAllowed }
    } catch {
      console.warn('[entitlements] falling back to Free defaults');
      return { tier: 'Free', remaining: 2, previewAllowed: false, ok: true };
    }
  }

  async function fetchEntitlements() {
    const userId = user?.id || USER_ID;
    const r = await fetchEntitlementsSafe(userId);
    const data = (r as any).data || r;
    setEnts({ 
      previewAllowed: !!(data?.previewAllowed) || false, 
      remaining: data?.remaining ?? 2
    });
  }

  useEffect(() => {
    fetchEntitlements();
    
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') {
        fetchEntitlements();
      }
    });
    
    return () => subscription.remove();
  }, []);

  // 1) Hydrate once on mount - do NOT overwrite if we already have local edits
  useEffect(() => {
    let alive = true;
    (async () => {
      if (hydratedRef.current) return;
      const stored = await loadNewProjectDraft();
      if (!alive) return;
      if (stored && Object.keys(stored).length > 0) {
        console.log('[draft] mount→hydrate', stored);
        // Merge: restore stored values
        if (stored.name) setTitle(stored.name);
        if (stored.description) setDescription(stored.description);
        if (stored.budget) setBudget(String(stored.budget));
        if (stored.skill_level) setSkillLevel(stored.skill_level);
        if (stored.projectId) setDraftId(stored.projectId);
      }
      hydratedRef.current = true;
    })();
    
    // Restore last scan from ephemeral store
    const { getLastScan } = require('../lib/ephemeral');
    const cached = getLastScan();
    if (cached) {
      setLastScan(cached);
      lastScanRef.current = cached;
    }
    
    return () => { alive = false; };
  }, []);

  // 2) Persist on any field change (debounced)
  useEffect(() => {
    if (!hydratedRef.current) return; // avoid saving empty default before hydration
    if (clearingRef.current) return; // don't persist while clearing
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    saveTimerRef.current = setTimeout(async () => {
      const currentDraft = await loadNewProjectDraft();
      saveNewProjectDraft({
        projectId: draftId,
        name: title,
        description,
        budget: budget,
        skill_level: skillLevel,
        measurement: currentDraft?.measurement,
      });
      console.log('[draft] autosave', { name: title, hasDesc: !!description, budget, skill_level: skillLevel, projectId: draftId });
    }, 250);
    return () => {
      if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    };
  }, [title, description, budget, skillLevel, draftId]);

  // Keep form alive when navigating away - no auto-clear on blur
  // User must explicitly tap "Clear Form" to reset


  // Handle photo from scan navigation params
  useEffect(() => {
    if (route.params?.photoUri && route.params?.fromScan) {
      setPhotoUri(route.params.photoUri);
      showToast('Room photo added', 'success');
      uploadPhotoToSupabase(route.params.photoUri, 'scan');
      // Clear params to avoid re-triggering
      navigation.setParams({ photoUri: undefined, fromScan: undefined } as any);
    }
  }, [route.params?.photoUri, route.params?.fromScan]);

  // Handle savedScan param from scan screen - only update scan, preserve form
  useFocusEffect(
    React.useCallback(() => {
      const s = route.params?.savedScan;
      if (s) {
        console.log('[newProject] savedScan arrived', s);
        setLastScan(s);
        lastScanRef.current = s;
        setLastScanEphemeral(s);
        // Clear param only - do NOT reset form fields
        navigation.setParams({ savedScan: undefined } as any);
        
        // For AR scans, show "Measuring..." state and poll draft for measurement result
        if (s.source === 'ar' && s.scanId && s.projectId) {
          setLastScan(prev => prev ? { ...prev, measuring: true } : prev);
          lastScanRef.current = lastScanRef.current ? { ...lastScanRef.current, measuring: true } : lastScanRef.current;
        }
      }
      return () => {};
    }, [route.params?.savedScan, navigation])
  );

  // Poll draft for measurement updates
  useEffect(() => {
    if (!lastScan?.measuring) return;
    
    const pollInterval = setInterval(async () => {
      const draft = await loadNewProjectDraft();
      if (draft?.measurement) {
        setLastScan(prev => prev ? {
          ...prev,
          measure: {
            width_in: draft.measurement!.width_in,
            height_in: draft.measurement!.height_in,
            px_per_in: draft.measurement!.px_per_in,
          },
          measuring: false
        } : prev);
        lastScanRef.current = lastScanRef.current ? {
          ...lastScanRef.current,
          measure: {
            width_in: draft.measurement!.width_in,
            height_in: draft.measurement!.height_in,
            px_per_in: draft.measurement!.px_per_in,
          },
          measuring: false
        } : lastScanRef.current;
      }
    }, 1500);

    return () => clearInterval(pollInterval);
  }, [lastScan?.measuring]);

  // Handle section deep-link parameter
  const section = route.params?.section as 'desc' | 'media' | 'preview' | 'plan' | undefined;

  const scrollToView = (ref: React.RefObject<View>) => {
    ref.current?.measureLayout(
      findNodeHandle(scrollRef.current) as number,
      (x, y) => scrollRef.current?.scrollTo({ y: Math.max(y - 24, 0), animated: true }),
      () => {}
    );
  };

  useEffect(() => {
    if (!section) return;
    const t = setTimeout(() => {
      switch (section) {
        case 'desc':
          descRef.current?.focus();
          break;
        case 'media':
          onUploadPhoto();
          break;
        case 'plan':
          scrollToView(ctaRef);
          break;
      }
    }, 250);
    return () => clearTimeout(t);
  }, [section]);

  async function getOrCreateProjectId() {
    try {
      const { data } = await supabase.auth.getSession();
      if (!data?.session?.user) {
        Alert.alert('Sign in required', 'Please sign in to create a project.');
        (navigation as any).navigate('Auth', { screen: 'SignIn' });
        throw new Error('AUTH_REQUIRED');
      }

      const currentDraft = {
        projectId: draftId ?? null,
        name: title,
        description,
        budget,
        skill_level: skillLevel,
      };
      const id = await ensureProjectForDraft(currentDraft);
      setDraftId(id);
      // keep storage in sync (optional, ensureProjectForDraft already saved)
      await saveNewProjectDraft({ ...currentDraft, projectId: id });
      return id;
    } catch (e: any) {
      if (e?.message === 'AUTH_REQUIRED') {
        throw e;
      }
      const msg =
        e?.userMessage ||
        (typeof e?.message === 'string' ? e.message : 'Could not create project. Please check your inputs and try again.');
      Alert.alert('Fix required', msg);
      throw e;
    }
  }

  function pickPhotoWeb(): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.onchange = () => {
          const file = input.files?.[0];
          if (!file) return reject(new Error('No file selected'));
          if (!file.type?.startsWith?.('image/')) return reject(new Error('Please select an image'));
          const reader = new FileReader();
          reader.onerror = () => reject(new Error('Failed to read file'));
          reader.onload = () => {
            const dataUrl = String(reader.result);
            console.info('[photo] picked web', { type: file.type, size: file.size });
            resolve(dataUrl);
          };
          reader.readAsDataURL(file);
        };
        input.click();
      } catch (e) {
        reject(e);
      }
    });
  }

  async function pickPhotoNative(): Promise<string> {
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.85,
      allowsEditing: false,
      base64: false,
    });
    if ((res as any).canceled) throw new Error('Selection canceled');
    const uri = (res as any).assets?.[0]?.uri;
    if (!uri) throw new Error('No image URI');
    console.info('[photo] picked native', { uri });
    return uri;
  }

  async function uploadPhotoToSupabase(uri: string, source: 'scan' | 'upload') {
    if (!user) {
      showToast('User not found', 'error');
      return;
    }

    setUploading(true);
    try {
      if (Platform.OS === 'web' && uri.startsWith('data:')) {
        console.log('[web] Skipping upload for data URL (web preview only)');
        showToast('Photo added (web preview)', 'success');
        return;
      }

      const { scanId, imageUrl } = await uploadRoomScan({
        uri,
        userId: user.id,
        projectId: draftId ?? null,
      });
      
      const scanData = { scanId, imageUrl, source: source === 'upload' ? 'upload' as const : 'ar' as const };
      setLastScan(scanData);
      lastScanRef.current = scanData;
      setLastScanEphemeral(scanData);
      console.log('[scan saved]', { scanId, imageUrl });
      showToast('Scan uploaded & saved', 'success');
    } catch (e) {
      console.error('[upload failed]', e);
      showToast('Upload failed', 'error');
    } finally {
      setUploading(false);
    }
  }

  const onScanRoom = async () => {
    if (!canProceed) {
      Alert.alert('Almost there', 'Please fill in title and description first.');
      const missing = firstMissing();
      if (missing === 'title' && posRef.current.title !== undefined) {
        scrollRef.current?.scrollTo({ y: posRef.current.title - 100, animated: true });
      } else if (missing === 'description' && posRef.current.description !== undefined) {
        scrollRef.current?.scrollTo({ y: posRef.current.description - 100, animated: true });
      }
      return;
    }
    
    try {
      Keyboard.dismiss();
      const projectId = await getOrCreateProjectId(); // throws + shows Alert on failure
      
      // Persist draft before leaving for Scan (survives remount just in case)
      await saveNewProjectDraft({
        projectId: draftId ?? projectId,
        name: title,
        description,
        budget,
        skill_level: skillLevel,
      });
      console.log('[draft] preserve before scan');
      
      (navigation as any).navigate('Scan', { projectId });
    } catch (e) {
      // Error already shown by getOrCreateProjectId
    }
  };

  const onUploadPhoto = async () => {
    if (!canProceed) {
      Alert.alert('Almost there', 'Please fill in title and description first.');
      const missing = firstMissing();
      if (missing === 'title' && posRef.current.title !== undefined) {
        scrollRef.current?.scrollTo({ y: posRef.current.title - 100, animated: true });
      } else if (missing === 'description' && posRef.current.description !== undefined) {
        scrollRef.current?.scrollTo({ y: posRef.current.description - 100, animated: true });
      }
      return;
    }
    
    try {
      const projectId = await getOrCreateProjectId(); // throws + shows Alert on failure
      
      // Persist draft before upload (in case something goes wrong)
      await saveNewProjectDraft({
        projectId: draftId ?? projectId,
        name: title,
        description,
        budget,
        skill_level: skillLevel,
      });
      console.log('[draft] preserve before upload');
      
      const uri = Platform.OS === 'web' ? await pickPhotoWeb() : await pickPhotoNative();
      setPhotoUri(uri);
      await uploadPhotoToSupabase(uri, 'upload');
    } catch (err: any) {
      // Skip alert if error came from getOrCreateProjectId (it already showed one)
      if (err?.userMessage) return;
      if (err?.message === 'Selection canceled' || err?.message === 'No file selected') return;
      Alert.alert('Photo picker', err?.message || 'Could not select photo');
    }
  };


  async function uploadProjectImage(id: string, photoUri?: string | null) {
    if (!photoUri) throw new Error('NO_PHOTO');

    // If already a public URL, use the server's direct_url shortcut
    if (photoUri.startsWith('http')) {
      return await api(`/api/projects/${id}/image`, {
        method: 'POST',
        body: JSON.stringify({ direct_url: photoUri }),
      });
    }

    // Build FormData across platforms
    const form = new FormData();

    if (Platform.OS === 'web') {
      // Expo ImagePicker on web returns a data URL; convert to Blob
      const res = await fetch(photoUri);
      const blob = await res.blob();
      form.append('file', blob, 'upload.jpg');
    } else {
      // Native RN needs { uri, name, type }
      // @ts-ignore – RN FormData type
      form.append('file', {
        uri: photoUri,
        name: 'upload.jpg',
        type: 'image/jpeg',
      });
    }

    return await api(`/api/projects/${id}/image`, { method: 'POST', body: form });
  }

  async function onBuildWithoutPreview() {
    if (busyBuild || isBuilding) return;
    setBusyBuild(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        showToast('User not found', 'error');
        setBusyBuild(false);
        return;
      }

      const id = await getOrCreateProjectId(); // throws + shows Alert on failure

      // Upload image if needed before build
      if (photoUri) {
        try {
          const u = await uploadProjectImage(id, photoUri);
          console.log('[upload]', u);
        } catch (e) {
          console.error('image upload failed', e);
          showToast('Could not upload photo. Please re-select and try again.', 'error');
          setBusyBuild(false);
          return;
        }
      }

      const res = await apiRaw(`/api/projects/${id}/build-without-preview?user_id=${encodeURIComponent(user.id)}`, {
        method: 'POST',
      });
      console.log('[build] accepted', res);
      
      // Link the last scan to the project if available
      const ls = lastScanRef.current;
      try {
        if (ls?.scanId) {
          await attachScanToProject(ls.scanId, id);
        }
      } catch (e) {
        console.warn('[link scan]', e);
      }
      
      setBusyBuild(false);
      setIsBuilding(true);
      
      // Poll for ready status
      const pollRes = await pollProjectReady(id, { tries: 40, interval: 2000 });
      setIsBuilding(false);
      
      if (pollRes.ok) {
        // Warm cache before navigation
        const { fetchProjectPlanMarkdown } = await import('../lib/api');
        await fetchProjectPlanMarkdown(id, { cacheBust: true }).catch(() => null);
        console.log('[cache] warmed before nav');
        
        // Mark project as active (promote out of draft)
        const { data: sessionData } = await supabase.auth.getSession();
        const user_id = sessionData?.session?.user?.id;
        const patchPayload = { user_id, status: 'active' };
        console.log('[build] PATCH payload', { user_id: !!user_id, status: 'active' });
        
        try {
          await patchProject(id, patchPayload);
          console.log('[project] marked active');
        } catch (e: any) {
          if (e?.message?.includes('404')) {
            console.log('[build] PATCH 404 (likely old deploy) – continuing');
          } else {
            console.warn('[build] PATCH failed', e?.message);
          }
        }
        
        // SUCCESS: Clear form and navigate
        try {
          clearingRef.current = true;
          await clearNewProjectDraft?.();
          setDraftId(null);
          setTitle('');
          setDescription('');
          setBudget('');
          setSkillLevel('');
          setPhotoUri(null);
          setLastScan(null);
          lastScanRef.current = null;
          console.log('[media] cleared after build (plan only)');
          setTimeout(() => { clearingRef.current = false; }, 0);
        } catch {}
        
        // Reset navigation to Projects tab with ProjectsList → ProjectDetails stack
        // Pass both id and projectId to avoid param name mismatch.
        navigation.dispatch(
          CommonActions.reset({
            index: 0,
            routes: [
              {
                name: 'Main',
                state: {
                  type: 'tab',
                  index: 2, // 0=Home, 1=NewProject, 2=Projects
                  routes: [
                    { name: 'Home' },
                    { name: 'NewProject' },
                    {
                      name: 'Projects',
                      state: {
                        type: 'stack',
                        index: 1,
                        routes: [
                          { name: 'ProjectsList' },
                          { name: 'ProjectDetails', params: { id, projectId: id, justBuilt: true } },
                        ],
                      },
                    },
                    { name: 'Profile' },
                  ],
                },
              },
            ],
          })
        );
      } else {
        Alert.alert('Still building', 'Plan is taking longer than usual. You can continue and check the Projects tab.');
      }
    } catch (e) {
      // Error already shown by getOrCreateProjectId
      setBusyBuild(false);
      setIsBuilding(false);
    }
  }

  // Exponential backoff utility
  function* backoffDelays(ms = 1500, factor = 1.6, max = 10000, tries = 12) {
    let d = ms;
    for (let i = 0; i < tries; i++) {
      yield Math.min(d, max);
      d = Math.ceil(d * factor);
    }
  }

  async function handleBuildWithPreview() {
    if (isBuilding || isPreviewing) return;
    setPreviewFailedOrTimeout(false);

    // 1) Auth required
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      Alert.alert('Sign in required', 'Please sign in to build with preview.');
      return;
    }

    // 2) Validate required fields (using description as the prompt)
    if (!description || description.trim().length < 3) {
      Alert.alert('Add description', 'Please enter a description of what you want to build.');
      return;
    }

    // 3) Ensure project exists first
    let projectId: string;
    try {
      projectId = await ensureProjectForDraft({
        name: title,
        description,
        budget,
        skill_level: skillLevel,
        projectId: draftId,
      });
    } catch (e: any) {
      Alert.alert('Project creation failed', String(e?.message || e));
      return;
    }

    if (!projectId) {
      Alert.alert('Missing project', 'Could not create project.');
      return;
    }

    // 4) Upload image if needed
    if (photoUri) {
      try {
        await uploadProjectImage(projectId, photoUri);
        console.log('[upload] complete');
      } catch (e) {
        console.error('[upload] failed', e);
        Alert.alert('Upload failed', 'Could not upload photo. Please try again.');
        return;
      }
    }

    // 5) Link scan to project if available
    const ls = lastScanRef.current;
    try {
      if (ls?.scanId) {
        await attachScanToProject(ls.scanId, projectId);
      }
    } catch (e) {
      console.warn('[link scan]', e);
    }

    // 6) Load latest project data to get image + dimensions
    const { data: projRow, error: projErr } = await supabase
      .from('projects')
      .select('id,input_image_url,dimensions_json')
      .eq('id', projectId)
      .single();
    
    if (projErr || !projRow) {
      Alert.alert('Project not found', 'Could not load project for preview.');
      return;
    }

    const photo_url = projRow.input_image_url || photoUri || '';
    const measurements = projRow.dimensions_json || (ls?.measure ? {
      width_in: ls.measure.width_in,
      height_in: ls.measure.height_in,
      px_per_in: ls.measure.px_per_in
    } : null);
    
    if (!photo_url) {
      Alert.alert('Add a photo', 'Please upload a photo before generating a preview.');
      return;
    }

    try {
      setIsPreviewing(true);

      // 7) Call backend /preview with required fields
      const res = await fetch(`${API_BASE_URL}/preview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          photo_url,
          prompt: description,
          measurements
        })
      });
      const data = await res.json();
      if (!res.ok || !data?.ok || !data?.preview_url) {
        throw new Error(data?.error || `HTTP ${res.status}`);
      }

      // 8) Persist preview to Supabase
      const { error: upErr } = await supabase
        .from('projects')
        .update({
          preview_url: data.preview_url,
          preview_status: 'ready',
          preview_meta: { source: data.source || 'stub|decor8', at: new Date().toISOString() },
          updated_at: new Date().toISOString()
        })
        .eq('id', projectId);
      if (upErr) throw upErr;

      // 9) Clear form
      try {
        clearingRef.current = true;
        await clearNewProjectDraft?.();
        setDraftId(null);
        setTitle('');
        setDescription('');
        setBudget('');
        setSkillLevel('');
        setPhotoUri(null);
        setLastScan(null);
        lastScanRef.current = null;
        console.log('[media] cleared after build (with preview)');
        setTimeout(() => { clearingRef.current = false; }, 0);
      } catch {}

      // 10) Navigate to the correct details screen (route key: "ProjectDetails")
      //     Pass both id and projectId to avoid param name mismatch.
      navigation.dispatch(
        CommonActions.reset({
          index: 0,
          routes: [
            {
              name: 'Main',
              state: {
                type: 'tab',
                index: 2,
                routes: [
                  { name: 'Home' },
                  { name: 'NewProject' },
                  {
                    name: 'Projects',
                    state: {
                      type: 'stack',
                      index: 1,
                      routes: [
                        { name: 'ProjectsList' },
                        { name: 'ProjectDetails', params: { id: projectId, projectId } },
                      ],
                    },
                  },
                  { name: 'Profile' },
                ],
              },
            },
          ],
        })
      );
    } catch (e: any) {
      console.error('[preview submit] fail', e);
      Alert.alert('Could not start preview', String(e?.message || e));
      setPreviewFailedOrTimeout(true);
    } finally {
      setIsPreviewing(false);
    }
  }

  const handleBudgetSelect = (option: string) => {
    setBudget(option);
    setShowBudgetDropdown(false);
  };

  const handleSkillSelect = (option: string) => {
    setSkillLevel(option);
    setShowSkillDropdown(false);
  };

  const TILE_SIZE = 300;
  const ICON_SIZE = 32;

  return (
    <KeyboardAvoidingView 
      style={{ flex: 1 }} 
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <SafeAreaView style={styles.container} edges={['top', 'left', 'right']}>
        <ScrollView 
          ref={scrollRef}
          style={styles.scrollView}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="on-drag"
          scrollEnabled={!roiOpen && !measureOpen}
          contentContainerStyle={{
            paddingHorizontal: spacing.lg,
            paddingTop: spacing.md,
            paddingBottom: Math.max(tabBarHeight + 20, insets.bottom + 20) + 40,
          }}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.header}>
            <Text style={styles.title}>Create Your New Project</Text>
            <Text style={styles.subtitle}>Provide details about your DIY project and watch the magic unfold!</Text>
          </View>

          <Animated.View
            onLayout={(e) => { posRef.current.title = e.nativeEvent.layout.y; }}
            style={[
              titleShake.style,
              missing === 'title' && { borderWidth: 2, borderColor: '#EF4444', borderRadius: 12, padding: 2 },
            ]}
          >
            <View style={styles.fieldContainer}>
              <Text style={styles.fieldLabel}>Project Title</Text>
              <TextInput
                style={styles.textArea}
                value={title}
                onChangeText={setTitle}
                placeholder="e.g., Built-in Bookcase"
                placeholderTextColor={colors.textSecondary}
                returnKeyType="done"
                blurOnSubmit
                onSubmitEditing={() => Keyboard.dismiss()}
              />
            </View>
          </Animated.View>

          <Animated.View
            onLayout={(e) => { posRef.current.description = e.nativeEvent.layout.y; }}
            style={[
              descShake.style,
              missing === 'description' && { borderWidth: 2, borderColor: '#EF4444', borderRadius: 12, padding: 2 },
            ]}
          >
            <View style={styles.fieldContainer}>
              <Text style={styles.fieldLabel}>Project Description</Text>
              <TextInput
                ref={descRef}
                style={[styles.textArea, { height: 84 }]}
                value={description}
                onChangeText={setDescription}
                placeholder="e.g. Build 3 floating shelves for living room wall (minimum 10 characters)"
                placeholderTextColor={colors.textSecondary}
                multiline
                numberOfLines={3}
                scrollEnabled={false}
                textAlignVertical="top"
                returnKeyType="done"
                blurOnSubmit
                onSubmitEditing={() => Keyboard.dismiss()}
              />
              <Text style={styles.charCount}>
                {description.length}/10 characters minimum
              </Text>
            </View>
          </Animated.View>

          <Animated.View
            onLayout={(e) => { posRef.current.budget = e.nativeEvent.layout.y; }}
            style={[
              budgetShake.style,
              missing === 'budget' && { borderWidth: 2, borderColor: '#EF4444', borderRadius: 12, padding: 2 },
            ]}
          >
            <View style={styles.budgetFieldWrapper}>
              <View style={styles.fieldContainer}>
            <Text style={styles.fieldLabel}>Budget</Text>
            <Pressable 
              style={styles.dropdown}
              onPress={() => {
                Keyboard.dismiss();
                setShowBudgetDropdown(true);
                setShowSkillDropdown(false);
              }}
            >
              <Text style={[styles.dropdownText, !budget && styles.placeholderText]}>
                {budget || 'Select budget range'}
              </Text>
              <Ionicons 
                name={showBudgetDropdown ? 'chevron-up' : 'chevron-down'} 
                size={20} 
                color={colors.textSecondary} 
              />
            </Pressable>
            
            <Modal
              transparent
              visible={showBudgetDropdown}
              animationType="fade"
              onRequestClose={() => setShowBudgetDropdown(false)}
            >
              <Pressable 
                style={styles.modalOverlay} 
                onPress={() => setShowBudgetDropdown(false)}
              >
                <View style={[styles.dropdownOptions, styles.budgetDropdownPosition]}>
                  {budgetOptions.map((option) => (
                    <Pressable
                      key={option}
                      style={styles.dropdownOption}
                      onPress={() => handleBudgetSelect(option)}
                    >
                      <Text style={styles.dropdownOptionText}>{option}</Text>
                    </Pressable>
                  ))}
                </View>
              </Pressable>
            </Modal>
              </View>
            </View>
          </Animated.View>

          <Animated.View
            onLayout={(e) => { posRef.current.skill = e.nativeEvent.layout.y; }}
            style={[
              skillShake.style,
              missing === 'skill' && { borderWidth: 2, borderColor: '#EF4444', borderRadius: 12, padding: 2 },
            ]}
          >
            <View style={styles.skillFieldWrapper}>
            <View style={styles.fieldContainer}>
            <Text style={styles.fieldLabel}>Skill Level</Text>
            <Pressable 
              style={styles.dropdown}
              onPress={() => {
                Keyboard.dismiss();
                setShowSkillDropdown(true);
                setShowBudgetDropdown(false);
              }}
            >
              <Text style={[styles.dropdownText, !skillLevel && styles.placeholderText]}>
                {skillLevel || 'Select skill level'}
              </Text>
              <Ionicons 
                name={showSkillDropdown ? 'chevron-up' : 'chevron-down'} 
                size={20} 
                color={colors.textSecondary} 
              />
            </Pressable>
            
            <Modal
              transparent
              visible={showSkillDropdown}
              animationType="fade"
              onRequestClose={() => setShowSkillDropdown(false)}
            >
              <Pressable 
                style={styles.modalOverlay} 
                onPress={() => setShowSkillDropdown(false)}
              >
                <View style={[styles.dropdownOptions, styles.skillDropdownPosition]}>
                  {skillOptions.map((option) => (
                    <Pressable
                      key={option}
                      style={styles.dropdownOption}
                      onPress={() => handleSkillSelect(option)}
                    >
                      <Text style={styles.dropdownOptionText}>{option}</Text>
                    </Pressable>
                  ))}
                </View>
              </Pressable>
            </Modal>
              </View>
            </View>
          </Animated.View>

          <View style={styles.tilesContainer}>
          <View style={{ 
            marginTop: 12, 
            marginBottom: 8, 
            alignItems: 'center' 
          }}>
            <View style={{ height: 1, width: '100%', backgroundColor: 'rgba(229,231,235,0.9)' }} />
            <View style={{ position: 'absolute', top: -9, paddingHorizontal: 8, backgroundColor: '#FFF' }}>
              <Text style={{ color: '#6B7280', fontSize: 12, fontWeight: '600' }}>
                Add your room photo
              </Text>
            </View>
          </View>

          {!photoUri ? (
            <View style={{ flexDirection: 'row', gap: 12, justifyContent: 'space-between', paddingVertical: 12 }}>
              <Pressable
                testID="btn-scan-room"
                disabled={!canProceed || uploading}
                style={({ pressed }) => ({
                  flex: 1,
                  height: 120,
                  borderRadius: 16,
                  justifyContent: 'center',
                  alignItems: 'center',
                  backgroundColor: pressed ? '#6D28D9' : brand.primary,
                  shadowColor: '#7C3AED',
                  shadowOpacity: (!canProceed || uploading) ? 0 : 0.3,
                  shadowRadius: 12,
                  shadowOffset: { width: 0, height: 4 },
                  elevation: 6,
                  opacity: (!canProceed || uploading) ? 0.5 : 1,
                })}
                onPress={onScanRoom}
              >
                <Ionicons 
                  name="scan-outline" 
                  size={28} 
                  color="#FFFFFF" 
                  style={{ marginBottom: 8 }} 
                />
                <Text style={{ color: '#FFFFFF', fontSize: 16, fontWeight: '600', fontFamily: typography.fontFamily.manropeSemiBold }}>
                  Scan room
                </Text>
              </Pressable>

              <Pressable
                testID="btn-upload-photo"
                disabled={!canProceed || uploading}
                style={({ pressed }) => ({
                  flex: 1,
                  height: 120,
                  borderRadius: 16,
                  justifyContent: 'center',
                  alignItems: 'center',
                  backgroundColor: pressed ? '#F9FAFB' : '#FFFFFF',
                  borderWidth: 1.5,
                  borderColor: '#D1D5DB',
                  opacity: (!canProceed || uploading) ? 0.5 : 1,
                })}
                onPress={onUploadPhoto}
              >
                {uploading ? (
                  <ActivityIndicator size="small" color={brand.primary} />
                ) : (
                  <>
                    <Ionicons 
                      name="image-outline" 
                      size={28} 
                      color={brand.primary} 
                      style={{ marginBottom: 8 }} 
                    />
                    <Text style={{ color: colors.textPrimary, fontSize: 16, fontWeight: '600', fontFamily: typography.fontFamily.manropeSemiBold }}>
                      Upload Photo
                    </Text>
                  </>
                )}
              </Pressable>
            </View>
          ) : (
            <Pressable
              testID="np-photo-preview"
              onPress={onUploadPhoto}
              disabled={uploading}
              style={{ 
                borderRadius: 16, 
                overflow: 'hidden', 
                borderWidth: 1, 
                borderColor: '#E5E7EB',
                marginVertical: 8,
              }}
            >
              <Image 
                source={{ uri: photoUri }} 
                style={{ 
                  width: '100%', 
                  aspectRatio: 16/9,
                }} 
                resizeMode="cover"
              />
              {uploading && (
                <View style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  backgroundColor: 'rgba(0,0,0,0.3)',
                  justifyContent: 'center',
                  alignItems: 'center',
                }}>
                  <ActivityIndicator size="large" color="#FFFFFF" />
                </View>
              )}
              <View style={{ 
                padding: 12, 
                alignItems: 'flex-end',
                backgroundColor: '#FFFFFF',
              }}>
                <Text style={{ color: brand.primary, fontSize: 14, fontWeight: '600' }}>
                  {uploading ? 'Uploading...' : 'Change photo'}
                </Text>
              </View>
            </Pressable>
          )}
          </View>

          {(lastScan || photoUri) && (() => {
            const thumbnailUri = lastScan?.imageUrl ?? photoUri;
            const label = lastScan?.source === 'ar' ? 'Saved scan (AR)' : 'Uploaded photo';
            console.log('[media] card label', label, { hasImage: !!thumbnailUri });
            
            return (
              <View style={{
                marginTop: 16,
                padding: 12,
                backgroundColor: '#F9FAFB',
                borderRadius: 12,
                borderWidth: 1,
                borderColor: '#E5E7EB',
                flexDirection: 'row',
                alignItems: 'center',
                gap: 12,
              }}>
                {thumbnailUri ? (
                  <Image 
                    source={{ uri: thumbnailUri }} 
                    style={{
                      width: 60,
                      height: 60,
                      borderRadius: 8,
                    }}
                    resizeMode="cover"
                  />
                ) : (
                  <View style={{
                    width: 60,
                    height: 60,
                    borderRadius: 8,
                    backgroundColor: '#E5E7EB',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}>
                    <Ionicons name="cube-outline" size={28} color="#9CA3AF" />
                  </View>
                )}
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 14, fontWeight: '600', color: '#1F2937', marginBottom: 4 }}>
                    {label}
                  </Text>
              
                  {lastScan?.measuring && (
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 }}>
                      <ActivityIndicator size="small" color="#7C3AED" />
                      <Text style={{ fontSize: 12, color: '#7C3AED', fontWeight: '500' }}>
                        Measuring…
                      </Text>
                    </View>
                  )}
                  
                  {lastScan?.measure && !lastScan?.measuring && (
                    <View style={{
                      marginTop: 4,
                      paddingHorizontal: 8,
                      paddingVertical: 4,
                      backgroundColor: '#F3F0FF',
                      borderRadius: 6,
                      alignSelf: 'flex-start',
                    }}>
                      <Text style={{ fontSize: 11, fontWeight: '600', color: '#7C3AED' }}>
                        Measurements • {lastScan.measure.width_in}" × {lastScan.measure.height_in}"
                      </Text>
                    </View>
                  )}
                  
                  {lastScan && !lastScan.measuring && !lastScan.measure && (
                    <Text style={{ fontSize: 12, color: '#6B7280' }}>
                      {lastScan.source === 'ar' 
                        ? `${lastScan.scanId.slice(0, 8)}…`
                        : `${lastScan.scanId.slice(0, 8)}…`}
                    </Text>
                  )}
                </View>
            {/* V1: hide tool buttons for uploads */}
            {__HIDE_MEDIA_TOOLS ? null : lastScan?.imageUrl && (
              <View style={{ flexDirection: 'column', gap: 8 }}>
                <Pressable
                  onPress={() => setRoiOpen(true)}
                  style={({ pressed }) => ({
                    paddingHorizontal: 12,
                    paddingVertical: 8,
                    borderRadius: 8,
                    backgroundColor: pressed ? '#EDE9FE' : '#F3F0FF',
                    borderWidth: 1,
                    borderColor: '#DDD6FE',
                  })}
                >
                  <Text style={{ fontSize: 13, fontWeight: '600', color: brand.primary }}>
                    Mark area
                  </Text>
                </Pressable>
                <Pressable
                  onPress={() => setMeasureOpen(true)}
                  style={({ pressed }) => ({
                    paddingHorizontal: 12,
                    paddingVertical: 8,
                    borderRadius: 8,
                    backgroundColor: pressed ? '#EDE9FE' : '#F3F0FF',
                    borderWidth: 1,
                    borderColor: '#DDD6FE',
                  })}
                >
                  <Text style={{ fontSize: 13, fontWeight: '600', color: brand.primary }}>
                    Measure
                  </Text>
                </Pressable>
              </View>
            )}
          </View>
            );
          })()}

          {(hasValidForm() || !!photoUri) && (
          <View ref={ctaRef} style={{ marginTop: 20 }}>
            {/* Loading banner */}
            {isBuilding && (
              <View style={{ padding: 14, borderRadius: 12, backgroundColor: '#EFE9FF', marginBottom: 12 }}>
                <ActivityIndicator color="#7C3AED" />
                <Text style={{ marginTop: 8, fontWeight: '600', textAlign: 'center' }}>
                  Building your plan…
                </Text>
                <Text style={{ color: '#5B5B66', textAlign: 'center', fontSize: 13, marginTop: 4 }}>
                  {isPreviewing 
                    ? 'Visual preview is generating in the background'
                    : "Hang tight — we'll open the project when it's ready"}
                </Text>
              </View>
            )}
            
            <View style={{ gap: 14, marginTop: 12 }}>
              {/* Primary: Generate AI Plan + Preview */}
              <View>
                <TouchableOpacity
                  activeOpacity={0.8}
                  accessibilityRole="button"
                  accessibilityLabel="Generate AI Plan + Preview"
                  disabled={!canSubmit || isBuilding || isPreviewing}
                  onPressIn={() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light)}
                  onPress={handleBuildWithPreview}
                  style={[
                    CTA.wrap,
                    CTA.primary,
                    (!canSubmit || isBuilding || isPreviewing) && CTA.disabled,
                    { borderRadius: 16 }
                  ]}
                >
                  <View style={CTA.row}>
                    <Text style={[CTA.title, { color: '#fff' }]}>
                      Generate AI Plan + Preview
                    </Text>
                    <Text style={[CTA.sub, { color: 'rgba(255,255,255,0.9)' }]} numberOfLines={2}>
                      Visual mockup of your space + complete AI plan
                    </Text>
                    {isPreviewing && previewStatusMsg && (
                      <View style={{ marginTop: 10, flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                        <ActivityIndicator size="small" color="#fff" />
                        <Text style={{ color: '#fff', fontSize: 13, fontWeight: '500' }}>
                          {previewStatusMsg}
                        </Text>
                      </View>
                    )}
                  </View>
                </TouchableOpacity>
                
                {/* Retry preview button (only on failure/timeout) */}
                {previewFailedOrTimeout && draftId && (
                  <Pressable
                    onPress={async () => {
                      console.log('[preview ui] retry');
                      setPreviewFailedOrTimeout(false);
                      setIsPreviewing(true);
                      setPreviewStatusMsg('Preview: queued…');
                      
                      const res = await submitPreview(draftId);
                      if (!res.ok) {
                        console.error('[preview ui] error submit retry');
                        simpleToast('Still unable to start preview.');
                        setPreviewFailedOrTimeout(true);
                        setIsPreviewing(false);
                        setPreviewStatusMsg('');
                        return;
                      }
                      
                      if (res.mode) console.log('[preview ui] mode', res.mode);
                      
                      const delays = backoffDelays(1200, 1.7, 9000, 14);
                      let attempt = 0;
                      let ready = false;
                      
                      for (const delay of delays) {
                        attempt++;
                        const statusRes = await getPreviewStatus(draftId);
                        console.log('[preview ui] poll', { projectId: draftId, attempt, status: statusRes.status });
                        
                        if (!statusRes.ok) {
                          simpleToast('Preview status check failed — retrying…');
                        } else if (statusRes.status === 'ready' && statusRes.preview_url) {
                          console.log('[preview ui] ready', { projectId: draftId, hasUrl: !!statusRes.preview_url });
                          if (statusRes.cached) console.log('[preview ui] cached hit');
                          ready = true;
                          
                          try {
                            await supabase
                              .from('projects')
                              .update({ 
                                preview_url: statusRes.preview_url,
                                preview_status: 'ready'
                              })
                              .eq('id', draftId);
                            console.log('[preview ui] cache updated retry');
                          } catch (e) {
                            console.warn('[preview ui] cache update failed', e);
                          }
                          
                          simpleToast('Preview is ready!');
                          setPreviewFailedOrTimeout(false);
                          break;
                        }
                        await new Promise(r => setTimeout(r, delay + Math.floor(Math.random() * 250)));
                      }
                      
                      if (!ready) {
                        console.warn('[preview ui] timeout retry', { projectId: draftId, attempts: attempt });
                        simpleToast('Preview still processing.');
                        setPreviewFailedOrTimeout(true);
                      }
                      
                      setIsPreviewing(false);
                      setPreviewStatusMsg('');
                    }}
                    style={({ pressed }) => ({
                      paddingVertical: 8,
                      paddingHorizontal: 12,
                      alignSelf: 'center',
                      opacity: pressed ? 0.6 : 1,
                    })}
                  >
                    <Text style={{ color: '#6D28D9', fontSize: 14, fontWeight: '600', textDecorationLine: 'underline' }}>
                      Retry preview
                    </Text>
                  </Pressable>
                )}
              </View>

              {/* Secondary: Create Plan Only (No Preview) */}
              <TouchableOpacity
                activeOpacity={0.85}
                accessibilityRole="button"
                accessibilityLabel="Create Plan Only (No Preview)"
                disabled={!canSubmit || isBuilding}
                onPressIn={() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light)}
                onPress={onBuildWithoutPreview}
                style={[
                  CTA.wrap,
                  CTA.secondary,
                  (!canSubmit || isBuilding) && CTA.disabled,
                ]}
              >
                <View style={CTA.row}>
                  <Text style={[CTA.title, { color: '#111827' }]}>Create Plan Only (No Preview)</Text>
                  <Text style={[CTA.sub, { color: '#374151' }]} numberOfLines={2}>
                    Full DIY plan—steps, materials, tools, cuts, time & cost
                  </Text>
                </View>
              </TouchableOpacity>
              
              <TouchableOpacity
                onPress={resetForm}
                style={{ marginTop: 16, alignItems: 'center' }}
              >
                <Text style={{ color: colors.textSecondary, fontSize: 14, fontWeight: '500' }}>
                  Clear Form
                </Text>
              </TouchableOpacity>
            </View>
          </View>
          )}
        </ScrollView>

        {toastMessage && (
        <View style={[
          styles.toast,
          toastType === 'error' && styles.toastError
        ]}>
          <Text style={styles.toastText}>{toastMessage}</Text>
        </View>
      )}

      {/* V1: hide ROI modal for upload flow */}
      {__HIDE_MEDIA_TOOLS ? null : (
        <RoiModal
          visible={roiOpen}
          imageUrl={lastScan?.imageUrl ?? ''}
          onCancel={() => setRoiOpen(false)}
          onSave={async (points, label) => {
            try {
              if (!lastScan?.scanId) throw new Error('No scan');
              const row = await saveRoomScanRegion({ scanId: lastScan.scanId, points, label });
              setLastRegionId(row.id);
              showToast('Area saved', 'success');
            } catch (e: any) {
              showToast(e?.message ?? 'Save failed', 'error');
            } finally {
              setRoiOpen(false);
            }
          }}
        />
      )}

      {/* V1: hide Measure modal for upload flow */}
      {__HIDE_MEDIA_TOOLS ? null : (
        <MeasureModal
          visible={measureOpen}
          scanId={lastScan?.scanId!}
          imageUrl={lastScan?.imageUrl ?? ''}
          regionId={lastRegionId ?? null}
          onCancel={() => setMeasureOpen(false)}
          onSaveLine={async ([a, b], valueInches) => {
            try {
              await saveLineMeasurement({
                scanId: lastScan!.scanId,
                regionId: lastRegionId ?? null,
                points: [a, b],
                valueInches,
              });
              showToast(`Saved ${valueInches.toFixed(1)} in`, 'success');
            } catch (e: any) {
              showToast(e?.message ?? 'Save failed', 'error');
            } finally {
              setMeasureOpen(false);
            }
          }}
        />
      )}
      </SafeAreaView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.surface,
    overflow: 'visible',
  },
  scrollView: {
    flex: 1,
    overflow: 'visible',
  },
  header: {
    marginBottom: 12,
  },
  title: {
    fontSize: 22,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#0F172A',
    marginTop: 8,
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 13,
    fontFamily: typography.fontFamily.inter,
    color: '#64748B',
    marginBottom: 12,
  },
  budgetFieldWrapper: {
    position: 'relative',
    zIndex: 2000,
    elevation: 2000,
    overflow: 'visible',
  },
  skillFieldWrapper: {
    position: 'relative',
    zIndex: 3000,
    elevation: 3000,
    overflow: 'visible',
  },
  fieldContainer: {
    marginBottom: 14,
    position: 'relative',
    overflow: 'visible',
  },
  fieldLabel: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#111827',
    marginBottom: 8,
  },
  textArea: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    fontFamily: typography.fontFamily.inter,
    color: colors.textPrimary,
    textAlignVertical: 'top',
  },
  charCount: {
    fontSize: 12,
    fontFamily: typography.fontFamily.inter,
    color: '#6B7280',
    marginTop: 6,
    textAlign: 'right',
  },
  dropdown: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    padding: 12,
    height: 44,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dropdownText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.inter,
    color: colors.textPrimary,
  },
  placeholderText: {
    color: colors.textSecondary,
  },
  dropdownOptions: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    marginHorizontal: 20,
    shadowColor: colors.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.06,
    shadowRadius: 20,
    elevation: 6,
    maxWidth: 300,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    justifyContent: 'center',
  },
  budgetDropdownPosition: {
    marginTop: -120,
  },
  skillDropdownPosition: {
    marginTop: -60,
  },
  dropdownOption: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  dropdownOptionText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.inter,
    color: colors.textPrimary,
  },
  tilesContainer: {
    marginTop: 8,
  },
  tileTitle: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#1F2937',
  },
  tileSubtitle: {
    fontSize: 13,
    fontFamily: typography.fontFamily.inter,
    color: '#6B7280',
    marginTop: 2,
  },
  primaryButton: {
    backgroundColor: '#F59E0B',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  primaryButtonDisabled: {
    backgroundColor: '#D1D5DB',
    shadowOpacity: 0,
    elevation: 0,
  },
  primaryButtonText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#FFF',
  },
  secondaryButton: {
    backgroundColor: '#FFF',
    borderWidth: 1.5,
    borderColor: '#F59E0B',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryButtonDisabled: {
    borderColor: '#D1D5DB',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontFamily: typography.fontFamily.manropeBold,
    color: '#F59E0B',
  },
  upgradeHint: {
    fontSize: 13,
    fontFamily: typography.fontFamily.inter,
    textAlign: 'center',
    marginTop: 8,
  },
  toast: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: '#111827',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  toastError: {
    backgroundColor: '#DC2626',
  },
  toastText: {
    fontSize: 14,
    fontFamily: typography.fontFamily.inter,
    color: '#FFF',
    fontWeight: '500' as any,
  },
});
