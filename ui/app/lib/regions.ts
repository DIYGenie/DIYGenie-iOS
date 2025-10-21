import { supabase } from './supabase';

export type Pt = { x: number; y: number };
export type NormRect = { x: number; y: number; w: number; h: number };

export async function saveRoomScanRegion(params: {
  scanId: string;
  points: Pt[];               // 0..1 normalized TL, TR, BR, BL
  label?: string | null;
}) {
  const row = {
    scan_id: params.scanId,
    points: params.points,
    kind: 'focus_area',
    label: params.label ?? 'Area 1',
    normalized: true,
    meta: {},
  };

  const { data, error } = await supabase
    .from('room_scan_regions')
    .insert(row)
    .select('*')
    .single();

  if (error) throw error;
  return data;
}

export async function getLatestScanIdForProject(projectId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from('room_scans')
    .select('id')
    .eq('project_id', projectId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return (data?.id as string) ?? null;
}

async function ensureScanForProject(projectId: string): Promise<string> {
  let scanId = await getLatestScanIdForProject(projectId);
  if (scanId) return scanId;

  const { data: sess } = await supabase.auth.getSession();
  const userId = sess?.session?.user?.id;
  if (!userId) throw new Error('AUTH_REQUIRED');

  const { data, error } = await supabase
    .from('room_scans')
    .insert({
      user_id: userId,
      project_id: projectId,
      meta: { source: 'ar' },
    })
    .select('id')
    .single();
  if (error) throw error;
  return data.id as string;
}

export async function saveFocusRegion(projectId: string, rect: NormRect) {
  const scanId = await ensureScanForProject(projectId);
  const { data, error } = await supabase
    .from('room_scan_regions')
    .insert({
      scan_id: scanId,
      kind: 'roi',
      label: 'Focus area',
      points: rect,
      normalized: true,
      order_index: 0,
      meta: {},
    })
    .select('id')
    .single();
  if (error) throw error;
  return { regionId: data.id as string, scanId };
}
