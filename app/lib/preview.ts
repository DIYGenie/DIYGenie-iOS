import { Alert, Platform } from 'react-native';
import * as FileSystem from 'expo-file-system/legacy';
import * as MediaLibrary from 'expo-media-library';

export async function saveRemoteImageToPhotos(url: string) {
  try {
    if (!url) throw new Error('missing_url');

    const perm = await MediaLibrary.requestPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Please allow Photos/Media access to save the preview.');
      return;
    }

    const ext = url.split('?')[0].split('.').pop()?.toLowerCase();
    const filename = `preview-${Date.now()}.${ext && ext.length <= 4 ? ext : 'jpg'}`;
    const tmpPath = (FileSystem.cacheDirectory || FileSystem.documentDirectory) + filename;

    const dl = await FileSystem.downloadAsync(url, tmpPath);
    if (dl.status !== 200) throw new Error(`download_status_${dl.status}`);

    const asset = await MediaLibrary.createAssetAsync(dl.uri);

    // Try to add to a "DIY Genie" album (best-effort)
    let album = await MediaLibrary.getAlbumAsync('DIY Genie');
    if (!album) {
      album = await MediaLibrary.createAlbumAsync('DIY Genie', asset, false);
    } else {
      await MediaLibrary.addAssetsToAlbumAsync([asset], album, false);
    }

    Alert.alert('Saved', Platform.OS === 'ios'
      ? 'Preview saved to your Photos.'
      : 'Preview saved to your device gallery.');
  } catch (e: any) {
    console.log('[preview save error]', e?.message || String(e));
    Alert.alert('Save failed', 'Could not save the preview. Please try again.');
  }
}
