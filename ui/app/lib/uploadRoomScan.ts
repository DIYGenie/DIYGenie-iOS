import * as Crypto from 'expo-crypto';
import * as ImageManipulator from 'expo-image-manipulator';
import { supabase } from './supabase';
import { Platform } from 'react-native';
import { ensureProfile } from './ensureProfile';

type Args = {
  uri: string;
  userId: string;
  projectId?: string | null;
};

function guessContentType(uri: string) {
  const lower = uri.split('?')[0].toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.heic')) return 'image/heic';
  return 'application/octet-stream';
}

async function ensureJpeg(uri: string) {
  const ct = guessContentType(uri);
  if (ct === 'image/heic' || ct === 'application/octet-stream') {
    const out = await ImageManipulator.manipulateAsync(
      uri,
      [],
      { compress: 0.9, format: ImageManipulator.SaveFormat.JPEG }
    );
    return { uri: out.uri, contentType: 'image/jpeg' as const };
  }
  if (ct === 'image/png' || ct === 'image/jpeg') {
    return { uri, contentType: ct as 'image/png' | 'image/jpeg' };
  }
  const out = await ImageManipulator.manipulateAsync(
    uri,
    [],
    { compress: 0.9, format: ImageManipulator.SaveFormat.JPEG }
  );
  return { uri: out.uri, contentType: 'image/jpeg' as const };
}

export async function uploadRoomScan({ uri, userId, projectId = null }: Args) {
  // 1) Make a stable id and storage path
  const scanId = Crypto.randomUUID();
  const path = `${userId}/${scanId}.jpg`;

  // 2) Convert HEIC to JPEG if needed
  const { uri: uploadUri, contentType } = await ensureJpeg(uri);

  // 3) Turn the local file into ArrayBuffer for supabase-js
  const res = await fetch(uploadUri);
  const arrayBuffer = await res.arrayBuffer();

  // 4) Upload to storage
  const { error: upErr } = await supabase
    .storage
    .from('room-scans')
    .upload(path, arrayBuffer, { contentType, upsert: false });

  if (upErr) throw upErr;

  // 5) Get a public URL (bucket policy already set)
  const { data: pub } = supabase.storage.from('room-scans').getPublicUrl(path);
  const imageUrl = pub?.publicUrl ?? null;

  // 6) Basic dimensions if available (best-effort)
  let width: number | null = null;
  let height: number | null = null;
  try {
    // iOS/Android: Image.getSize needs a network URL; this may fail silently on some dev tunnels.
    // That's okay—dimensions are optional and can be filled later by a server job.
    const sizeRes = await fetch(imageUrl!);
    // If you want real dimensions later, we'll add an Image.getSize step on-device once it's in the cache.
  } catch {}

  // 7) Ensure profile exists (for FK constraint)
  await ensureProfile();

  // 8) Insert DB row
  const { error: dbErr } = await supabase.from('room_scans').insert([{
    id: scanId,
    user_id: userId,
    project_id: projectId,
    image_url: imageUrl,
    raw_scan_url: null,
    dimensions: width && height ? { width, height } : null,
    scale_px_per_in: null,
    meta: {
      source: 'camera',
      platform: Platform.OS,
    }
  }]);

  if (dbErr) throw dbErr;

  return { scanId, imageUrl, path };
}
