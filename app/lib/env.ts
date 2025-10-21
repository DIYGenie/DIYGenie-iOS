export const ENV = (process.env.EXPO_PUBLIC_ENV || 'dev') as 'dev'|'prod';
export const WEBHOOKS_BASE = process.env.EXPO_PUBLIC_BASE_URL!;
export const IS_PROD = ENV === 'prod';
