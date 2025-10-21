import React, { useRef } from 'react';
import { View, Text, ScrollView, Pressable, Alert, Image, ActivityIndicator } from 'react-native';
import { RouteProp, useRoute } from '@react-navigation/native';
import { captureRef } from 'react-native-view-shot';
import * as MediaLibrary from 'expo-media-library';
import { fetchProjectById, fetchProjectPlan, fetchProjectPlanMarkdown } from '../lib/api';
import { parsePlanMarkdown } from '../lib/plan';
import { Ionicons, MaterialCommunityIcons, Feather } from '@expo/vector-icons';
import { PlanResponse } from '../types/plan';
import { log } from '../lib/logger';

type R = RouteProp<Record<'DetailedInstructions', { id: string; section?: string }>, 'DetailedInstructions'>;

// -- Safe text helpers (local to this screen) --
const notNil = (v: any) => v !== null && v !== undefined;

const joinText = (...parts: (string | null | undefined)[]) =>
  parts.filter(p => typeof p === 'string' && p.length > 0).join(' ');

const fmtMoney = (n: number | null | undefined) =>
  notNil(n) ? `$${Number(n).toFixed(2).replace(/\.00$/, '')}` : null;

const fmtQtyUnit = (qty: number | string | null | undefined, unit?: string | null) => {
  const q = notNil(qty) ? String(qty) : null;
  const u = unit ? String(unit) : null;
  return joinText(q, u);
};

const fmtDim = (w?: number | null, h?: number | null) =>
  notNil(w) && notNil(h) ? `${w}" x ${h}"` : null;

const TextIf: React.FC<{ style?: any; children?: string | null }> = ({ style, children }) => {
  if (!children) return null;
  return <Text style={style}>{children}</Text>;
};

function RowText({ children, style }: { children: React.ReactNode; style?: any }) {
  return <Text style={[{ fontSize: 14, color: '#374151' }, style]}>{children}</Text>;
}

