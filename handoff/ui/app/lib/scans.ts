import { supabase } from './supabase';

export async function attachScanToProject(scanId: string, projectId: string) {
  const { error } = await supabase
    .from('room_scans')
    .update({ project_id: projectId })
    .eq('id', scanId);
  if (error) throw error;
  return true;
}
