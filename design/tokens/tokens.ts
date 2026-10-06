// Miko design tokens — generated from the design system (tokens.json)
// Usable in React Native (StyleSheet) and web. Font: Vazirmatn.

export const darkColors = {
  /** Tint behind tags, selected cards and unread notifications. */
  red900: '#2A0A0A',
  /** Quiet red borders: tag outline, dashed upload zone, danger outline button. */
  red800: '#5A1414',
  /** Gradient start; pressed state of primary buttons. */
  red700: '#8E0000',
  /** Outline of text fields and the auth card; chapter-row border. */
  red600: '#C8102E',
  /** Primary brand red: solid buttons, active tab, selected chip. White text on it passes 4.5:1. */
  red500: '#E00000',
  /** Active tab-bar icon, star rating, liked heart, unread dot. */
  red400: '#FF2D2D',
  /** Text links and text-only actions (بیشتر ›). */
  red300: '#FF4D4D',
  /** Text on red-900 tint (genre tags, spoiler warning). */
  red200: '#FF8A8A',
  /** Reader background and splash. */
  bgBase: '#0A0A0A',
  /** Bottom tab bar and admin sidebar. */
  bgNav: '#0E0E0E',
  /** Default page background in app and admin. */
  bgPage: '#121212',
  /** Admin inputs and inset panels inside cards. */
  surfaceSunken: '#141414',
  /** Cards, table containers, list items. */
  surface1: '#1A1A1A',
  /** Search field, unselected chips, secondary buttons. */
  surface2: '#1E1E1E',
  /** Icon buttons inside cards, hover of surface-2. */
  surface3: '#242424',
  /** Hairline dividers and card borders. */
  border1: '#262626',
  /** Borders of fields and chips. */
  border2: '#2E2E2E',
  /** Track of an off switch; unselected chapter-range pill. */
  switchOff: '#3A3A3A',
  /** Headings and body text on bg-page and surface-1. */
  textPrimary: '#F5F5F5',
  /** Subtitles, Persian title under an English title. */
  textSecondary: '#D4D4D4',
  /** Dates, counts, helper text. 7.6:1 on bg-page (dark). */
  textMuted: '#A3A3A3',
  /** Placeholders and disabled labels. Not for body copy. */
  textHint: '#8C8C8C',
  /** Text and icons on red-500 or the brand gradient. */
  onBrand: '#FFFFFF',
  /** Ongoing / active / paid status text. */
  success: '#4ADE80',
  /** Background of success badges. */
  successBg: '#0F2A1A',
  /** Pending / expiring status text. */
  warning: '#FACC15',
  /** Background of warning badges. */
  warningBg: '#2A220A',
  /** Completed series / informational status text. */
  info: '#60A5FA',
  /** Background of info badges. */
  infoBg: '#102235',
  /** Errors, banned users, destructive actions. */
  danger: '#FF6B6B',
  /** Background of danger badges and error banners. */
  dangerBg: '#2A0A0A',
  /** Overlay behind bottom sheets and dialogs. */
  scrim: 'rgba(0,0,0,0.72)',
} as const;

