import { supabase } from './supabase';

const MEASURE_API_BASE = 'https://api.diygenieapp.com/api';

export async function startMeasurement({
  projectId,
  scanId,
  userId,
  roi,
}: {
  projectId: string;
  scanId: string;
  userId: string;
  roi?: { x: number; y: number; w: number; h: number };
}): Promise<{ ok: boolean; status?: 'pending' | 'done' }> {
  try {
    console.log('[measure] start →', { projectId, scanId });
    
    const response = await fetch(
      `${MEASURE_API_BASE}/projects/${projectId}/scans/${scanId}/measure`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId, roi }),
      }
    );

    if (!response.ok) {
      console.log('[measure] error (start) →', response.status);
      return { ok: false };
    }

    const data = await response.json();
    return { ok: true, status: data.status };
  } catch (err) {
    console.log('[measure] error (start) →', err);
    return { ok: false };
  }
}

export async function pollMeasurement({
  projectId,
  scanId,
  userId,
  tries = 10,
  intervalMs = 1500,
}: {
  projectId: string;
  scanId: string;
  userId: string;
  tries?: number;
  intervalMs?: number;
}): Promise<{
  ok: boolean;
  result?: { width_in: number; height_in: number; px_per_in: number };
}> {
  for (let i = 0; i < tries; i++) {
    try {
      console.log(`[measure] poll try ${i + 1}`);
      
      const response = await fetch(
        `${MEASURE_API_BASE}/projects/${projectId}/scans/${scanId}/measure/status?user_id=${userId}`
      );

      if (!response.ok) {
        console.log('[measure] error (poll) →', response.status);
        await new Promise((resolve) => setTimeout(resolve, intervalMs));
        continue;
      }

      const data = await response.json();

      if (data.status === 'done' && data.result) {
        console.log('[measure] done →', data.result);
        return {
          ok: true,
          result: {
            width_in: data.result.width_in,
            height_in: data.result.height_in,
            px_per_in: data.result.px_per_in,
          },
        };
      }

      await new Promise((resolve) => setTimeout(resolve, intervalMs));
    } catch (err) {
      console.log('[measure] error (poll) →', err);
      await new Promise((resolve) => setTimeout(resolve, intervalMs));
    }
  }

  console.log('[measure] error → timeout after', tries, 'tries');
  return { ok: false };
}

export type LinePoint = { x: number; y: number };

export async function saveLineMeasurement(opts: {
  scanId: string;
  regionId?: string | null;
  points: LinePoint[];
  valueInches: number;
  unit?: string;
}) {
  const { data, error } = await supabase
    .from('room_scan_measurements')
    .insert({
      scan_id: opts.scanId,
      region_id: opts.regionId ?? null,
      tool: 'line',
      points: opts.points,
      value: opts.valueInches,
      unit: opts.unit ?? 'in',
      meta: {},
    })
    .select('*')
    .single();
  if (error) throw error;
  return data;
}

export async function getScanScalePxPerIn(scanId: string): Promise<number | null> {
  try {
    const { data } = await supabase
      .from('room_scans')
      .select('scale_px_per_in')
      .eq('id', scanId)
      .single();
    return data?.scale_px_per_in ?? null;
  } catch {
    return null;
  }
}

export async function setScanScalePxPerIn(scanId: string, pxPerIn: number): Promise<void> {
  await supabase
    .from('room_scans')
    .update({ scale_px_per_in: pxPerIn })
    .eq('id', scanId);
}
