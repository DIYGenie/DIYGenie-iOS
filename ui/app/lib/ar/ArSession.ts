import { Platform } from 'react-native';

export type ArStartOpts = {
  projectId: string;
};

export function arSupported(): boolean {
  return Platform.OS === 'ios';
}

export async function startArSession(_opts: ArStartOpts): Promise<void> {
  return;
}

export async function stopArSession(): Promise<void> {
  return;
}
