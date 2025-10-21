import * as FileSystem from 'expo-file-system';
import { supabase } from '../../lib/supabase';
import { Platform } from 'react-native';

type SaveArgs = {
  uri: string;
  source: 'scan' | 'upload';
  projectId?: string | null;
  userId?: string | null;
};

export async function saveRoomScan({ uri, source, projectId = null, userId = null }: SaveArgs) {
  if (!userId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Please sign in to save scans.');
    userId = user.id;
  }

  const base64 = await FileSystem.readAsStringAsync(uri, { encoding: 'base64' });
  const fileBytes = Uint8Array.from(atob(base64), c => c.charCodeAt(0));
  const file = new Blob([fileBytes], { type: 'image/jpeg' });

  const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}.jpg`;
  const path = `${userId}/${filename}`;

  const { error: upErr } = await supabase.storage.from('room-scans').upload(path, file, {
    contentType: 'image/jpeg',
    upsert: false,
  });
  if (upErr) throw upErr;

  const { data: signed, error: signErr } = await supabase.storage
    .from('room-scans')
    .createSignedUrl(path, 60 * 60 * 24 * 7);
  if (signErr) throw signErr;

  const signedUrl = signed?.signedUrl;
  if (!signedUrl) throw new Error('Failed to create signed URL');

  const meta = {
    source,
    device: Platform.OS,
    flow: 'new_project',
    v: 1,
  };

  const { data, error: dbErr } = await supabase
    .from('room_scans')
    .insert({
      user_id: userId,
      project_id: projectId ?? null,
      image_url: signedUrl,
      raw_scan_url: path,
      meta,
    })
    .select('*')
    .single();

  if (dbErr) throw dbErr;

  return { id: data?.id, image_url: signedUrl, path };
}
