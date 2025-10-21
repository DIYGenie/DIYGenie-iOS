const APP_ENV = process.env.APP_ENV || 'development';

const isProd = APP_ENV === 'production';
const version = require('./package.json').version || '1.0.0';

const BASE_URL = process.env.EXPO_PUBLIC_BASE_URL || 'https://diy-genie-webhooks-tyekowalski.replit.app';

module.exports = {
  expo: {
    name: "DIY Genie",
    slug: "diy-genie",
    version,
    scheme: "diygenie",
    orientation: "portrait",
    userInterfaceStyle: "automatic",
    icon: "./assets/Icon.png",
    splash: {
      image: "./assets/splash.png",
      resizeMode: "contain",
      backgroundColor: "#8B5CF6"
    },
    assetBundlePatterns: [
      "**/*"
    ],
    ios: {
      supportsTablet: true,
      bundleIdentifier: "com.diygenie.app",
      buildNumber: version,
      icon: "./assets/Icon.png",
      splash: {
        image: "./assets/splash.png",
        resizeMode: "contain",
        backgroundColor: "#8B5CF6"
      },
      infoPlist: {
        NSCameraUsageDescription: "DIY Genie uses the camera to capture room photos for AI previews.",
        NSPhotoLibraryUsageDescription: "DIY Genie accesses photos you select for project previews.",
        NSPhotoLibraryAddUsageDescription: "DIY Genie saves preview images to your library when you choose.",
        UIRequiredDeviceCapabilities: ["arkit"]
      }
    },
    android: {
      package: "com.diygenie.app",
      versionCode: 1,
      adaptiveIcon: {
        foregroundImage: "./assets/adaptive-icon.png",
        backgroundColor: "#8B5CF6"
      },
      permissions: ["CAMERA", "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE"]
    },
    web: {
      bundler: "metro",
      favicon: "./assets/Icon.png"
    },
    updates: {
      url: "https://u.expo.dev",
      enabled: true,
      checkAutomatically: "ON_LOAD",
      fallbackToCacheTimeout: 0
    },
    runtimeVersion: {
      policy: "sdkVersion"
    },
    extra: {
      appEnv: APP_ENV,
      apiBase: BASE_URL,
      previewApiBase: BASE_URL,
    }
  }
};
