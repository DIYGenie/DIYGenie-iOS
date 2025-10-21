import { View, Text, TouchableOpacity, Alert } from 'react-native';
import { captureRef } from 'react-native-view-shot';
import { useRef, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as MediaLibrary from 'expo-media-library';
import * as FileSystem from 'expo-file-system';
import * as Clipboard from 'expo-clipboard';
import { Ionicons } from '@expo/vector-icons';

export function SectionListCard({
  title,
  items,
  projectId,
  sectionKey,
}: {
  title: string;
  items: string[];
  projectId?: string;
  sectionKey?: string;
}) {
  const ref = useRef<View>(null);
  const [checkedItems, setCheckedItems] = useState<Set<number>>(new Set());
  const storageKey = projectId && sectionKey ? `checkboxes:${projectId}:${sectionKey}` : null;

  useEffect(() => {
    if (!storageKey) return;
    
    AsyncStorage.getItem(storageKey).then(data => {
      if (data) {
        setCheckedItems(new Set(JSON.parse(data)));
      }
    });
  }, [storageKey]);

  const toggleCheckbox = async (index: number) => {
    const newChecked = new Set(checkedItems);
    if (newChecked.has(index)) {
      newChecked.delete(index);
    } else {
      newChecked.add(index);
    }
    setCheckedItems(newChecked);
    
    if (storageKey) {
      await AsyncStorage.setItem(storageKey, JSON.stringify(Array.from(newChecked)));
    }
  };

  const handleCopy = async () => {
    try {
      await Clipboard.setStringAsync(items.join('\n'));
      Alert.alert('Copied!', `${items.length} items copied to clipboard`);
    } catch (e) {
      console.log('[copy error]', e);
      Alert.alert('Error', 'Could not copy to clipboard');
    }
  };

  const handleSave = async () => {
    try {
      if (!ref.current) return;
      
      const uri = await captureRef(ref, { format: 'png', quality: 1 });
      
      const { status } = await MediaLibrary.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Required', 'Please grant photo library access to save images');
        return;
      }
      
      const asset = await MediaLibrary.createAssetAsync(uri);
      await MediaLibrary.createAlbumAsync('DIY Genie', asset, false);
      
      Alert.alert('Saved!', 'Image saved to your Photos in "DIY Genie" album');
    } catch (e) {
      console.log('[save error]', e);
      Alert.alert('Error', 'Could not save to photos');
    }
  };

  return (
    <View
      ref={ref}
      style={{
        backgroundColor: '#fff',
        borderRadius: 16,
        padding: 16,
        marginBottom: 12,
      }}
    >
      <View
        style={{
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 8,
        }}
      >
        <Text style={{ fontSize: 16, fontWeight: '700' }}>{title}</Text>
        <View style={{ flexDirection: 'row', gap: 12 }}>
          <TouchableOpacity onPress={handleCopy}>
            <Text style={{ color: '#6D28D9' }}>Copy</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={handleSave}>
            <Text style={{ color: '#6D28D9' }}>Save</Text>
          </TouchableOpacity>
        </View>
      </View>
      {items.length === 0 ? (
        <Text style={{ opacity: 0.6 }}>No items listed.</Text>
      ) : (
        items.map((t, i) => {
          const isChecked = checkedItems.has(i);
          return (
            <TouchableOpacity
              key={i}
              onPress={() => toggleCheckbox(i)}
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                marginVertical: 6,
              }}
            >
              <View
                style={{
                  width: 22,
                  height: 22,
                  borderRadius: 5,
                  borderWidth: 1,
                  borderColor: isChecked ? '#6D28D9' : '#D1D5DB',
                  backgroundColor: isChecked ? '#6D28D9' : 'transparent',
                  marginRight: 10,
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {isChecked && (
                  <Ionicons name="checkmark" size={16} color="#fff" />
                )}
              </View>
              <Text style={{ flex: 1, textDecorationLine: isChecked ? 'line-through' : 'none', opacity: isChecked ? 0.6 : 1 }}>{t}</Text>
            </TouchableOpacity>
          );
        })
      )}
    </View>
  );
}
