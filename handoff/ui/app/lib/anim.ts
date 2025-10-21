import { Platform, UIManager, LayoutAnimation } from 'react-native';

let enabled = false;
export function enableLayoutAnimOnce() {
  if (!enabled && Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
    UIManager.setLayoutAnimationEnabledExperimental(true);
    enabled = true;
  }
}

export function sectionEase(duration = 180) {
  const preset = {
    duration,
    create:  { type: LayoutAnimation.Types.easeInEaseOut, property: LayoutAnimation.Properties.opacity },
    update:  { type: LayoutAnimation.Types.easeInEaseOut },
    delete:  { type: LayoutAnimation.Types.easeInEaseOut, property: LayoutAnimation.Properties.opacity },
  };
  return LayoutAnimation.create(
    preset.duration,
    LayoutAnimation.Types.easeInEaseOut,
    LayoutAnimation.Properties.opacity
  ) || preset;
}

export function animateSection(duration = 180) {
  LayoutAnimation.configureNext(sectionEase(duration));
}