export default function DetailedInstructions() {
  const { params } = useRoute<R>();
  const [project, setProject] = React.useState<any>(null);
  const [planData, setPlanData] = React.useState<PlanResponse | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [saving, setSaving] = React.useState(false);
  const scrollViewRef = useRef<ScrollView>(null);

  const refs = {
    overview: useRef<View>(null),
    materials: useRef<View>(null),
    cuts: useRef<View>(null),
    tools: useRef<View>(null),
    steps: useRef<View>(null),
  };

  React.useEffect(() => {
    (async () => {
      try {
        setLoading(true);
        setError(null);
        
        // Fetch project data
        const p = await fetchProjectById(params.id);
        setProject(p);
        
        // Try to fetch plan from API
        const apiPlan = await fetchProjectPlan(params.id);
        
        if (apiPlan.ok) {
          log('[detailed instructions] API plan loaded');
          setPlanData(apiPlan);
        } else {
          log('[detailed instructions] API plan failed, trying fallback', apiPlan.error);
          
          // Fallback to markdown plan if API fails
          if (!p?.plan) {
            try {
              const md = await fetchProjectPlanMarkdown(params.id);
              if (md) {
                setProject((prev: any) => ({ ...(prev || {}), plan: parsePlanMarkdown(md) }));
              }
            } catch (e) {
              log('[detailed instructions] fallback error', e);
              setError(apiPlan.error || 'Failed to load plan');
            }
          }
        }
      } catch (e) {
        console.error('[detailed instructions] error', e);
        setError(e instanceof Error ? e.message : 'Failed to load plan');
      } finally {
        setLoading(false);
      }
    })();
  }, [params.id]);

  React.useEffect(() => {
    const section = params.section;
    if (section && refs[section as keyof typeof refs]?.current && scrollViewRef.current) {
      setTimeout(() => {
        refs[section as keyof typeof refs]?.current?.measureLayout(
          scrollViewRef.current as any,
          (_x: number, y: number) => {
            scrollViewRef.current?.scrollTo({ y: y - 20, animated: true });
          },
          () => {}
        );
      }, 300);
    }
  }, [params.section, planData, project]);

  const plan = project?.plan ?? {};

  // Derive a clean, human title (strip any trailing datetime)
  const rawTitle =
    planData?.summary?.title ||
    plan?.title ||
    project?.name ||
    'Project Plan';

  const cleanTitle = rawTitle.replace(/\s*\d{4}-\d{2}-\d{2}.*$/, '');

  async function saveSection(ref: React.RefObject<View>, name: string) {
    try {
      const uri = await captureRef(ref, { format: 'png', quality: 1 });
      await MediaLibrary.saveToLibraryAsync(uri);
    } catch (e) {
      console.error(`Failed to save ${name}:`, e);
      throw e;
    }
  }

  async function saveAll() {
    try {
      const { status } = await MediaLibrary.requestPermissionsAsync();
      if (status !== 'granted') { 
        Alert.alert('Permission needed', 'Please allow Photo access.'); 
        return; 
      }
      setSaving(true);
      
      const sectionsToSave: [React.RefObject<View>, string][] = [
        [refs.overview, 'Overview'],
        [refs.materials, 'Materials'],
        [refs.tools, 'Tools'],
      ];
      
      if ((planData?.cutList?.items && planData.cutList.items.length > 0) || (plan.cuts && plan.cuts.length > 0)) {
        sectionsToSave.push([refs.cuts, 'Cut List']);
      }
      
      sectionsToSave.push([refs.steps, 'Build Steps']);
      
      for (const [ref, name] of sectionsToSave) {
        await saveSection(ref, name);
      }
      
      Alert.alert('Saved', 'All sections saved to Photos.');
    } catch (e) {
      Alert.alert('Save failed', 'Please try again.');
    } finally {
      setSaving(false);
    }
  }

  const totalSteps = planData?.steps?.length || plan.steps?.length || 0;

  if (loading) {
    return (
      <View style={{ flex: 1, backgroundColor: '#FAFAFA', alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator size="large" color="#7C3AED" />
        <Text style={{ marginTop: 16, fontSize: 16, color: '#6B7280' }}>Loading plan...</Text>
      </View>
    );
  }

  if (error && !plan && !planData) {
    return (
      <View style={{ flex: 1, backgroundColor: '#FAFAFA', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <Ionicons name="alert-circle-outline" size={64} color="#EF4444" />
        <Text style={{ marginTop: 16, fontSize: 18, fontWeight: '600', color: '#111827', textAlign: 'center' }}>
          Failed to Load Plan
        </Text>
        <Text style={{ marginTop: 8, fontSize: 15, color: '#6B7280', textAlign: 'center' }}>
          {error}
        </Text>
      </View>
    );
  }

  return (
    <ScrollView ref={scrollViewRef} style={{ flex: 1, backgroundColor: '#FAFAFA' }} contentContainerStyle={{ paddingBottom: 100, paddingTop: 60 }}>
      {/* Purple Branded Header */}
      <View
        style={{
          backgroundColor: '#6D28D9',
          borderRadius: 12,
          marginHorizontal: 16,
          marginTop: 0,
          paddingVertical: 12,
          paddingHorizontal: 16,
        }}
      >
        <Text
          style={{
            fontSize: 20,
            fontWeight: '700',
            color: 'white',
          }}
        >
          {cleanTitle}
        </Text>

        <Text
          style={{
            fontSize: 13,
            color: 'rgba(255,255,255,0.8)',
            marginTop: 3,
          }}
        >
          Step-by-step builder&apos;s guide
        </Text>

        <View style={{ flexDirection: 'row', gap: 10, marginTop: 6 }}>
          {typeof (planData?.summary?.estTimeHours ?? plan?.time_estimate_hours) !==
            'undefined' && (
            <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.8)' }}>
              {(planData?.summary?.estTimeHours ?? plan?.time_estimate_hours) || 0} hrs
            </Text>
          )}
          {typeof planData?.summary?.estCostUsd !== 'undefined' && (
            <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.8)' }}>
              ${planData?.summary?.estCostUsd || 0}
            </Text>
          )}
          {totalSteps > 0 && (
            <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.8)' }}>
              {totalSteps} steps
            </Text>
          )}
        </View>
      </View>

      {/* Quota Blocking Banner */}
      {planData?.quota?.blocked && (
        <View style={{ 
          backgroundColor: '#FEF2F2', 
          marginHorizontal: 16, 
          marginTop: 16, 
          padding: 16, 
          borderRadius: 12, 
          borderLeftWidth: 4, 
          borderLeftColor: '#EF4444' 
        }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 8 }}>
            <Ionicons name="lock-closed" size={20} color="#DC2626" />
            <Text style={{ fontSize: 16, fontWeight: '700', color: '#991B1B', marginLeft: 8 }}>Plan Limit Reached</Text>
          </View>
          <Text style={{ fontSize: 14, color: '#7F1D1D', lineHeight: 20 }}>
            {planData.quota.message || 'You\'ve reached your plan generation limit. Upgrade to continue creating projects.'}
          </Text>
        </View>
      )}

      {/* Preview block removed - now shown in ProjectDetails screen */}
      {false && (
        <View style={{ backgroundColor: 'white', marginTop: 16, marginHorizontal: 16, borderRadius: 16, padding: 20 }}>
          <Text>Preview removed</Text>
        </View>
      )}

      {/* Before You Begin Section */}
      <View ref={refs.overview} style={{ backgroundColor: 'white', marginTop: 16, marginHorizontal: 16, borderRadius: 16, padding: 20 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 12 }}>
          <Ionicons name="information-circle" size={24} color="#7C3AED" />
          <Text style={{ fontSize: 18, fontWeight: '700', color: '#111827', marginLeft: 8 }}>Before You Begin</Text>
        </View>
        
        {plan.overview && (
          <Text style={{ fontSize: 15, color: '#374151', lineHeight: 22 }}>{plan.overview}</Text>
        )}
        {/* Removed "No overview available" placeholder text */}

        {/* Safety Warnings - Lighter */}
        {(planData?.safety?.notes && planData.safety.notes.length > 0) || (plan.safety_warnings && plan.safety_warnings.length > 0) ? (
          <View style={{ backgroundColor: '#FFF6F6', borderLeftWidth: 3, borderLeftColor: '#FF5C5C', padding: 10, borderRadius: 8, marginBottom: 8 }}>
            <Text style={{ color: '#CC0000', fontWeight: '700', fontSize: 13 }}>Safety First</Text>
            {(planData?.safety?.notes || plan.safety_warnings || []).map((warning: string, i: number) => (
              <Text key={i} style={{ color: '#444', fontSize: 12, marginTop: 4 }}>
                {warning}
              </Text>
            ))}
          </View>
        ) : null}

        {/* Permits - Lighter */}
        {planData?.permits && (planData.permits.needed || planData.permits.note) && (
          <View style={{ backgroundColor: '#FFFBEA', borderLeftWidth: 3, borderLeftColor: '#FBC02D', padding: 10, borderRadius: 8 }}>
            <Text style={{ color: '#A67C00', fontWeight: '700', fontSize: 13 }}>Permits Required</Text>
            <Text style={{ color: '#444', fontSize: 12, marginTop: 4 }}>
              {planData.permits.note || 'Check local building codes for structural modifications.'}
            </Text>
          </View>
        )}
      </View>

      {/* Materials Section - Receipt Style */}
      <View ref={refs.materials} style={{ backgroundColor: '#FFFFFF', borderRadius: 12, padding: 12, marginHorizontal: 12, marginTop: 12, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 }}>
        <Text style={{ fontSize: 18, fontWeight: '700', color: '#3A2EB0', marginBottom: 8 }}>Materials</Text>
        
        {planData?.materials && planData.materials.length > 0 ? (
          <>
            {planData.materials.map((m, i) => (
              <View key={i} style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 0.5, borderBottomColor: '#EEE' }}>
                <Text style={{ fontSize: 15, color: '#111827', flex: 1 }}>
                  {joinText(fmtQtyUnit(m.qty, m.unit), '·', m.name)}
                </Text>
                <TextIf style={{ fontSize: 15, fontWeight: '500', color: '#111827', marginLeft: 12 }}>
                  {fmtMoney(m.subtotalUsd)}
                </TextIf>
              </View>
            ))}
            
            {(() => {
              const subtotal = planData.materials.reduce((sum, m) => sum + (m.subtotalUsd || 0), 0);
              if (subtotal > 0) {
                return (
                  <View style={{ flexDirection: 'row', justifyContent: 'space-between', paddingTop: 8 }}>
                    <Text style={{ fontWeight: '700', color: '#111827' }}>Subtotal</Text>
                    <Text style={{ fontWeight: '700', color: '#0a8f5b' }}>{fmtMoney(subtotal)}</Text>
                  </View>
                );
              }
              return null;
            })()}
          </>
        ) : plan.materials && plan.materials.length > 0 ? (
          <>
            {plan.materials.map((m: any, i: number) => (
              <View key={i} style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 0.5, borderBottomColor: '#EEE' }}>
                <Text style={{ fontSize: 15, color: '#111827', flex: 1 }}>
                  {joinText(fmtQtyUnit(m.qty, m.unit), '·', m.name || 'Material')}
                </Text>
                <TextIf style={{ fontSize: 15, fontWeight: '500', color: '#111827', marginLeft: 12 }}>
                  {fmtMoney(m.price)}
                </TextIf>
              </View>
            ))}
          </>
        ) : (
          <Text style={{ fontSize: 15, color: '#777' }}>No materials yet.</Text>
        )}
      </View>

      {/* Tools Section - Polished */}
      <View ref={refs.tools} style={{ backgroundColor: 'white', marginTop: 16, marginHorizontal: 16, borderRadius: 16, padding: 20 }}>
        <Text style={{ fontSize: 18, fontWeight: '700', color: '#3A2EB0', marginBottom: 12 }}>Tools</Text>
        
        {planData?.tools ? (
          <>
            {/* Required Tools Card */}
            {planData.tools.required && planData.tools.required.length > 0 && (
              <View style={{ 
                backgroundColor: '#FFFFFF', 
                borderRadius: 12, 
                padding: 16, 
                marginBottom: 12, 
                shadowColor: '#000', 
                shadowOpacity: 0.08, 
                shadowRadius: 8, 
                shadowOffset: { width: 0, height: 2 },
                elevation: 3,
                borderWidth: 1,
                borderColor: '#F3F4F6'
              }}>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 12 }}>
                  <Ionicons name="hammer-outline" size={18} color="#6D28D9" style={{ marginRight: 8 }} />
                  <Text style={{ fontSize: 16, fontWeight: '600', color: '#1F2937', fontFamily: 'Manrope_600SemiBold' }}>
                    Required Tools
                  </Text>
                </View>
                {planData.tools.required.map((tool, i) => (
                  <View 
                    key={`req-${i}`} 
                    style={{ 
                      paddingVertical: 8,
                      borderBottomWidth: i < planData.tools.required.length - 1 ? 0.5 : 0,
                      borderBottomColor: '#E5E7EB'
                    }}
                  >
                    <Text style={{ fontSize: 14, color: '#374151', fontFamily: 'Inter_400Regular' }}>
                      • {tool}
                    </Text>
                  </View>
                ))}
              </View>
            )}
            
            {/* Optional Tools Card */}
            {planData.tools.optional && planData.tools.optional.length > 0 && (
              <View style={{ 
                backgroundColor: '#FFFFFF', 
                borderRadius: 12, 
                padding: 16, 
                marginBottom: 8, 
                shadowColor: '#000', 
                shadowOpacity: 0.08, 
                shadowRadius: 8, 
                shadowOffset: { width: 0, height: 2 },
                elevation: 3,
                borderWidth: 1,
                borderColor: '#F3F4F6'
              }}>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 12 }}>
                  <Ionicons name="build-outline" size={18} color="#6D28D9" style={{ marginRight: 8 }} />
                  <Text style={{ fontSize: 16, fontWeight: '600', color: '#1F2937', fontFamily: 'Manrope_600SemiBold' }}>
                    Optional Tools
                  </Text>
                </View>
                {planData.tools.optional.map((tool, i) => (
                  <View 
                    key={`opt-${i}`} 
                    style={{ 
                      paddingVertical: 8,
                      borderBottomWidth: i < planData.tools.optional.length - 1 ? 0.5 : 0,
                      borderBottomColor: '#E5E7EB'
                    }}
                  >
                    <Text style={{ fontSize: 14, color: '#374151', fontFamily: 'Inter_400Regular' }}>
                      • {tool}
                    </Text>
                  </View>
                ))}
              </View>
            )}
            
            {/* Empty state if no tools at all */}
            {(!planData.tools.required || planData.tools.required.length === 0) && 
             (!planData.tools.optional || planData.tools.optional.length === 0) && (
              <Text style={{ fontSize: 14, color: '#9CA3AF', fontStyle: 'italic', textAlign: 'center', paddingVertical: 12 }}>
                No tools listed for this project.
              </Text>
            )}
          </>
        ) : plan.tools && plan.tools.length > 0 ? (
          <View style={{ 
            backgroundColor: '#FFFFFF', 
            borderRadius: 12, 
            padding: 16, 
            shadowColor: '#000', 
            shadowOpacity: 0.08, 
            shadowRadius: 8, 
            shadowOffset: { width: 0, height: 2 },
            elevation: 3,
            borderWidth: 1,
            borderColor: '#F3F4F6'
          }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 12 }}>
              <Ionicons name="hammer-outline" size={18} color="#6D28D9" style={{ marginRight: 8 }} />
              <Text style={{ fontSize: 16, fontWeight: '600', color: '#1F2937', fontFamily: 'Manrope_600SemiBold' }}>
                Required Tools
              </Text>
            </View>
            {plan.tools.map((tool: any, i: number) => {
              const toolObj = typeof tool === 'string' ? { name: tool } : tool;
              return (
                <View 
                  key={i} 
                  style={{ 
                    flexDirection: 'row', 
                    justifyContent: 'space-between', 
                    paddingVertical: 8,
                    borderBottomWidth: i < plan.tools.length - 1 ? 0.5 : 0,
                    borderBottomColor: '#E5E7EB'
                  }}
                >
                  <Text style={{ fontSize: 14, color: '#374151', flex: 1, fontFamily: 'Inter_400Regular' }}>
                    • {toolObj.name}
                  </Text>
                  <TextIf style={{ fontSize: 13, color: '#9CA3AF', fontStyle: 'italic' }}>
                    {toolObj.rentalPrice ? `~${fmtMoney(toolObj.rentalPrice)}` : null}
                  </TextIf>
                </View>
              );
            })}
          </View>
        ) : (
          <Text style={{ fontSize: 14, color: '#9CA3AF', fontStyle: 'italic', textAlign: 'center', paddingVertical: 12 }}>
            No tools listed for this project.
          </Text>
        )}
      </View>

      {/* Cut List Section - 3-Column Table */}
      <View ref={refs.cuts} style={{ backgroundColor: '#FFFFFF', borderRadius: 12, padding: 12, marginHorizontal: 12, marginTop: 12, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 }}>
        <Text style={{ fontSize: 18, fontWeight: '700', color: '#3A2EB0', marginBottom: 8 }}>Cut List</Text>
        
        {planData?.cutList?.items && planData.cutList.items.length > 0 ? (
          <>
            {/* Column Headers */}
            <View style={{ flexDirection: 'row', paddingVertical: 6, marginBottom: 4 }}>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1 }}>Part</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1, textAlign: 'center' }}>Dimensions</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', width: 40, textAlign: 'right' }}>Qty</Text>
            </View>
            
            {planData.cutList.items.map((cut, i) => (
              <View key={i} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 8, backgroundColor: i % 2 === 0 ? 'transparent' : '#FAFAFF' }}>
                <Text style={{ fontSize: 15, color: '#111827', flex: 1 }}>{cut.board || 'Part'}</Text>
                <Text style={{ fontSize: 15, color: '#6B7280', flex: 1, textAlign: 'center' }}>{cut.dims || '—'}</Text>
                <Text style={{ fontSize: 15, color: '#111827', fontWeight: '600', width: 40, textAlign: 'right' }}>{cut.qty || '1'}</Text>
              </View>
            ))}
            
            {planData.cutList.layoutSvgUrl && (
              <Pressable 
                onPress={() => Alert.alert('Cut Layout', planData.cutList.layoutSvgUrl || 'Layout diagram available')}
                style={{ marginTop: 8, padding: 8, backgroundColor: '#F3F4F6', borderRadius: 6, alignItems: 'center' }}
              >
                <Text style={{ fontSize: 13, fontWeight: '600', color: '#7C3AED' }}>View layout</Text>
              </Pressable>
            )}
          </>
        ) : plan.cuts && plan.cuts.length > 0 ? (
          <>
            {/* Column Headers */}
            <View style={{ flexDirection: 'row', paddingVertical: 6, marginBottom: 4 }}>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1 }}>Part</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1, textAlign: 'center' }}>Dimensions</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', width: 40, textAlign: 'right' }}>Qty</Text>
            </View>
            
            {plan.cuts.map((cut: any, i: number) => {
              const dimOrSize = fmtDim(cut.width, cut.height) ?? (cut.size ?? '—');
              const qty = notNil(cut.qty) ? String(cut.qty) : '1';
              return (
                <View key={i} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 8, backgroundColor: i % 2 === 0 ? 'transparent' : '#FAFAFF' }}>
                  <Text style={{ fontSize: 15, color: '#111827', flex: 1 }}>{cut.part || 'Part'}</Text>
                  <Text style={{ fontSize: 15, color: '#6B7280', flex: 1, textAlign: 'center' }}>{dimOrSize}</Text>
                  <Text style={{ fontSize: 15, color: '#111827', fontWeight: '600', width: 40, textAlign: 'right' }}>{qty}</Text>
                </View>
              );
            })}
          </>
        ) : (
          <>
            {/* Column Headers */}
            <View style={{ flexDirection: 'row', paddingVertical: 6, marginBottom: 4 }}>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1 }}>Part</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', flex: 1, textAlign: 'center' }}>Dimensions</Text>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#666', width: 40, textAlign: 'right' }}>Qty</Text>
            </View>
            <Text style={{ fontSize: 15, color: '#777', marginTop: 4 }}>No cuts listed.</Text>
          </>
        )}
      </View>

      {/* Build Steps - Numbered Cards */}
      <View ref={refs.steps} style={{ marginTop: 12, marginHorizontal: 12 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <Text style={{ fontSize: 18, fontWeight: '700', color: '#3A2EB0' }}>Build Steps</Text>
          {totalSteps > 0 && (
            <Text style={{ fontSize: 13, color: '#666' }}>0/{totalSteps}</Text>
          )}
        </View>
        
        {planData?.steps && planData.steps.length > 0 ? (
          planData.steps.map((step, i) => (
            <View key={i} style={{ backgroundColor: '#FFFFFF', borderRadius: 12, padding: 12, marginVertical: 6, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 }}>
              <Text style={{ fontSize: 16, fontWeight: '700', color: '#111827' }}>
                {`${i + 1}. ${step.title || 'Step'}`}
              </Text>
              <Text style={{ fontSize: 15, color: '#374151', lineHeight: 20, marginTop: 4 }}>
                {step.text}
              </Text>
              {step.diagramUrl && (
                <Image 
                  source={{ uri: step.diagramUrl }} 
                  style={{ width: '100%', height: 160, borderRadius: 10, marginTop: 8 }} 
                  resizeMode="cover" 
                />
              )}
            </View>
          ))
        ) : plan.steps && plan.steps.length > 0 ? (
          plan.steps.map((step: any, i: number) => (
            <View key={i} style={{ backgroundColor: '#FFFFFF', borderRadius: 12, padding: 12, marginVertical: 6, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 }}>
              <Text style={{ fontSize: 16, fontWeight: '700', color: '#111827' }}>
                {`${i + 1}. ${step.title || 'Step'}`}
              </Text>
              {step.body && (
                <Text style={{ fontSize: 15, color: '#374151', lineHeight: 20, marginTop: 4 }}>
                  {step.body}
                </Text>
              )}
              {step.photo_url && (
                <Image 
                  source={{ uri: step.photo_url }} 
                  style={{ width: '100%', height: 160, borderRadius: 10, marginTop: 8 }} 
                  resizeMode="cover" 
                />
              )}
            </View>
          ))
        ) : (
          <Text style={{ fontSize: 15, color: '#777' }}>No build steps yet.</Text>
        )}
      </View>

      {/* Totals Footer */}
      {(() => {
        const materialsSubtotal = planData?.materials?.reduce((sum, m) => sum + (m.subtotalUsd || 0), 0) || 0;
        const estCost = planData?.summary?.estCostUsd;
        
        if (estCost || materialsSubtotal > 0) {
          return (
            <View style={{ backgroundColor: 'white', marginTop: 24, marginHorizontal: 16, borderRadius: 16, padding: 20, borderWidth: 2, borderColor: '#7C3AED' }}>
              <Text style={{ fontSize: 18, fontWeight: '700', color: '#111827', marginBottom: 12 }}>Total Estimate</Text>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <Text style={{ fontSize: 15, color: '#6B7280' }}>
                  {estCost ? 'Estimated Cost' : 'Materials Cost'}
                </Text>
                <Text style={{ fontSize: 28, fontWeight: '800', color: '#7C3AED' }}>
                  {estCost ? fmtMoney(estCost) : `~${fmtMoney(materialsSubtotal)}`}
                </Text>
              </View>
              {!estCost && materialsSubtotal > 0 && (
                <Text style={{ fontSize: 12, color: '#9CA3AF', marginTop: 4, fontStyle: 'italic' }}>
                  ~ Based on materials only
                </Text>
              )}
            </View>
          );
        }
        return null;
      })()}

      {/* Save All Button */}
      <View style={{ paddingHorizontal: 16, paddingVertical: 24 }}>
        <Pressable
          onPress={saveAll}
          disabled={saving}
          style={({ pressed }) => ({
            backgroundColor: pressed ? '#6D28D9' : '#7C3AED',
            padding: 16,
            borderRadius: 12,
            alignItems: 'center',
            opacity: saving ? 0.7 : 1
          })}
        >
          <Text style={{ color: 'white', fontSize: 16, fontWeight: '700' }}>
            {saving ? 'Saving...' : 'Save All Sections to Photos'}
          </Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}
