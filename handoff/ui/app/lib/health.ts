import { API_BASE, joinUrl } from './api';

export async function softHealthCheck(base = API_BASE) {
  try {
    const t0 = Date.now();
    let url = joinUrl(base, 'health/full');
    let res = await fetch(url);
    if (res.status === 404) {
      url = joinUrl(base, 'api/health/full');
      res = await fetch(url);
    }
    const ms = Date.now() - t0;
    if (!res.ok) {
      console.warn('[health] non-200', res.status);
      return { json: null, ms };
    }
    const json = await res.json();
    console.log('[health] ok', { modes: json?.modes, uptime_s: json?.uptime_s, ping: ms + 'ms' });
    return { json, ms };
  } catch (e) {
    console.warn('[health] failed', String(e));
    return { json: null, ms: 0 };
  }
}
