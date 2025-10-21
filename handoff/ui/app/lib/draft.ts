// app/lib/draft.ts
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createProjectAndReturnId } from './api';

const DRAFT_KEY = 'newProjectDraft:v1';

export type NewProjectDraft = {
  projectId?: string | null;
  name?: string;
  description?: string;
  budget?: string | null;          // '$' | '$$' | '$$$'
  skill_level?: string | null;     // 'Beginner' | 'Intermediate' | 'Advanced'
  measurement?: { width_in: number; height_in: number; px_per_in?: number; roi?: any } | null;
};

export async function loadNewProjectDraft(): Promise<NewProjectDraft | null> {
  try {
    const raw = await AsyncStorage.getItem(DRAFT_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export async function saveNewProjectDraft(draft: NewProjectDraft): Promise<void> {
  await AsyncStorage.setItem(DRAFT_KEY, JSON.stringify(draft ?? {}));
}

export async function clearNewProjectDraft(): Promise<void> {
  await AsyncStorage.removeItem(DRAFT_KEY);
}

// --- helpers for name cleanup ---
function collapseSpaces(s: string) {
  return (s || '').replace(/\s+/g, ' ').trim();
}
export function sanitizeProjectName(raw: string) {
  // trim + collapse
  const trimmed = collapseSpaces(raw);
  // strip emojis / control chars
  const basic = trimmed.normalize('NFKD').replace(/[^\w\s\-.']/g, '');
  // whitelist: letters/numbers/space/._-'
  const whitelisted = basic.replace(/[^A-Za-z0-9 _.\-']/g, '');
  // collapse again and bound length
  let safe = collapseSpaces(whitelisted).slice(0, 60);
  // avoid leading/trailing punctuation
  safe = safe.replace(/^[\s._'\-]+/, '').replace(/[\s._'\-]+$/, '');
  return safe;
}
function nameLooksValid(name: string) {
  const s = (name || '').trim();
  return s.length >= 3 && s.length <= 60 && /[A-Za-z0-9]/.test(s);
}

function generateDefaultName(description?: string) {
  const ts = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  const stamp = `${ts.getFullYear()}-${pad(ts.getMonth()+1)}-${pad(ts.getDate())} ${pad(ts.getHours())}:${pad(ts.getMinutes())}:${pad(ts.getSeconds())}`;
  let base = 'DIY Project';
  const desc = collapseSpaces(description || '');
  if (desc.length >= 6) {
    // Take first 3 words from description to make a human-ish default
    const words = desc.split(' ').slice(0, 3).join(' ');
    base = collapseSpaces(words).replace(/[^A-Za-z0-9 _.\-']/g, '');
    // Ensure after cleanup we still have something usable
    if (!nameLooksValid(base)) base = 'DIY Project';
  }
  return `${base} ${stamp}`.slice(0, 60);
}

// ---------- NEW: strong validation + project create ----------
function validateDraftForCreate(d: NewProjectDraft) {
  const errs: string[] = [];
  const name = (d.name ?? '').trim();
  const description = (d.description ?? '').trim();
  const budget = (d.budget ?? '').trim();
  const skill = (d.skill_level ?? '').trim();

  if (name.length < 3) errs.push('Title must be at least 3 characters.');
  if (description.length < 10) errs.push('Description must be at least 10 characters.');
  if (!['$', '$$', '$$$'].includes(budget)) errs.push('Choose a budget ($, $$, $$$).');
  if (!['Beginner', 'Intermediate', 'Advanced'].includes(skill)) errs.push('Choose a skill level.');
  return { ok: errs.length === 0, errs, name, description, budget, skill };
}

/**
 * Ensure a server project exists for this draft.
 * Returns projectId. Never clears the draft.
 */
export async function ensureProjectForDraft(draft: NewProjectDraft): Promise<string> {
  if (draft?.projectId) return draft.projectId as string;

  const v = validateDraftForCreate(draft ?? {});
  if (!v.ok) {
    const message = v.errs.join('\n');
    const e: any = new Error('VALIDATION_FAILED');
    e.userMessage = message;
    throw e;
  }

  // Build payload (with sanitized name; fallback if empty/invalid)
  let cleanName = sanitizeProjectName(v.name);
  if (!nameLooksValid(cleanName)) {
    const fallback = generateDefaultName(v.description);
    console.log('[project create] name sanitized to empty/invalid; using fallback', { fallback });
    cleanName = fallback;
  }
  
  // Include AR measurement data if present
  const measurement = draft?.measurement;
  const pxPerIn = measurement?.px_per_in ?? null;
  const dims = (measurement?.width_in != null && measurement?.height_in != null) 
    ? { width_in: measurement.width_in, height_in: measurement.height_in }
    : null;
  
  const payload: any = {
    name: cleanName,
    description: v.description.trim(),
    budget: v.budget,
    skill_level: v.skill,
  };
  
  if (pxPerIn != null) payload.scale_px_per_in = pxPerIn;
  if (dims != null) payload.dimensions_json = dims;
  
  console.log('[project create] payload', payload);
  console.log('[create] ar saved', { pxPerIn, dims: !!dims });

  // First attempt - use the helper that handles all response shapes
  let id: string;
  try {
    id = await createProjectAndReturnId(payload);
  } catch (err: any) {
    // If invalid_name (422), try one automatic repair with fresh fallback
    if (err.message?.includes('422') && /invalid[_\s-]?name/i.test(err.message)) {
      const repaired = generateDefaultName(v.description);
      if (repaired !== cleanName && nameLooksValid(repaired)) {
        console.log('[project create] retry with repaired name', { repaired });
        try {
          id = await createProjectAndReturnId({ ...payload, name: repaired });
          cleanName = repaired;
        } catch (retryErr: any) {
          console.log('[project create] retry failed', retryErr.message);
          const e: any = new Error('PROJECT_CREATE_FAILED');
          e.userMessage = retryErr.message || 'Project creation failed after retry';
          throw e;
        }
      } else {
        console.log('[project create] failed', err.message);
        const e: any = new Error('PROJECT_CREATE_FAILED');
        if (/invalid[_\s-]?name/i.test(err.message)) {
          e.userMessage = 'Project title has characters the server does not accept. Use letters, numbers, spaces, and -_. (3–60 chars).';
        } else {
          e.userMessage = err.message;
        }
        throw e;
      }
    } else {
      // Other errors - show the actual error message
      console.log('[project create] error', err.message);
      const e: any = new Error('PROJECT_CREATE_FAILED');
      e.userMessage = err.message || 'Project creation failed';
      throw e;
    }
  }

  // Persist sanitized name + id back into draft
  const nextDraft: NewProjectDraft = { ...(draft ?? {}), projectId: id, name: cleanName };
  await saveNewProjectDraft(nextDraft);
  console.log('[project create] success', { id, name: cleanName });
  return id;
}
