export const brand = {
  primary: '#7C3AED',      // purple-600 - main DIY Genie brand color
  primary700: '#6D28D9',   // purple-700 - darker shade for gradients
  primary500: '#A78BFA',   // purple-400 - lighter shade
  primary300: '#C4B5FD',   // purple-300 - lightest shade for accents
  surface: '#FFFFFF',
  surfaceAlt: '#F6F6FA',
  text: '#101828',
  textMuted: '#667085',
  success: '#12B76A',
  danger:  '#EF4444',
  border:  '#E5E7EB',
};

export const colors = {
  // Gradient colors for background (matching colors.ts)
  gradientStart: '#C4B5FD', // Light Lavender (purple-300)
  gradientEnd: '#93C5FD',   // Soft Sky Blue
  
  // High-contrast UI surfaces
  bg: '#F1F5F9',        // slate-50 - page background under gradient fade
  surface: '#FFFFFF',    // white cards/sheets
  
  // Text colors
  textPrimary: '#0F172A',   // slate-900 - main headings/content
  textSecondary: '#475569', // slate-600 - secondary text
  
  // Interactive colors
  accent: brand.primary,     // Purple brand color
  accentPressed: brand.primary700, // Purple pressed state
  brandPurpleDeep: brand.primary700, // nav bars/background accents
  purpleLight: brand.primary300,     // inactive tab/icon tint
  
  // UI elements
  muted: '#E5E7EB',      // gray-200 - skeletons/dividers
  
  // Core colors
  white: '#FFFFFF',
  black: '#000000',
  ctaOrange: brand.primary,        // Aliased to purple brand
  ctaOrangePressed: brand.primary700, // Aliased to purple brand
  
  // Tab bar colors (updated for new design)
  tabActive: '#0F172A',
  tabInactive: '#64748B',
  tabBackground: 'rgba(255, 255, 255, 0.95)',
  
  // CTA colors
  brand: '#6E40FF',
  brand600: '#6E40FF',
  brand700: '#5A2EE8',
  brand50: '#F2ECFF',
  onBrand: '#FFFFFF',
  ctaShadow: 'rgba(110,64,255,0.28)',
  
  // Text ink colors
  ink900: '#111111',
  ink700: '#374151',
  ink600: '#4B5563',
  
  // DIY tile colors
  diy: {
    tileBg: '#F6F3FF',
    tileBorder: '#E7DFFF',
    tilePressed: '#EEE6FF',
  },
};