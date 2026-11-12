import type { ExpoConfig } from 'expo/config';

// Native folders (ios/, android/) are generated (Expo CNG) and never committed;
// all native configuration goes through this file and config plugins. See docs/adr/0004.
const config: ExpoConfig = {
  name: 'Hype2gether',
  slug: 'hype2gether',
  scheme: 'hype2gether',
  version: '0.1.0',
  orientation: 'portrait',
  userInterfaceStyle: 'automatic',
  ios: {
    supportsTablet: false,
    // bundleIdentifier: decided by the team before the first EAS build.
  },
  plugins: ['expo-router', 'expo-status-bar'],
  experiments: {
    typedRoutes: true,
  },
};

export default config;
