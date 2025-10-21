/**
 * Supabase Storage helper for image uploads
 */

import { Platform } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SUPABASE_URL, SUPABASE_ANON_KEY, UPLOADS_BUCKET } from '../config';

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Export supabase client for auth access
export { supabase };

/**
 * Detect mime type from file extension
 */
function guessMime(uri: string): string {
  return uri.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
}

/**
 * Pick an image from the device gallery
 * Version-safe implementation that works across Expo versions
 * Directly opens library picker without requesting permissions (iOS/Android handle this automatically)
 * 
 * @returns URI string or null if cancelled
 */
export async function pickImageAsync(): Promise<string | null> {
  // Directly open library; do NOT request permission up-front to avoid "cannot grant permission" errors
  const mediaTypes =
    (ImagePicker as any).MediaType
      ? [(ImagePicker as any).MediaType.Images]
      : (ImagePicker as any).MediaTypeOptions?.Images ?? 0;

  const res = await ImagePicker.launchImageLibraryAsync({
    mediaTypes,
    quality: 0.85,
    allowsEditing: false,
  });

  if (res.canceled) return null;
  const asset = res.assets?.[0] ?? (res as any);
  return asset?.uri ?? null;
}

/**
 * Pick room photo and return full asset object
 * Version-safe implementation for FormData uploads
 * Directly opens library picker without requesting permissions (iOS/Android handle this automatically)
 * 
 * @returns Asset object with uri, fileName, mimeType or null if cancelled
 */
export async function pickRoomPhoto(): Promise<any | null> {
  // Directly open library; do NOT request permission up-front to avoid "cannot grant permission" errors
  const mediaTypes =
    (ImagePicker as any).MediaType
      ? [(ImagePicker as any).MediaType.Images]
      : (ImagePicker as any).MediaTypeOptions?.Images ?? 0;

  const res = await ImagePicker.launchImageLibraryAsync({
    mediaTypes,
    quality: 0.85,
    allowsEditing: false,
  });

  if (res.canceled) return null;
  return res.assets?.[0] ?? (res as any);
}

/**
 * Upload an image to Supabase Storage and return its public URL
 * 
 * @param projectId - Project ID for organizing uploads
 * @param fileUri - Local file URI from image picker
 * @returns Public URL of the uploaded image
 * @throws Error (not ApiError) on storage failures
 */
export async function uploadImageAsync(
  projectId: string,
  fileUri: string
): Promise<string> {
  const contentType = guessMime(fileUri);
  const ext = contentType === 'image/png' ? 'png' : 'jpg';
  const fileName = `${Date.now()}.${ext}`;
  const path = `projects/${projectId}/${fileName}`;

  const resp = await fetch(fileUri);
  const blob = await resp.blob();

  const file = Platform.OS === 'web'
    ? new File([blob], fileName, { type: contentType })
    : blob;

  const { error } = await supabase
    .storage
    .from(UPLOADS_BUCKET)
    .upload(path, file as any, { contentType, upsert: true });

  if (error) throw new Error(error.message);
  
  const { data: pub } = supabase.storage.from(UPLOADS_BUCKET).getPublicUrl(path);
  return pub?.publicUrl;
}

export async function getFlag(key: string): Promise<boolean> {
  try {
    const val = await AsyncStorage.getItem(key);
    return val === 'true';
  } catch (e) {
    console.warn('[storage] getFlag failed', key, e);
    return false;
  }
}

export async function setFlag(key: string, value: boolean): Promise<void> {
  try {
    await AsyncStorage.setItem(key, String(value));
  } catch (e) {
    console.warn('[storage] setFlag failed', key, e);
  }
}
