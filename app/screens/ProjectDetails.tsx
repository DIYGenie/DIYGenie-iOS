import React, { useCallback, useEffect, useRef, useState, useLayoutEffect } from 'react';
import { View, Image, ActivityIndicator, Pressable, Text, ScrollView, Alert, TouchableOpacity, Platform, Switch, Share, DeviceEventEmitter } from 'react-native';
import { useRoute, useNavigation, RouteProp, useFocusEffect } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSafeBack } from '../lib/useSafeBack';
import { fetchProjectById, fetchLatestScanForProject, fetchProjectProgress, updateProjectProgress, pollScanMeasurement, getMeasurement, MeasureResult } from '../lib/api';
import StatusBadge from '../components/StatusBadge';
import Toast from '../components/Toast';
import DimensionsCard from '../components/DimensionsCard';
import { saveImageToPhotos } from '../lib/media';
import SectionCard from '../components/SectionCard';
import * as Clipboard from 'expo-clipboard';
import * as FileSystem from 'expo-file-system';
import * as MediaLibrary from 'expo-media-library';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, Feather } from '@expo/vector-icons';
import { supabase } from '../lib/supabase';
import RulerOverlay from '../components/RulerOverlay';
import { simpleToast } from '../lib/ui';
import { formatPlanText } from '../lib/planFormat';
import { enableLayoutAnimOnce, animateSection } from '../lib/anim';
import { deleteProjectDeep } from '../lib/deleteProject';
import { brand } from '../../theme/colors';
import { useUser } from '../lib/useUser';
import { track } from '../lib/track';
import { log, warn } from '../lib/logger';

type RouteParams = { id: string; justBuilt?: boolean };
type R = RouteProp<Record<'ProjectDetails', RouteParams>, 'ProjectDetails'>;

