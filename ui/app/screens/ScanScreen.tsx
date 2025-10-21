import React, { useState, useEffect, useRef } from 'react';
import { View, Text, Pressable, Alert, TouchableOpacity } from 'react-native';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import DraggableRect from '../components/DraggableRect';
import { saveArScan } from '../lib/scanEvents';
import { arSupported, startArSession, stopArSession } from '../lib/ar/ArSession';
import { captureRef } from 'react-native-view-shot';
import * as MediaLibrary from 'expo-media-library';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { getUserId } from '../lib/auth';
import { startMeasurement, pollMeasurement } from '../lib/measure';
import { loadNewProjectDraft, saveNewProjectDraft } from '../lib/draft';
import { saveRoomScan } from '../features/scans/saveRoomScan';

export default function ScanScreen() {
  const navigation = useNavigation();
  type Params = { projectId?: string };
  const route = useRoute<RouteProp<Record<'ScanScreen', Params>, 'ScanScreen'>>();
  const projectId = route.params?.projectId;
  const [norm, setNorm] = useState<{ x: number; y: number; w: number; h: number }>({ x: 0.2, y: 0.2, w: 0.5, h: 0.35 });
  const [saving, setSaving] = useState(false);
  const [scanSaved, setScanSaved] = useState(false);
  const [snapshotSaving, setSnapshotSaving] = useState(false);
  const [toast, setToast] = useState({ visible: false, message: '' });
  const [arReady, setArReady] = useState(false);
  const usingExpoGo = !(global as any).expo?.modules?.ExpoModules;
  const viewRef = useRef<View>(null);
  const cameraRef = useRef<any>(null);
  const [permission, requestPermission] = useCameraPermissions();

  useEffect(() => {
    requestPermission();
  }, []);

  useEffect(() => {
    if (!projectId) {
      console.log('[scan] missing projectId – bailing');
      Alert.alert('Missing project', 'Please start the scan from the New Project form.');
      navigation.goBack();
    }
  }, [projectId, navigation]);

  useEffect(() => {
    let alive = true;

    (async () => {
      if (!projectId) return;

      if (!arSupported() || usingExpoGo) {
        setArReady(false);
        return;
      }

      try {
        await startArSession({ projectId });
        if (alive) setArReady(true);
      } catch (e) {
        console.log('[ar] start failed', e);
        Alert.alert('AR unavailable', 'Falling back to manual ROI.');
        setArReady(false);
      }
    })();

    return () => {
      alive = false;
      stopArSession().catch(() => {});
    };
  }, [projectId, usingExpoGo]);

  const handleSave = async () => {
    if (!projectId) {
      console.log('[scan] missing projectId in handleSave – should not happen');
      Alert.alert('Error', 'Please create a project first.');
      return;
    }

    setSaving(true);
    try {
      let imageUrl: string | undefined;
      
      if (cameraRef.current && permission?.granted) {
        try {
          console.log('[camera] taking picture...');
          const photo = await cameraRef.current.takePictureAsync({ 
            quality: 0.8, 
            skipProcessing: true 
          });
          
          if (photo?.uri) {
            console.log('[camera] picture taken', { uri: photo.uri });
            
            const userId = await getUserId();
            const result = await saveRoomScan({
              uri: photo.uri,
              source: 'scan',
              projectId,
              userId,
            });
            
            imageUrl = result.image_url;
            console.log('[media] saved scan (AR)', { hasImage: true, imageUrl });
          }
        } catch (cameraError: any) {
          console.log('[camera] failed to take picture', cameraError?.message || cameraError);
        }
      }
      
      console.log('[scan] saveArScan start', { projectId, source: 'ar', roi: norm, hasImage: !!imageUrl });
      
      const { scanId } = await saveArScan({
        projectId,
        roi: norm,
      });
      
      console.log('[scan] saved', { scanId, hasImage: !!imageUrl });
      setScanSaved(true);
      
      const result = { 
        scanId, 
        source: 'ar' as const,
        projectId,
        roi: norm
      };
      
      Alert.alert('Success', 'Scan saved');
      
      (navigation as any).navigate({
        name: 'Main',
        params: { screen: 'NewProject', params: { savedScan: result } },
        merge: true,
      });

      const userId = await getUserId();
      if (userId) {
        (async () => {
          const startResult = await startMeasurement({
            projectId,
            scanId,
            userId,
            roi: norm,
          });

          if (!startResult.ok) {
            console.log('[measure] start failed, skipping poll');
            return;
          }

          const pollResult = await pollMeasurement({
            projectId,
            scanId,
            userId,
          });

          if (pollResult.ok && pollResult.result) {
            const draft = await loadNewProjectDraft();
            if (draft) {
              await saveNewProjectDraft({
                ...draft,
                measurement: {
                  width_in: pollResult.result.width_in,
                  height_in: pollResult.result.height_in,
                  px_per_in: pollResult.result.px_per_in,
                  roi: norm,
                },
              });
            }
          }
        })();
      }
    } catch (e: any) {
      console.log('[scan] save failed', String(e?.message || e));
      Alert.alert('Could not save scan', 'Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleSnapshot = async () => {
    if (!scanSaved) {
      Alert.alert('Save scan first', 'Please save the scan before taking a snapshot.');
      return;
    }

    setSnapshotSaving(true);
    try {
      // Request permissions
      const { status } = await MediaLibrary.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission required', 'Please allow access to save photos.');
        setSnapshotSaving(false);
        return;
      }

      // Capture screen with ROI overlay
      const uri = await captureRef(viewRef, {
        format: 'png',
        quality: 1,
      });

      // Save to camera roll
      await MediaLibrary.saveToLibraryAsync(uri);
      console.log('[scan snapshot] saved to camera roll');

      // Show success toast
      setToast({ visible: true, message: 'Snapshot saved to Photos' });
      setTimeout(() => setToast({ visible: false, message: '' }), 3000);
    } catch (e: any) {
      console.log('[scan snapshot] save failed', String(e?.message || e));
      Alert.alert('Snapshot failed', 'Could not save snapshot to camera roll.');
    } finally {
      setSnapshotSaving(false);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#000' }} ref={viewRef} collapsable={false}>
      {(!arSupported() || usingExpoGo) && (
        <View style={{ backgroundColor: '#F3E8FF', padding: 12 }}>
          <Text style={{ color: '#6D28D9', fontWeight: '700' }}>
            AR requires an iOS development build
          </Text>
          <Text style={{ color: '#6B7280', marginTop: 4 }}>
            You're in Expo Go. You can still drag the purple focus box and save the scan.
          </Text>
        </View>
      )}

      <View style={{ flex: 1, padding: 16 }}>
        <Text style={{ fontSize: 22, fontWeight: '700', marginBottom: 8, color: 'white' }}>Adjust area</Text>
        <Text style={{ fontSize: 14, color: '#9CA3AF', marginBottom: 12 }}>
          {permission?.granted 
            ? 'Drag or resize the purple box to frame your target area.' 
            : 'Camera permission required to scan.'}
        </Text>

        {/* Live camera view with adjustable ROI */}
        <View style={{ borderRadius: 16, overflow: 'hidden', flex: 1 }}>
          {permission?.granted ? (
            <CameraView
              ref={cameraRef}
              style={{ flex: 1 }}
              facing="back"
              onCameraReady={() => console.log('[camera] ready')}
              onMountError={(e) => console.error('[camera] mount error', e)}
            >
              <View style={{
                position: 'absolute',
                borderWidth: 3,
                borderColor: '#8B5CF6',
                borderRadius: 8,
                left: '30%',
                top: '25%',
                width: '40%',
                height: '50%',
              }} />
            </CameraView>
          ) : (
            <View style={{ backgroundColor: '#111827', flex: 1, alignItems: 'center', justifyContent: 'center', padding: 16 }}>
              <Ionicons name="camera-outline" size={48} color="#9CA3AF" />
              <Text style={{ color: '#9CA3AF', marginTop: 12, textAlign: 'center' }}>
                Camera permission required
              </Text>
              <Pressable
                onPress={requestPermission}
                style={{ 
                  backgroundColor: '#7C3AED', 
                  paddingVertical: 12, 
                  paddingHorizontal: 24, 
                  borderRadius: 8, 
                  marginTop: 16 
                }}
              >
                <Text style={{ color: 'white', fontWeight: '600' }}>Grant Permission</Text>
              </Pressable>
            </View>
          )}
        </View>
      </View>

      <View style={{ padding: 16, paddingTop: 0, gap: 12 }}>
        {scanSaved && (
          <TouchableOpacity
            onPress={handleSnapshot}
            disabled={snapshotSaving}
            activeOpacity={0.9}
            style={{ 
              borderRadius: 12, 
              overflow: 'hidden',
              shadowColor: '#000',
              shadowOpacity: 0.15,
              shadowRadius: 8,
              shadowOffset: { width: 0, height: 4 },
              elevation: 6
            }}
          >
            <LinearGradient
              colors={snapshotSaving ? ['#9CA3AF', '#9CA3AF'] : ['#7C3AED', '#6D28D9']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={{ paddingVertical: 14, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 }}
            >
              <Ionicons name="camera-outline" size={20} color="white" />
              <Text style={{ color: 'white', fontWeight: '700', fontSize: 16 }}>
                {snapshotSaving ? 'Saving Snapshot...' : 'Save Snapshot'}
              </Text>
            </LinearGradient>
          </TouchableOpacity>
        )}

        <Pressable
          onPress={handleSave}
          disabled={saving}
          style={{ 
            backgroundColor: saving ? '#9CA3AF' : '#7C3AED', 
            paddingVertical: 14, 
            borderRadius: 12, 
            alignItems: 'center' 
          }}
        >
          <Text style={{ color: 'white', fontWeight: '600', fontSize: 16 }}>
            {saving ? 'Saving...' : 'Save scan & Close'}
          </Text>
        </Pressable>
      </View>

      {/* Toast */}
      {toast.visible && (
        <View style={{
          position: 'absolute',
          top: 100,
          left: 20,
          right: 20,
          backgroundColor: '#10B981',
          paddingVertical: 12,
          paddingHorizontal: 16,
          borderRadius: 12,
          flexDirection: 'row',
          alignItems: 'center',
          gap: 8,
          shadowColor: '#000',
          shadowOpacity: 0.2,
          shadowRadius: 8,
          shadowOffset: { width: 0, height: 4 },
          elevation: 8
        }}>
          <Ionicons name="checkmark-circle" size={20} color="white" />
          <Text style={{ color: 'white', fontWeight: '600', fontSize: 15, flex: 1 }}>{toast.message}</Text>
        </View>
      )}
    </View>
  );
}
