import AsyncStorage from '@react-native-async-storage/async-storage';

const key = (id: string) => `plan-cache:${id}`;

export async function getCachedPlan(id: string) {
  try {
    const s = await AsyncStorage.getItem(key(id));
    return s ? JSON.parse(s) : null;
  } catch (e) {
    console.log('[planCache] getCachedPlan error', e);
    return null;
  }
}

export async function setCachedPlan(id: string, plan: any) {
  try {
    await AsyncStorage.setItem(key(id), JSON.stringify({ plan, ts: Date.now() }));
  } catch (e) {
    console.log('[planCache] setCachedPlan error', e);
  }
}
