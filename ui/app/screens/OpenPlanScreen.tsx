import React, { useRef } from "react";
import { View, Text, ScrollView, Pressable, Alert } from "react-native";
import { captureRef } from 'react-native-view-shot';
import * as MediaLibrary from 'expo-media-library';

export default function OpenPlanScreen({ route, navigation }: any) {
  const { id } = route.params || {};
  const pageRef = useRef<ScrollView>(null);

  async function savePlanToPhotos() {
    try {
      const { status } = await MediaLibrary.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission required', 'Please allow photo access to save your plan.');
        return;
      }

      const uri = await captureRef(pageRef, { format: 'png', quality: 1 });
      await MediaLibrary.saveToLibraryAsync(uri);
      console.log('[plan] saved to photos');
      Alert.alert('Saved', 'Your plan has been saved to Photos.');
    } catch (e) {
      console.log('[save plan failed]', e);
      Alert.alert('Save failed', 'Please try again.');
    }
  }

  return (
    <View style={{ flex: 1 }}>
      <ScrollView
        ref={pageRef}
        contentContainerStyle={{ padding: 16, gap: 12, paddingBottom: 120 }}
        keyboardShouldPersistTaps="handled"
      >
        {/* Overview */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 20, fontWeight: '800', marginBottom: 8 }}>Overview</Text>
          <Text style={{ color: '#4B5563' }}>High-level summary of the build (auto-generated).</Text>
        </View>

        {/* Materials */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 18, fontWeight: '800', marginBottom: 8 }}>Materials</Text>
          <Text style={{ color: '#4B5563' }}>• 2x4 lumber (qty: 8)</Text>
          <Text style={{ color: '#4B5563' }}>• Plywood 3/4" (2 sheets)</Text>
          <Text style={{ color: '#4B5563' }}>• Wood screws (1lb box)</Text>
          <Text style={{ color: '#4B5563' }}>• Wood glue</Text>
        </View>

        {/* Tools */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 18, fontWeight: '800', marginBottom: 8 }}>Tools</Text>
          <Text style={{ color: '#4B5563' }}>• Circular saw or miter saw</Text>
          <Text style={{ color: '#4B5563' }}>• Drill with bits</Text>
          <Text style={{ color: '#4B5563' }}>• Level</Text>
          <Text style={{ color: '#4B5563' }}>• Measuring tape</Text>
          <Text style={{ color: '#4B5563' }}>• Clamps</Text>
        </View>

        {/* Cut List */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 18, fontWeight: '800', marginBottom: 8 }}>Cut List</Text>
          <Text style={{ color: '#4B5563' }}>• 2x4 @ 96" (qty: 4)</Text>
          <Text style={{ color: '#4B5563' }}>• 2x4 @ 48" (qty: 4)</Text>
          <Text style={{ color: '#4B5563' }}>• Plywood @ 48" x 24" (qty: 2)</Text>
        </View>

        {/* Steps */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 18, fontWeight: '800', marginBottom: 8 }}>Step-by-Step</Text>
          <Text style={{ color: '#4B5563', marginTop: 4 }}>1. Cut all lumber to size per cut list</Text>
          <Text style={{ color: '#4B5563', marginTop: 4 }}>2. Assemble the frame using wood glue and screws</Text>
          <Text style={{ color: '#4B5563', marginTop: 4 }}>3. Attach plywood to frame</Text>
          <Text style={{ color: '#4B5563', marginTop: 4 }}>4. Sand all surfaces smooth</Text>
          <Text style={{ color: '#4B5563', marginTop: 4 }}>5. Apply finish of choice</Text>
        </View>

        {/* Time & Cost */}
        <View style={{ backgroundColor: '#F9FAFB', borderRadius: 16, padding: 16 }}>
          <Text style={{ fontSize: 18, fontWeight: '800', marginBottom: 8 }}>Time & Cost</Text>
          <Text style={{ color: '#4B5563', fontWeight: '600', marginTop: 4 }}>Estimated Time: 4-6 hours</Text>
          <Text style={{ color: '#4B5563', marginTop: 2 }}>• Cutting: 1 hour</Text>
          <Text style={{ color: '#4B5563', marginTop: 2 }}>• Assembly: 2-3 hours</Text>
          <Text style={{ color: '#4B5563', marginTop: 2 }}>• Finishing: 1-2 hours</Text>
          <Text style={{ color: '#4B5563', fontWeight: '600', marginTop: 8 }}>Estimated Cost: $75-$125</Text>
          <Text style={{ color: '#4B5563', marginTop: 2 }}>Based on average material prices</Text>
        </View>
      </ScrollView>

      <View style={{ position: 'absolute', left: 16, right: 16, bottom: 16, gap: 10 }}>
        <Pressable
          onPress={savePlanToPhotos}
          style={{ backgroundColor: '#6D28D9', padding: 14, borderRadius: 14, alignItems: 'center' }}
        >
          <Text style={{ color: 'white', fontWeight: '700' }}>Save to Photos</Text>
        </Pressable>
        <Pressable
          onPress={() => navigation.goBack()}
          style={{ backgroundColor: '#111827', padding: 14, borderRadius: 14, alignItems: 'center' }}
        >
          <Text style={{ color: 'white', fontWeight: '700' }}>Back to Project</Text>
        </Pressable>
      </View>
    </View>
  );
}
