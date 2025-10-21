import * as FileSystem from 'expo-file-system/legacy';
import * as MediaLibrary from 'expo-media-library';
import { Platform } from 'react-native';

export async function saveImageToPhotos(uri: string): Promise<{ success: boolean; message: string }> {
  try {
    const { status } = await MediaLibrary.requestPermissionsAsync();
    
    if (status !== 'granted') {
      return { 
        success: false, 
        message: 'Permission to access media library is required to save images.' 
      };
    }

    const filename = `diy-genie-preview-${Date.now()}.jpg`;
    const fileUri = (FileSystem.documentDirectory || FileSystem.cacheDirectory) + filename;

    const downloadResult = await FileSystem.downloadAsync(uri, fileUri);
    
    if (downloadResult.status !== 200) {
      return { 
        success: false, 
        message: 'Failed to download image.' 
      };
    }

    const asset = await MediaLibrary.createAssetAsync(downloadResult.uri);
    
    let album = await MediaLibrary.getAlbumAsync('DIY Genie');
    
    if (album === null) {
      album = await MediaLibrary.createAlbumAsync('DIY Genie', asset, false);
    } else {
      await MediaLibrary.addAssetsToAlbumAsync([asset], album, false);
    }

    return { 
      success: true, 
      message: 'Preview saved to Photos in "DIY Genie" album!' 
    };
  } catch (error) {
    console.error('[saveImageToPhotos]', error);
    return { 
      success: false, 
      message: 'Failed to save image. Please try again.' 
    };
  }
}
