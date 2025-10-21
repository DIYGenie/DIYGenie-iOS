import { Camera } from 'expo-camera';

export function useCameraPermission() {
  const checkStatus = async () => {
    const { status } = await Camera.getCameraPermissionsAsync();
    
    if (status === 'granted') {
      return 'granted';
    } else if (status === 'denied') {
      return 'denied';
    } else {
      return 'undetermined';
    }
  };

  const request = async () => {
    const { status } = await Camera.requestCameraPermissionsAsync();
    return status === 'granted' ? 'granted' : 'denied';
  };

  return {
    checkStatus,
    request,
  };
}