export const lightColors = {
  /** Tint behind tags, selected cards and unread notifications. */
  red900: '#FDECEC',
  /** Quiet red borders: tag outline, dashed upload zone, danger outline button. */
  red800: '#F5B8B8',
  /** Gradient start; pressed state of primary buttons. */
  red700: '#9E0000',
  /** Outline of text fields and the auth card; chapter-row border. */
  red600: '#C8102E',
  /** Primary brand red: solid buttons, active tab, selected chip. White text on it passes 4.5:1. */
  red500: '#D00000',
  /** Active tab-bar icon, star rating, liked heart, unread dot. */
  red400: '#D00000',
  /** Text links and text-only actions (بیشتر ›). */
  red300: '#B00000',
  /** Text on red-900 tint (genre tags, spoiler warning). */
  red200: '#9E0000',
  /** Reader background and splash. */
  bgBase: '#FFFFFF',
  /** Bottom tab bar and admin sidebar. */
  bgNav: '#FFFFFF',
  /** Default page background in app and admin. */
  bgPage: '#F6F4F4',
  /** Admin inputs and inset panels inside cards. */
  surfaceSunken: '#EFECEC',
  /** Cards, table containers, list items. */
  surface1: '#FFFFFF',
  /** Search field, unselected chips, secondary buttons. */
  surface2: '#F1EEEE',
  /** Icon buttons inside cards, hover of surface-2. */
  surface3: '#E7E3E3',
  /** Hairline dividers and card borders. */
  border1: '#E4E0E0',
  /** Borders of fields and chips. */
  border2: '#D6D0D0',
  /** Track of an off switch; unselected chapter-range pill. */
  switchOff: '#C9C3C3',
  /** Headings and body text on bg-page and surface-1. */
  textPrimary: '#1A1414',
  /** Subtitles, Persian title under an English title. */
  textSecondary: '#3D3535',
  /** Dates, counts, helper text. 7.6:1 on bg-page (dark). */
  textMuted: '#6B6262',
  /** Placeholders and disabled labels. Not for body copy. */
  textHint: '#7A7171',
  /** Text and icons on red-500 or the brand gradient. */
  onBrand: '#FFFFFF',
  /** Ongoing / active / paid status text. */
  success: '#15803D',
  /** Background of success badges. */
  successBg: '#DCFCE7',
  /** Pending / expiring status text. */
  warning: '#A16207',
  /** Background of warning badges. */
  warningBg: '#FEF3C7',
  /** Completed series / informational status text. */
  info: '#1D4ED8',
  /** Background of info badges. */
  infoBg: '#DBEAFE',
  /** Errors, banned users, destructive actions. */
  danger: '#B91C1C',
  /** Background of danger badges and error banners. */
  dangerBg: '#FEE2E2',
  /** Overlay behind bottom sheets and dialogs. */
  scrim: 'rgba(20,10,10,0.55)',
} as const;

export type ColorToken = keyof typeof darkColors;

export const spacing = {
  space1: 4,
  space2: 8,
  space3: 12,
  space4: 16,
  space5: 20,
  space6: 24,
  space7: 28,
  space8: 40,
  space9: 56,
} as const;

export const radius = {
  radiusXs: 8,
  radiusSm: 10,
  radiusMd: 14,
  radiusLg: 18,
  radiusXl: 22,
  radius2xl: 26,
  radiusSheet: 28,
  radiusHero: 42,
  radiusFull: 999,
} as const;

export const fontFamily = 'Vazirmatn';
export const typography = {
  display: { fontFamily, fontSize: 40, lineHeight: 52, fontWeight: '900' as const },
  h1: { fontFamily, fontSize: 26, lineHeight: 36, fontWeight: '900' as const },
  h2: { fontFamily, fontSize: 20, lineHeight: 28, fontWeight: '900' as const },
  h3: { fontFamily, fontSize: 16, lineHeight: 24, fontWeight: '900' as const },
  bodyLg: { fontFamily, fontSize: 15, lineHeight: 27, fontWeight: '500' as const },
  body: { fontFamily, fontSize: 14, lineHeight: 26, fontWeight: '400' as const },
  caption: { fontFamily, fontSize: 12, lineHeight: 20, fontWeight: '400' as const },
  label: { fontFamily, fontSize: 11, lineHeight: 16, fontWeight: '700' as const },
} as const;

export const motion = {
  fast: 100, base: 200, slow: 320,
  standard: [0.2, 0, 0, 1], emphasized: [0.2, 0.8, 0.2, 1], spring: [0.3, 1.6, 0.5, 1],
} as const;

export const gradients = {
  brand: ['#8E0000', '#E60000'],
  hero: ['#A00000', '#FF0000'],
  card: ['#6E0000', '#D00000'],
} as const;
