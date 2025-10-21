import { DeviceEventEmitter } from 'react-native';

export const SCAN_PHOTO_EVENT = 'scan-photo-selected';

export function emitScanPhoto(uri) {
  DeviceEventEmitter.emit(SCAN_PHOTO_EVENT, { uri });
}

export function subscribeScanPhoto(callback) {
  return DeviceEventEmitter.addListener(SCAN_PHOTO_EVENT, ({ uri }) => callback(uri));
}
