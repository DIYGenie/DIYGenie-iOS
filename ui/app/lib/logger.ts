import { IS_PROD } from './env';

export const log  = (...a:any[]) => { if (!IS_PROD) console.log(...a); };
export const warn = (...a:any[]) => { if (!IS_PROD) console.warn(...a); };
export const error= (...a:any[]) => console.error(...a);
