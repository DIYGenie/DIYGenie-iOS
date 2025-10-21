export type LastScan = { scanId: string; imageUrl: string | null };

let lastScanCache: LastScan | null = null;

export const setLastScan = (v: LastScan | null) => { 
  lastScanCache = v; 
};

export const getLastScan = () => lastScanCache;