export default function ProjectDetails() {
  const route = useRoute<R>();
  const navigation = useNavigation();
  const safeBack = useSafeBack();
  const { userId } = useUser();
  const projectId = route.params?.id;
  const justBuilt = route.params?.justBuilt;

  const [loading, setLoading] = useState(true);
  // hide debug actions (manual preview/plan triggers) on this screen
  const SHOW_DEBUG_ACTIONS = false;
  const ENABLE_RULER_OVERLAY = false; // MVP: off
  const [project, setProject] = useState<any>(null);
  const [scan, setScan] = useState<{ scanId: string; imageUrl: string; roi?: any; measureResult?: any } | null>(null);
  const [toast, setToast] = useState({ visible: false, message: '', type: 'success' as 'success' | 'error' });
  const [completedSteps, setCompletedSteps] = useState<number[]>([]);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [measure, setMeasure] = useState<MeasureResult | null>(null);
  const [showRuler, setShowRuler] = useState(false);
  const [heroW, setHeroW] = useState(0);
  const [openSections, setOpenSections] = useState<string[]>([]);
  const [previewTab, setPreviewTab] = useState<'before'|'after'>('after');
  const abortRef = useRef<AbortController | null>(null);
  const scanId = project?.last_scan_id || project?.scan_id || project?.scan?.id;
  
  const [stubPreviewUrl, setStubPreviewUrl] = useState(null);
  const [stubPreviewLoading, setStubPreviewLoading] = useState(false);
  const RAW_BASE = process.env.EXPO_PUBLIC_BASE_URL || 'http://localhost:5000';
  const API_BASE_URL = RAW_BASE.startsWith('http') ? RAW_BASE : `https://${RAW_BASE}`;
  
  const [planJson, setPlanJson] = useState(null);
  const [planLoading, setPlanLoading] = useState(false);
  const [deleting, setDeleting] = useState(false);

  enableLayoutAnimOnce();

  useEffect(() => {
    (async () => {
      if (!projectId) return;
      try {
        const stored = await AsyncStorage.getItem(`sections:${projectId}`);
        if (stored) setOpenSections(JSON.parse(stored));
      } catch (e) {
        log('[ui] load sections error', e);
      }
    })();
  }, [projectId]);

  const toggleSection = useCallback(async (name: string) => {
    animateSection(200);
    const next = openSections.includes(name)
      ? openSections.filter(s => s !== name)
      : [...openSections, name];
    setOpenSections(next);
    try {
      await AsyncStorage.setItem(`sections:${projectId}`, JSON.stringify(next));
      log('[ui] toggle', { name, open: next.includes(name) });
    } catch (e) {
      log('[ui] save sections error', e);
    }
  }, [openSections, projectId]);

  const copyList = useCallback(async (name: string, arr: any[], formatter?: (item: any) => string) => {
    if (!arr?.length) return;
    const defaultFormat = (i: any) => i.name || i.item || i.text || String(i);
    const format = formatter || defaultFormat;
    const txt = arr.map(format).filter(Boolean).join('\n');
    await Clipboard.setStringAsync(txt);
    simpleToast(`Copied ${arr.length} items`);
    log('[ui] copy', { name, count: arr.length });
  }, []);

  // Poll for measurement once on mount
  useEffect(() => {
    let mounted = true;
    (async () => {
      if (!project?.id || !scanId) return;
      try {
        const m = await getMeasurement(project.id, scanId);
        if (mounted) setMeasure(m);
      } catch {}
    })();
    return () => { mounted = false; };
  }, [project?.id, scanId]);

  // Normalize plan from plan_json with safe defaults
  const plan = project?.plan_json ?? {};
  const overview = plan?.overview ?? {};
  const materials = Array.isArray(plan?.materials) ? plan.materials : [];
  const tools = Array.isArray(plan?.tools) ? plan.tools : [];
  const cuts = Array.isArray(plan?.cuts) ? plan.cuts : [];
  const steps = Array.isArray(plan?.steps) ? plan.steps : [];
  const finishing = Array.isArray(plan?.finishing) ? plan.finishing : [];
  const counts = { materials: materials.length, tools: tools.length, cuts: cuts.length, steps: steps.length };
  
  log('[details] plan counts', counts);

  // Derive AR scale/dimensions with safe defaults
  const pxPerIn = typeof project?.scale_px_per_in === 'number' ? project.scale_px_per_in : null;
  const dims = project?.dimensions_json || {};
  const widthIn  = typeof dims?.width_in === 'number'  ? dims.width_in  : null;
  const heightIn = typeof dims?.height_in === 'number' ? dims.height_in : null;
  const depthIn  = typeof dims?.depth_in === 'number'  ? dims.depth_in  : null;
  const diagIn   = typeof dims?.diagonal_in === 'number' ? dims.diagonal_in : null;
  log('[details] ar', { pxPerIn, widthIn, heightIn, depthIn, diagIn });

  const load = useCallback(async () => {
    if (!projectId) return;

    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setLoading(true);
    try {
      const [p, s, prog] = await Promise.all([
        fetchProjectById(projectId, { signal: controller.signal, timeoutMs: 8000 }),
        fetchLatestScanForProject(projectId),
        fetchProjectProgress(projectId).catch(() => ({ completed_steps: [], current_step_index: 0 })),
      ]);
      
      if (!controller.signal.aborted) {
        setProject(p);
        setScan(s);
        setCompletedSteps(prog.completed_steps || []);
        setCurrentStepIndex(prog.current_step_index || 0);
        
        log('[details] loaded', {
          id: p?.id,
          status: p?.status,
          has_plan_json: !!p?.plan_json
        });
      }
    } catch (e: any) {
      if (e?.name !== 'AbortError') {
        log('[ProjectDetails load error]', String(e));
      }
    } finally {
      if (!controller.signal.aborted) {
        setLoading(false);
      }
    }
  }, [projectId]);

  // Hero logic: preview → scan → placeholder
  const previewUrl = project?.preview_url ?? project?.plan?.preview_url ?? null;
  const scanUrl = scan?.imageUrl || null;
  const measureResult = scan?.measureResult || null;
  const roi = scan?.roi || null;
  const previewStatus = project?.preview_status;

  // --- Before/After image URIs ---
  const beforeUri = project?.before || project?.plan_json?.preview?.before || project?.input_image_url || scan?.imageUrl;
  const afterUri = project?.preview_url || project?.plan_json?.preview?.after || project?.plan?.preview_image_url;
  const activeUri = previewTab === 'before' ? beforeUri : afterUri;

  // --- hero image resolver (use activeUri based on toggle) ---
  const heroUri = activeUri || null;
  const heroType = project?.preview_url ? 'preview' : project?.input_image_url ? 'input' : scan?.imageUrl ? 'scan' : null;

  // Log candidates once per change
  useEffect(() => {
    log('[hero:candidates]', {
      preview: project?.preview_url,
      input: project?.input_image_url,
      scan: scan?.imageUrl,
    });
  }, [project?.preview_url, project?.input_image_url, scan?.imageUrl]);

  // Fallback if preview fails to load
  const [heroError, setHeroError] = useState(false);
  const primary = heroUri;
  const fallback = project?.input_image_url || scan?.imageUrl || null;
  const pick = (!heroError && primary) ? primary : fallback;
  // Add cache-buster so <Image> refetches when URL toggles
  const resolvedHero = pick ? `${pick}${pick.includes('?') ? '&' : '?'}v=${Date.now()}` : null;
  
  log('[details] hero =', heroType ?? 'none');

  const handleSaveHeroToPhotos = async () => {
    // Always save the After image only
    const uri = afterUri;
    if (!uri) { Alert.alert('Nothing to save', 'No after image available.'); return; }
    try {
      // ask permission once
      const { status } = await MediaLibrary.requestPermissionsAsync();
      if (status !== 'granted') { Alert.alert('Permission needed', 'Enable Photos access to save.'); return; }

      // download to app cache first (RN Image cannot save remote URLs directly)
      const fileName = `diygenie_${project?.id || 'preview'}.jpg`;
      const tmpPath = ((FileSystem as any).cacheDirectory || (FileSystem as any).documentDirectory) + fileName;
      const dl = await FileSystem.downloadAsync(uri, tmpPath);
      if (dl.status !== 200) throw new Error(`Download failed (${dl.status})`);

      // create asset in Photos
      await MediaLibrary.saveToLibraryAsync(dl.uri);
      Alert.alert('Saved', 'Image saved to Photos.');
    } catch (e: any) {
      console.error('[save:hero]', e);
      Alert.alert('Save failed', String(e?.message || e));
    }
  };

  const onHeroLayout = useCallback((e: any) => {
    const w = e?.nativeEvent?.layout?.width ?? 0;
    if (w && w !== heroW) setHeroW(w);
  }, [heroW]);

  const handleGeneratePreview = async () => {
    try {
      if (!project || !project.photo_url || !project.prompt) {
        Alert.alert('Missing data', 'This project needs a photo_url and prompt before generating a preview.');
        return;
      }
      setStubPreviewLoading(true);
      setStubPreviewUrl(null);
      const res = await fetch(`${API_BASE_URL}/preview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          photo_url: project.photo_url,
          prompt: project.prompt,
          measurements: project.measurements_json || null
        })
      });
      const data = await res.json();
      if (!res.ok || !data?.ok) {
        throw new Error(data?.error || `HTTP ${res.status}`);
      }
      setStubPreviewUrl(data.preview_url);
    } catch (err) {
      Alert.alert('Preview failed', String(err?.message || err));
    } finally {
      setStubPreviewLoading(false);
    }
  };

  const handleGeneratePlan = async () => {
    try {
      if (!project || !project.photo_url || !project.prompt) {
        Alert.alert('Missing data', 'Project needs a photo_url and prompt before generating a plan.');
        return;
      }
      setPlanLoading(true);
      setPlanJson(null);
      const res = await fetch(`${API_BASE_URL}/plan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          photo_url: project.photo_url,
          prompt: project.prompt,
          measurements: project.measurements_json || null
        })
      });
      const data = await res.json();
      if (!res.ok || !data?.ok || !data?.plan) {
        throw new Error(data?.error || `HTTP ${res.status}`);
      }
      setPlanJson(data.plan);
    } catch (err) {
      Alert.alert('Plan failed', String(err?.message || err));
    } finally {
      setPlanLoading(false);
    }
  };

  const handleDeleteProject = async () => {
    if (!projectId) return;

    Alert.alert(
      'Delete Project?',
      'This action is permanent and cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              setDeleting(true);
              const res = await deleteProjectDeep(projectId);
              
              if (!res.ok) {
                setToast({
                  visible: true,
                  message: res.message || 'Could not delete project. Please try again.',
                  type: 'error',
                });
                return;
              }

              setToast({
                visible: true,
                message: 'Project deleted',
                type: 'success',
              });

              // Track deletion
              track({ userId, event: 'delete_project', projectId });

              // Navigate back and emit refresh event
              navigation.goBack();
              DeviceEventEmitter.emit('projects:refresh');
            } catch (err) {
              setToast({
                visible: true,
                message: 'Could not delete project. Please try again.',
                type: 'error',
              });
            } finally {
              setDeleting(false);
            }
          },
        },
      ]
    );
  };

  const generatePlanIfNeeded = async (p: any) => {
    if (!p) return;
    if (planLoading) return;
    if (!p.preview_url) return;           // need preview first
    if (p.plan_json) return;              // already has plan

    const photo_url = p.input_image_url;
    const measurements = p.dimensions_json || null;
    const prompt = p.goal || p.name || 'DIY plan';
    if (!photo_url || !prompt) return;

    try {
      setPlanLoading(true);
      log('[plan] generating', { id: p.id });
      const res = await fetch(`${API_BASE_URL}/plan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ photo_url, prompt, measurements })
      });
      const data = await res.json();
      if (!res.ok || !data?.ok || !data?.plan) {
        throw new Error(data?.error || `HTTP ${res.status}`);
      }
      const { error: upErr } = await supabase
        .from('projects')
        .update({
          plan_json: data.plan,
          status: 'planned',
          updated_at: new Date().toISOString()
        })
        .eq('id', p.id);
      if (upErr) throw upErr;
      // reflect locally
      setProject((prev: any) => ({ ...(prev || p), plan_json: data.plan, status: 'planned' }));
      log('[plan] saved', { id: p.id });
    } catch (e: any) {
      console.error('[plan] generate fail', e);
      Alert.alert('Plan failed', String(e?.message || e));
    } finally {
      setPlanLoading(false);
    }
  };

  const planReady = /ready|active/i.test(project?.status ?? '');

  useLayoutEffect(() => {
    navigation.setOptions({
      title: '',
      headerBackVisible: true,
      headerRight: () => (
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, marginRight: 8 }}>
          {project?.name && (
            <View style={{ maxWidth: 180 }}>
              <Text style={{ fontSize: 17, fontWeight: '600', color: '#111827' }} numberOfLines={1}>
                {project.name}
              </Text>
            </View>
          )}
          {planReady && (
            <View style={{ paddingLeft: 4 }}>
              <StatusBadge status="ready" />
            </View>
          )}
        </View>
      ),
    });
  }, [navigation, safeBack, project?.name, planReady]);

  useEffect(() => {
    load();
    return () => {
      abortRef.current?.abort();
    };
  }, [load]);

  useEffect(() => {
    if (project) generatePlanIfNeeded(project);
  }, [project]);

  useFocusEffect(
    useCallback(() => {
      load();
      
      // Clear justBuilt param after first use
      if (justBuilt) {
        navigation.setParams({ justBuilt: undefined } as any);
      }
      
      return () => {
        abortRef.current?.abort();
      };
    }, [load, justBuilt, navigation])
  );

  // Refetch if plan is empty after active status (handles webhook race)
  useEffect(() => {
    if (planReady && counts.materials + counts.tools + counts.cuts + counts.steps === 0) {
      log('[details] empty plan after active → refetch in 2s');
      const t = setTimeout(() => load(), 2000);
      return () => clearTimeout(t);
    }
  }, [planReady, project?.updated_at, counts, load]);

  // Poll for preview status when queued or processing
  useEffect(() => {
    if (!projectId || !project) return;
    
    const previewStatus = project.preview_status?.toLowerCase();
    const shouldPoll = previewStatus === 'queued' || previewStatus === 'processing';
    
    if (!shouldPoll) return;
    
    const abortController = new AbortController();
    let polling = true;
    
    const pollStatus = async () => {
      try {
        const u = await supabase.auth.getSession();
        const user_id = u?.data?.session?.user?.id;
        
        while (polling && !abortController.signal.aborted) {
          log('[preview] polling…');
          
          const r = await fetch(`https://api.diygenieapp.com/api/projects/${projectId}/preview/status?user_id=${user_id}`, {
            signal: abortController.signal
          });
          
          if (r.status === 200) {
            const result = await r.json();
            if (result.status === 'done' && result.url) {
              log('[preview] ready', { url: result.url });
              setProject((prev: any) => ({
                ...prev,
                preview_status: 'done',
                preview_url: result.url
              }));
              polling = false;
              log('[preview] stop');
              break;
            }
          }
          
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      } catch (err) {
        if ((err as any)?.name !== 'AbortError') {
          log('[preview] poll error', err);
        }
      }
    };
    
    pollStatus();
    
    return () => {
      polling = false;
      abortController.abort();
      log('[preview] stop');
    };
  }, [projectId, project?.preview_status]);

  const isBuilding = planLoading || (!project?.plan_json && !!project?.preview_url);

  // Log plan state
  const hasPlanContent = counts.materials + counts.tools + counts.cuts + counts.steps > 0;
  const planState = isBuilding ? 'building' : planReady && hasPlanContent ? 'ready' : planReady ? 'active_empty' : 'none';
  log('[details] plan state =', planState);

  const copyText = async (txt: string) => {
    if (!txt) return;
    await Clipboard.setStringAsync(txt);
    log('[copy] ok');
  };

  const toggleStepComplete = async (stepIndex: number) => {
    if (!projectId) return;
    
    const isCompleted = completedSteps.includes(stepIndex);
    let newCompleted: number[];
    
    if (isCompleted) {
      newCompleted = completedSteps.filter(i => i !== stepIndex);
    } else {
      newCompleted = [...completedSteps, stepIndex].sort((a, b) => a - b);
    }
    
    setCompletedSteps(newCompleted);
    setCurrentStepIndex(stepIndex);
    
    try {
      await updateProjectProgress(projectId, {
        completed_steps: newCompleted,
        current_step_index: stepIndex
      });
      log('[progress] step', stepIndex, isCompleted ? 'unchecked' : 'checked');
    } catch (e) {
      console.error('[progress] update failed', e);
      setCompletedSteps(completedSteps);
    }
  };

  const fmtQty = (q?: number | string, u?: string) => {
    if (q == null || q === '') return '';
    return u ? `${q} ${u}` : String(q);
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#F5F3FF' }}>
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, paddingBottom: 100 }}>
      {loading ? (
        <View style={{ paddingTop: 40 }}>
          <ActivityIndicator />
        </View>
      ) : (
        <>
          {/* Single Hero Image - Priority: preview → input → scan → nothing */}
          {resolvedHero ? (
            <View style={{ marginBottom: 20 }}>
              {/* Before/After Toggle */}
              {(beforeUri || afterUri) && (
                <View style={{ flexDirection: 'row', backgroundColor: '#F1EEFF', borderRadius: 10, padding: 4, marginBottom: 8 }}>
                  {(['before', 'after'] as const).map(tab => (
                    <Pressable 
                      key={tab} 
                      onPress={() => setPreviewTab(tab)} 
                      style={{ 
                        flex: 1, 
                        paddingVertical: 8, 
                        borderRadius: 8, 
                        backgroundColor: previewTab === tab ? 'white' : 'transparent' 
                      }}
                    >
                      <Text style={{ 
                        textAlign: 'center', 
                        fontWeight: previewTab === tab ? '700' : '500', 
                        color: '#3A2EB0' 
                      }}>
                        {tab === 'before' ? 'Before' : 'After'}
                      </Text>
                    </Pressable>
                  ))}
                </View>
              )}
              
              <View 
                onLayout={onHeroLayout}
                style={{ 
                  position: 'relative', 
                  aspectRatio: 16/9, 
                  borderRadius: 16, 
                  overflow: 'hidden', 
                  backgroundColor: '#EEE',
                  shadowColor: '#000', 
                  shadowOpacity: 0.1, 
                  shadowRadius: 8, 
                  shadowOffset: { width: 0, height: 2 }, 
                  elevation: 3 
                }}>
                <Image
                  key={resolvedHero}
                  source={{ uri: resolvedHero }}
                  style={{ width: '100%', height: '100%', minHeight: 220 }}
                  resizeMode="cover"
                  onError={(e) => {
                    warn('[hero:error]', { url: resolvedHero, err: e?.nativeEvent?.error });
                    setHeroError(true);
                  }}
                />
              
              {/* Measurement badge (only for scan with measureResult) */}
              {heroType === 'scan' && measureResult && (
                <View style={{ 
                  position: 'absolute', 
                  bottom: 12, 
                  left: 12, 
                  backgroundColor: 'rgba(124,58,237,0.9)', 
                  paddingHorizontal: 10, 
                  paddingVertical: 6, 
                  borderRadius: 8 
                }}>
                  <Text style={{ color: 'white', fontSize: 12, fontWeight: '600' }}>
                    {measureResult.width_in}" × {measureResult.height_in}"
                  </Text>
                </View>
              )}
              
              {/* Save to Photos icon button (only shown when image exists) */}
              {resolvedHero && (
                <TouchableOpacity 
                  onPress={handleSaveHeroToPhotos}
                  accessibilityLabel="Save to Photos"
                  style={{ 
                    position: 'absolute', 
                    top: 12, 
                    right: 12, 
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    backgroundColor: 'rgba(0,0,0,0.4)',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                >
                  <Ionicons name="download-outline" size={22} color="#fff" />
                </TouchableOpacity>
              )}
              
              {/* ROI overlay (when measurement data available) */}
              {measure?.roi && (() => {
                const labelTop = `${Math.max(0, (measure.roi.y * 100) - 6)}%` as any;
                return (
                  <View style={{ position:'absolute', left: 16, right: 16, top: 16, bottom: 16 }}>
                    <View
                      pointerEvents="none"
                      style={{
                        position:'absolute',
                        left: `${measure.roi.x * 100}%`,
                        top: `${measure.roi.y * 100}%`,
                        width: `${measure.roi.w * 100}%`,
                        height: `${measure.roi.h * 100}%`,
                        borderWidth: 2,
                        borderColor: 'rgba(255,255,255,0.9)',
                        backgroundColor: 'rgba(255,255,255,0.12)',
                        borderRadius: 8,
                      }}
                    />
                    <View style={{
                      position:'absolute',
                      left: `${measure.roi.x * 100}%`,
                      top: labelTop,
                      paddingHorizontal:8, paddingVertical:4, borderRadius:6,
                      backgroundColor:'rgba(0,0,0,0.55)'
                    }}>
                      <Text style={{color:'#fff', fontSize:12, fontWeight:'600'}}>
                        {Math.round(measure.width_in)}″ × {Math.round(measure.height_in)}″
                      </Text>
                    </View>
                  </View>
                );
              })()}
              
              {/* Ruler overlay disabled for MVP */}
              {ENABLE_RULER_OVERLAY && (showRuler && pxPerIn && heroW > 0) && (
                <RulerOverlay widthPx={heroW} pxPerIn={pxPerIn} />
              )}
              </View>
              
              {/* Caption */}
              <Text style={{ color: '#666', fontSize: 12, marginTop: 6 }}>
                Before and after preview of your space.
              </Text>
              
              {/* AR measurements badge row & mode display */}
              <View style={{ paddingVertical: 8 }}>
                {(pxPerIn || widthIn || heightIn || depthIn || diagIn) && (
                  <View style={{ flexDirection: 'row', gap: 12, marginBottom: 6 }}>
                    {pxPerIn != null && <Text style={{ fontSize: 12, opacity: 0.8 }}>Scale: {pxPerIn.toFixed(2)} px/in</Text>}
                    {widthIn  != null && <Text style={{ fontSize: 12, opacity: 0.8 }}>W: {widthIn.toFixed(1)}"</Text>}
                    {heightIn != null && <Text style={{ fontSize: 12, opacity: 0.8 }}>H: {heightIn.toFixed(1)}"</Text>}
                    {depthIn  != null && <Text style={{ fontSize: 12, opacity: 0.8 }}>D: {depthIn.toFixed(1)}"</Text>}
                    {diagIn   != null && <Text style={{ fontSize: 12, opacity: 0.8 }}>Diag: {diagIn.toFixed(1)}"</Text>}
                  </View>
                )}
                {project?.preview_meta?.mode && (
                  <Text style={{ fontSize: 12, opacity: 0.6 }}>
                    Mode: {project.preview_meta.mode}
                  </Text>
                )}
              </View>
              
              {/* Ruler toggle (only shown when pxPerIn exists) */}
              {pxPerIn ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 6, marginBottom: 8 }}>
                  <Switch 
                    value={showRuler} 
                    onValueChange={(val) => {
                      setShowRuler(val);
                      log('[ruler] toggle', { on: val, pxPerIn, heroW });
                    }} 
                  />
                  <Text style={{ fontSize: 14, opacity: 0.85 }}>Show ruler</Text>
                  <Text style={{ marginLeft: 8, fontSize: 12, opacity: 0.6 }}>Scale: {pxPerIn.toFixed(2)} px/in</Text>
                </View>
              ) : null}
            </View>
          ) : (previewStatus === 'queued' || previewStatus === 'processing') ? (
            <View style={{ marginBottom: 20 }}>
              <View style={{ 
                position: 'relative', 
                aspectRatio: 16/9, 
                borderRadius: 16, 
                overflow: 'hidden', 
                backgroundColor: '#F3F0FF',
                shadowColor: '#000', 
                shadowOpacity: 0.1, 
                shadowRadius: 8, 
                shadowOffset: { width: 0, height: 2 }, 
                elevation: 3,
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <ActivityIndicator size="large" color="#7C3AED" />
                <Text style={{ marginTop: 12, color: '#7C3AED', fontSize: 14, fontWeight: '600' }}>
                  Generating visual preview...
                </Text>
              </View>
            </View>
          ) : null}

          {/* Top CTA */}
          {hasPlanContent && (
            <TouchableOpacity
              activeOpacity={0.9}
              onPress={() => {
                log('[details] nav to full');
                track({ userId, event: 'open_plan', projectId });
                (navigation as any).navigate('DetailedInstructions', { id: projectId });
              }}
              style={{
                borderRadius: 16, overflow: 'hidden', marginBottom: 16,
                shadowColor: '#000', shadowOpacity: 0.12, shadowRadius: 12, shadowOffset: { width: 0, height: 6 }, elevation: 6
              }}
            >
              <LinearGradient colors={['#7C3AED','#6D28D9']} start={{x:0,y:0}} end={{x:1,y:1}} style={{ padding: 18 }}>
                <Text style={{ color: 'white', fontSize: 20, fontWeight: '800', marginBottom: 4 }}>
                  Open Detailed Build Plan
                </Text>
                <Text style={{ color: 'white', opacity: 0.85 }}>
                  Document-style guide with every step and detail
                </Text>
              </LinearGradient>
            </TouchableOpacity>
          )}

          {/* Building status banner */}
          {isBuilding && (
            <View style={{ marginBottom: 20, backgroundColor: '#F3E8FF', borderRadius: 16, padding: 18, alignItems: 'center' }}>
              <ActivityIndicator color="#6D28D9" />
              <Text style={{ color: '#6D28D9', fontSize: 15, marginTop: 8 }}>
                Plan is building…
              </Text>
            </View>
          )}

          {/* Plan loading skeleton */}
          {planReady && !hasPlanContent && (
            <View style={{ marginBottom: 20, backgroundColor: '#F3E8FF', borderRadius: 16, padding: 18, alignItems: 'center' }}>
              <ActivityIndicator color="#6D28D9" />
              <Text style={{ color: '#6D28D9', fontSize: 15, marginTop: 8 }}>
                Loading plan…
              </Text>
            </View>
          )}

          {/* Section Cards */}
          {hasPlanContent && (
            <>
              {/* 1. Overview */}
              <SectionCard
                icon={<Ionicons name="information-circle-outline" size={16} color={brand.primary} />}
                title="Overview"
                summary="Project summary"
                isOpen={openSections.includes('overview')}
                onToggle={() => toggleSection('overview')}
              >
                <Text style={{ fontSize: 15, color: '#374151', lineHeight: 22, marginBottom: 12 }}>
                  {overview?.text || overview || 'No overview yet.'}
                </Text>
                
                {/* Time & Cost & Skill */}
                <View style={{ flexDirection: 'row', gap: 8, flexWrap: 'wrap', marginTop: 8 }}>
                  {plan.skill_level && (
                    <View style={{ backgroundColor: '#EDE9FE', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 12, flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={{ fontSize: 16 }}>🎯</Text>
                      <Text style={{ fontSize: 14, fontWeight: '600', color: '#6D28D9', textTransform: 'capitalize' }}>{plan.skill_level}</Text>
                    </View>
                  )}
                  {plan.time_estimate_hours && (
                    <View style={{ backgroundColor: '#EDE9FE', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 12, flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={{ fontSize: 16 }}>⏱</Text>
                      <Text style={{ fontSize: 14, fontWeight: '600', color: '#6D28D9' }}>{plan.time_estimate_hours} hrs</Text>
                    </View>
                  )}
                  {plan.cost_estimate_usd && (
                    <View style={{ backgroundColor: '#EDE9FE', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 12, flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={{ fontSize: 16 }}>💵</Text>
                      <Text style={{ fontSize: 14, fontWeight: '600', color: '#6D28D9' }}>${plan.cost_estimate_usd}</Text>
                    </View>
                  )}
                </View>

                {/* Safety Warnings */}
                {plan.safety_warnings && plan.safety_warnings.length > 0 && (
                  <View style={{ backgroundColor: '#FEF3C7', paddingHorizontal: 12, paddingVertical: 10, borderRadius: 8, marginTop: 12 }}>
                    <Text style={{ fontSize: 13, fontWeight: '700', color: '#92400E', marginBottom: 6 }}>⚠️ Safety First</Text>
                    {plan.safety_warnings.map((warning, i) => (
                      <Text key={i} style={{ fontSize: 13, color: '#92400E', lineHeight: 18 }}>• {warning}</Text>
                    ))}
                  </View>
                )}
              </SectionCard>

              {/* Dimensions Card */}
              <DimensionsCard measure={measure} />

              {/* AR Measurements Card */}
              <View style={{ backgroundColor: 'white', borderRadius: 16, padding: 16, marginBottom: 12 }}>
                <Text style={{ fontSize: 16, fontWeight: '700', marginBottom: 6 }}>Measurements</Text>
                {pxPerIn == null && widthIn == null && heightIn == null && depthIn == null && diagIn == null ? (
                  <Text style={{ opacity: 0.6 }}>No measurements yet</Text>
                ) : (
                  <>
                    {pxPerIn != null && <Text>Scale: {pxPerIn.toFixed(3)} px/in</Text>}
                    {widthIn  != null && <Text>Width: {widthIn.toFixed(2)}"</Text>}
                    {heightIn != null && <Text>Height: {heightIn.toFixed(2)}"</Text>}
                    {depthIn  != null && <Text>Depth: {depthIn.toFixed(2)}"</Text>}
                    {diagIn   != null && <Text>Diagonal: {diagIn.toFixed(2)}"</Text>}
                  </>
                )}
              </View>

              {/* 2. Materials + Tools (combined shopping list) */}
              <SectionCard
                icon={<Ionicons name="cart-outline" size={16} color={brand.primary} />}
                title="Materials + Tools"
                countBadge={materials.length + tools.length}
                summary="Shopping list"
                isOpen={openSections.includes('materials')}
                onToggle={() => toggleSection('materials')}
              >
                {/* Materials section */}
                {materials.length > 0 && (
                  <View style={{ marginBottom: 16 }}>
                    <Text style={{ fontSize: 14, fontWeight: '700', color: '#6D28D9', marginBottom: 8 }}>Materials (Required)</Text>
                    {materials.map((m: any, i: number) => (
                      <View key={i} style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6, gap: 8 }}>
                        <View style={{ flexDirection: 'row', gap: 8, flex: 1 }}>
                          <Text style={{ color: '#6D28D9', fontSize: 18 }}>•</Text>
                          <Text style={{ fontSize: 15, color: '#374151', flex: 1 }}>
                            {m.name} {m.qty && <Text style={{ fontWeight: '600' }}>({m.qty}{m.unit ? ' ' + m.unit : ''})</Text>}
                          </Text>
                        </View>
                        {m.price && <Text style={{ fontSize: 15, fontWeight: '600', color: '#059669' }}>${m.price}</Text>}
                      </View>
                    ))}
                  </View>
                )}

                {/* Tools section */}
                {tools.length > 0 && (
                  <View>
                    <Text style={{ fontSize: 14, fontWeight: '700', color: '#6D28D9', marginBottom: 8 }}>Tools</Text>
                    {tools.map((tool: any, i: number) => {
                      const toolObj = typeof tool === 'string' ? { name: tool } : tool;
                      const needToBuy = toolObj.have === false;
                      return (
                        <View key={i} style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6, gap: 8 }}>
                          <View style={{ flexDirection: 'row', gap: 8, flex: 1 }}>
                            <Text style={{ color: '#6D28D9', fontSize: 18 }}>•</Text>
                            <Text style={{ fontSize: 15, color: '#374151', flex: 1 }}>{toolObj.name}</Text>
                          </View>
                          {needToBuy && toolObj.rentalPrice && (
                            <Text style={{ fontSize: 13, color: '#9CA3AF', fontStyle: 'italic' }}>
                              if needed ~${toolObj.rentalPrice}
                            </Text>
                          )}
                        </View>
                      );
                    })}
                  </View>
                )}
              </SectionCard>

              {/* 3. Cut List */}
              {cuts.length > 0 && (
                <SectionCard
                  icon={<MaterialCommunityIcons name="content-cut" size={16} color={brand.primary} />}
                  title="Cut List"
                  countBadge={cuts.length}
                  summary="Cutting guide"
                  isOpen={openSections.includes('cuts')}
                  onToggle={() => toggleSection('cuts')}
                >
                  <View>
                    {cuts.map((cut: any, i: number) => (
                      <View key={i} style={{ 
                        flexDirection: 'row', 
                        justifyContent: 'space-between', 
                        paddingVertical: 10, 
                        borderBottomWidth: i < cuts.length - 1 ? 1 : 0,
                        borderBottomColor: '#E5E7EB'
                      }}>
                        <Text style={{ fontSize: 15, color: '#374151', flex: 1 }}>{cut.part}</Text>
                        <Text style={{ fontSize: 15, color: '#6B7280', fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace' }}>
                          {cut.width && cut.height ? `${cut.width}" × ${cut.height}"` : cut.size} ×{cut.qty ?? 1}
                        </Text>
                      </View>
                    ))}
                  </View>
                </SectionCard>
              )}

              {/* 4. Build Steps (with checkboxes and progress) */}
              <SectionCard
                icon={<Ionicons name="checkmark-done-outline" size={16} color={brand.primary} />}
                title="Build Steps"
                countBadge={steps.length}
                summary={completedSteps.length > 0 ? `${Math.round((completedSteps.length / (steps.length || 1)) * 100)}% complete` : `${steps.length} steps`}
                isOpen={openSections.includes('steps')}
                onToggle={() => toggleSection('steps')}
              >
                {steps.length ? (
                  <>
                    {/* Progress bar */}
                    {completedSteps.length > 0 && (
                      <View style={{ marginBottom: 16 }}>
                        <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 }}>
                          <Text style={{ fontSize: 13, color: '#6B7280' }}>Progress</Text>
                          <Text style={{ fontSize: 13, fontWeight: '600', color: '#6D28D9' }}>
                            {completedSteps.length}/{steps.length} steps
                          </Text>
                        </View>
                        <View style={{ height: 8, backgroundColor: '#E5E7EB', borderRadius: 4, overflow: 'hidden' }}>
                          <View style={{ 
                            height: '100%', 
                            width: `${(completedSteps.length / steps.length) * 100}%`, 
                            backgroundColor: '#6D28D9' 
                          }} />
                        </View>
                      </View>
                    )}

                    <View style={{ marginBottom: 16 }}>
                      {steps.slice(0, 10).map((step: any, i: number) => {
                        const stepTitle = typeof step === 'string' ? step : (step.title || `Step ${i + 1}`);
                        const stepTime = typeof step === 'object' ? step.estimatedTime || step.time_minutes : null;
                        const isCompleted = completedSteps.includes(i);
                        
                        return (
                          <Pressable 
                            key={i} 
                            onPress={() => toggleStepComplete(i)}
                            style={{ marginBottom: 12 }}
                          >
                            <View style={{ flexDirection: 'row', gap: 10, alignItems: 'flex-start' }}>
                              {/* Checkbox */}
                              <View style={{ 
                                width: 24, 
                                height: 24, 
                                borderRadius: 6, 
                                borderWidth: 2, 
                                borderColor: isCompleted ? '#6D28D9' : '#D1D5DB',
                                backgroundColor: isCompleted ? '#6D28D9' : 'transparent',
                                alignItems: 'center',
                                justifyContent: 'center',
                                marginTop: 2
                              }}>
                                {isCompleted && <Ionicons name="checkmark" size={16} color="white" />}
                              </View>
                              
                              <View style={{ flex: 1 }}>
                                <Text style={{ 
                                  fontSize: 15, 
                                  color: isCompleted ? '#9CA3AF' : '#374151', 
                                  lineHeight: 22,
                                  textDecorationLine: isCompleted ? 'line-through' : 'none'
                                }}>
                                  {i + 1}. {stepTitle}
                                </Text>
                                {stepTime && (
                                  <Text style={{ fontSize: 13, color: '#9CA3AF', marginTop: 2 }}>
                                    ⏱ {typeof stepTime === 'number' ? `${stepTime} min` : stepTime}
                                  </Text>
                                )}
                              </View>
                            </View>
                          </Pressable>
                        );
                      })}
                    </View>
                    
                    <View style={{ flexDirection: 'row', gap: 10 }}>
                      <Pressable
                        onPress={() => (navigation as any).navigate('DetailedInstructions', { id: projectId })}
                        style={{ flex: 1, backgroundColor: '#6D28D9', paddingVertical: 10, borderRadius: 10, alignItems: 'center' }}
                      >
                        <Text style={{ color: 'white', fontWeight: '600', fontSize: 14 }}>
                          {completedSteps.length === 0 ? 'Start Building' : 'Continue Building'}
                        </Text>
                      </Pressable>
                      <Pressable
                        onPress={() => {
                          const text = steps.map((s: any, i: number) => 
                            `${completedSteps.includes(i) ? '✓' : '☐'} ${i + 1}. ${typeof s === 'string' ? s : s.title}`
                          ).join('\n');
                          copyText(text);
                        }}
                        style={{ flex: 1, backgroundColor: '#EDE9FE', paddingVertical: 10, borderRadius: 10, alignItems: 'center' }}
                      >
                        <Text style={{ color: '#6D28D9', fontWeight: '600', fontSize: 14 }}>Copy Steps</Text>
                      </Pressable>
                    </View>
                  </>
                ) : (
                  <Text style={{ color: '#9CA3AF', fontSize: 14 }}>No steps yet.</Text>
                )}
              </SectionCard>

              {/* 5. Finishing (only if applicable) */}
              {finishing.length > 0 && (
                <SectionCard
                  icon={<Ionicons name="sparkles-outline" size={16} color={brand.primary} />}
                  title="Finishing"
                  summary="Final touches"
                  isOpen={openSections.includes('finishing')}
                  onToggle={() => toggleSection('finishing')}
                >
                  <View>
                    {finishing.map((item: any, i: number) => (
                      <View key={i} style={{ marginBottom: 12 }}>
                        {item.title && (
                          <Text style={{ fontSize: 15, fontWeight: '600', color: '#374151', marginBottom: 4 }}>
                            {item.title}
                          </Text>
                        )}
                        {item.description && (
                          <Text style={{ fontSize: 14, color: '#6B7280', lineHeight: 20 }}>
                            {item.description}
                          </Text>
                        )}
                      </View>
                    ))}
                  </View>
                </SectionCard>
              )}
              
              {/* Share Plan Button */}
              <TouchableOpacity
                onPress={async () => {
                  try {
                    const text = formatPlanText(project, { overview, materials, tools, cuts, steps });
                    const res = await Share.share({ message: text, title: project?.name ?? 'DIY Plan' });
                    log('[ui] share', { action: res.action });
                  } catch (e) {
                    console.error('[ui] share error', e);
                    simpleToast('Could not open share sheet');
                  }
                }}
                style={{ 
                  backgroundColor: '#6D28D9', 
                  borderRadius: 16, 
                  padding: 16, 
                  alignItems: 'center', 
                  marginTop: 20,
                  shadowColor: '#000',
                  shadowOpacity: 0.15,
                  shadowRadius: 8,
                  shadowOffset: { width: 0, height: 4 },
                  elevation: 4
                }}
              >
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                  <Ionicons name="share-outline" size={20} color="white" />
                  <Text style={{ color: 'white', fontWeight: '600', fontSize: 16 }}>Share Plan</Text>
                </View>
              </TouchableOpacity>

              {/* Delete Project Button */}
              <View style={{ marginTop: 24, paddingTop: 24, borderTopWidth: 1, borderTopColor: '#E5E7EB' }}>
                <TouchableOpacity
                  onPress={handleDeleteProject}
                  disabled={deleting}
                  style={{ 
                    backgroundColor: deleting ? '#FCA5A5' : '#EF4444',
                    borderRadius: 12,
                    padding: 16,
                    alignItems: 'center',
                    opacity: deleting ? 0.6 : 1,
                  }}
                >
                  {deleting ? (
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                      <ActivityIndicator size="small" color="white" />
                      <Text style={{ color: 'white', fontWeight: '600', fontSize: 16 }}>Deleting...</Text>
                    </View>
                  ) : (
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                      <Ionicons name="trash-outline" size={20} color="white" />
                      <Text style={{ color: 'white', fontWeight: '600', fontSize: 16 }}>Delete Project</Text>
                    </View>
                  )}
                </TouchableOpacity>
                <Text style={{ fontSize: 12, color: '#9CA3AF', marginTop: 8, textAlign: 'center' }}>
                  This action is permanent
                </Text>
              </View>

              {/* --- Preview (Decor8 stub) --- */}
              {SHOW_DEBUG_ACTIONS && (
                <View style={{ marginTop: 16, padding: 12, borderRadius: 12, backgroundColor: '#f3f4f6' }}>
                  <Text style={{ fontWeight: '600', marginBottom: 8 }}>Design Preview</Text>
                  <Pressable
                    onPress={handleGeneratePreview}
                    disabled={stubPreviewLoading}
                    style={({ pressed }) => ({
                      opacity: stubPreviewLoading ? 0.6 : pressed ? 0.8 : 1,
                      alignSelf: 'flex-start',
                      paddingVertical: 10,
                      paddingHorizontal: 14,
                      borderRadius: 10,
                      backgroundColor: '#6D28D9',
                      marginBottom: 10
                    })}
                    testID="btn-generate-preview"
                  >
                    <Text style={{ color: 'white', fontWeight: '600' }}>
                      {stubPreviewLoading ? 'Generating…' : 'Generate Preview'}
                    </Text>
                  </Pressable>
                  {stubPreviewLoading && <ActivityIndicator size="small" />}
                  {stubPreviewUrl && (
                    <Image
                      source={{ uri: stubPreviewUrl }}
                      style={{ width: '100%', aspectRatio: 4 / 3, borderRadius: 10 }}
                      resizeMode="cover"
                      testID="img-preview"
                    />
                  )}
                </View>
              )}

              {/* --- Build Plan (OpenAI stub) --- */}
              {SHOW_DEBUG_ACTIONS && (
                <View style={{ marginTop: 16, padding: 12, borderRadius: 12, backgroundColor: '#eef2ff' }}>
                  <Text style={{ fontWeight: '600', marginBottom: 8 }}>Build Plan</Text>
                  <Pressable
                    onPress={handleGeneratePlan}
                    disabled={planLoading}
                    style={({ pressed }) => ({
                      opacity: planLoading ? 0.6 : pressed ? 0.8 : 1,
                      alignSelf: 'flex-start',
                      paddingVertical: 10,
                      paddingHorizontal: 14,
                      borderRadius: 10,
                      backgroundColor: '#6D28D9',
                      marginBottom: 10
                    })}
                    testID="btn-generate-plan"
                  >
                    <Text style={{ color: 'white', fontWeight: '600' }}>
                      {planLoading ? 'Generating…' : 'Generate Plan'}
                    </Text>
                  </Pressable>
                  {planLoading && <ActivityIndicator size="small" />}
                  {planJson && (
                    <View testID="plan-summary" style={{ gap: 6 }}>
                      <Text style={{ fontWeight: '600' }}>{planJson.overview}</Text>
                      <Text>Materials: {Array.isArray(planJson.materials) ? planJson.materials.length : 0}</Text>
                      <Text>Tools: {Array.isArray(planJson.tools) ? planJson.tools.length : 0}</Text>
                      <Text>Steps: {Array.isArray(planJson.steps) ? planJson.steps.length : 0}</Text>
                      {planJson.estimation && (
                        <Text>
                          Est: ${(planJson.estimation.grand_total ?? 0).toFixed ? planJson.estimation.grand_total.toFixed(2) : planJson.estimation.grand_total}
                        </Text>
                      )}
                    </View>
                  )}
                </View>
              )}
            </>
          )}
        </>
      )}
      <Toast
        visible={toast.visible}
        message={toast.message}
        type={toast.type}
        onHide={() => setToast({ ...toast, visible: false })}
      />
    </ScrollView>
    </View>
  );
}
