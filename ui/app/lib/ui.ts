import { Platform, ToastAndroid } from 'react-native';

let bannerCb: ((msg: string) => void) | null = null;

export function simpleToast(msg: string) {
  if (Platform.OS === 'android') {
    ToastAndroid.show(msg, ToastAndroid.SHORT);
  } else {
    console.log('[toast]', msg);
  }
  bannerCb?.(msg);
}

export function _attachBanner(cb: (msg: string) => void) {
  bannerCb = cb;
}
