// Miko design tokens — generated from the design system (tokens.json)
// NOTE: gradients run left→right (dark→bright) like the CSS 90deg in the design, not start→end.
// Font: Vazirmatn (add to pubspec via google_fonts or bundled assets).

import 'package:flutter/material.dart';

class MRDarkColors {
  MRDarkColors._();

  /// Tint behind tags, selected cards and unread notifications.
  static const red900 = Color(0xFF2A0A0A);

  /// Quiet red borders: tag outline, dashed upload zone, danger outline button.
  static const red800 = Color(0xFF5A1414);

  /// Gradient start; pressed state of primary buttons.
  static const red700 = Color(0xFF8E0000);

  /// Outline of text fields and the auth card; chapter-row border.
  static const red600 = Color(0xFFC8102E);

  /// Primary brand red: solid buttons, active tab, selected chip. White text on it passes 4.5:1.
  static const red500 = Color(0xFFE00000);

  /// Active tab-bar icon, star rating, liked heart, unread dot.
  static const red400 = Color(0xFFFF2D2D);

  /// Text links and text-only actions (بیشتر ›).
  static const red300 = Color(0xFFFF4D4D);

  /// Text on red-900 tint (genre tags, spoiler warning).
  static const red200 = Color(0xFFFF8A8A);

  /// Reader background and splash.
  static const bgBase = Color(0xFF0A0A0A);

  /// Bottom tab bar and admin sidebar.
  static const bgNav = Color(0xFF0E0E0E);

  /// Default page background in app and admin.
  static const bgPage = Color(0xFF121212);

  /// Admin inputs and inset panels inside cards.
  static const surfaceSunken = Color(0xFF141414);

  /// Cards, table containers, list items.
  static const surface1 = Color(0xFF1A1A1A);

  /// Search field, unselected chips, secondary buttons.
  static const surface2 = Color(0xFF1E1E1E);

  /// Icon buttons inside cards, hover of surface-2.
  static const surface3 = Color(0xFF242424);

  /// Hairline dividers and card borders.
  static const border1 = Color(0xFF262626);

  /// Borders of fields and chips.
  static const border2 = Color(0xFF2E2E2E);

  /// Track of an off switch; unselected chapter-range pill.
  static const switchOff = Color(0xFF3A3A3A);

  /// Headings and body text on bg-page and surface-1.
  static const textPrimary = Color(0xFFF5F5F5);

  /// Subtitles, Persian title under an English title.
  static const textSecondary = Color(0xFFD4D4D4);

  /// Dates, counts, helper text. 7.6:1 on bg-page (dark).
  static const textMuted = Color(0xFFA3A3A3);

  /// Placeholders and disabled labels. Not for body copy.
  static const textHint = Color(0xFF8C8C8C);

  /// Text and icons on red-500 or the brand gradient.
  static const onBrand = Color(0xFFFFFFFF);

  /// Ongoing / active / paid status text.
  static const success = Color(0xFF4ADE80);

  /// Background of success badges.
  static const successBg = Color(0xFF0F2A1A);

  /// Pending / expiring status text.
  static const warning = Color(0xFFFACC15);

  /// Background of warning badges.
  static const warningBg = Color(0xFF2A220A);

  /// Completed series / informational status text.
  static const info = Color(0xFF60A5FA);

  /// Background of info badges.
  static const infoBg = Color(0xFF102235);

  /// Errors, banned users, destructive actions.
  static const danger = Color(0xFFFF6B6B);

  /// Background of danger badges and error banners.
  static const dangerBg = Color(0xFF2A0A0A);

  /// Overlay behind bottom sheets and dialogs.
  static const scrim = Color.fromRGBO(0, 0, 0, 0.72);
}

class MRLightColors {
  MRLightColors._();

  /// Tint behind tags, selected cards and unread notifications.
  static const red900 = Color(0xFFFDECEC);

  /// Quiet red borders: tag outline, dashed upload zone, danger outline button.
  static const red800 = Color(0xFFF5B8B8);

  /// Gradient start; pressed state of primary buttons.
  static const red700 = Color(0xFF9E0000);

  /// Outline of text fields and the auth card; chapter-row border.
  static const red600 = Color(0xFFC8102E);

  /// Primary brand red: solid buttons, active tab, selected chip. White text on it passes 4.5:1.
  static const red500 = Color(0xFFD00000);

  /// Active tab-bar icon, star rating, liked heart, unread dot.
  static const red400 = Color(0xFFD00000);

  /// Text links and text-only actions (بیشتر ›).
  static const red300 = Color(0xFFB00000);

  /// Text on red-900 tint (genre tags, spoiler warning).
  static const red200 = Color(0xFF9E0000);

  /// Reader background and splash.
  static const bgBase = Color(0xFFFFFFFF);

  /// Bottom tab bar and admin sidebar.
  static const bgNav = Color(0xFFFFFFFF);

  /// Default page background in app and admin.
  static const bgPage = Color(0xFFF6F4F4);

  /// Admin inputs and inset panels inside cards.
  static const surfaceSunken = Color(0xFFEFECEC);

  /// Cards, table containers, list items.
  static const surface1 = Color(0xFFFFFFFF);

  /// Search field, unselected chips, secondary buttons.
  static const surface2 = Color(0xFFF1EEEE);

  /// Icon buttons inside cards, hover of surface-2.
  static const surface3 = Color(0xFFE7E3E3);

  /// Hairline dividers and card borders.
  static const border1 = Color(0xFFE4E0E0);

  /// Borders of fields and chips.
  static const border2 = Color(0xFFD6D0D0);

  /// Track of an off switch; unselected chapter-range pill.
  static const switchOff = Color(0xFFC9C3C3);

  /// Headings and body text on bg-page and surface-1.
  static const textPrimary = Color(0xFF1A1414);

  /// Subtitles, Persian title under an English title.
  static const textSecondary = Color(0xFF3D3535);

  /// Dates, counts, helper text. 7.6:1 on bg-page (dark).
  static const textMuted = Color(0xFF6B6262);

  /// Placeholders and disabled labels. Not for body copy.
  static const textHint = Color(0xFF7A7171);

  /// Text and icons on red-500 or the brand gradient.
  static const onBrand = Color(0xFFFFFFFF);

  /// Ongoing / active / paid status text.
  static const success = Color(0xFF15803D);

  /// Background of success badges.
  static const successBg = Color(0xFFDCFCE7);

  /// Pending / expiring status text.
  static const warning = Color(0xFFA16207);

  /// Background of warning badges.
  static const warningBg = Color(0xFFFEF3C7);

  /// Completed series / informational status text.
  static const info = Color(0xFF1D4ED8);

  /// Background of info badges.
  static const infoBg = Color(0xFFDBEAFE);

  /// Errors, banned users, destructive actions.
  static const danger = Color(0xFFB91C1C);

  /// Background of danger badges and error banners.
  static const dangerBg = Color(0xFFFEE2E2);

  /// Overlay behind bottom sheets and dialogs.
  static const scrim = Color.fromRGBO(20, 10, 10, 0.55);
}

class MRSpacing {
  MRSpacing._();
  static const double space1 = 4; // Icon-to-label gap, tight stacks.
  static const double space2 = 8; // Between chips and inline badges.
  static const double space3 = 12; // Between list cards.
  static const double space4 = 16; // Card padding.
  static const double space5 = 20; // Mobile page side margin.
  static const double space6 = 24; // Between sections on mobile.
  static const double space7 = 28; // Admin page margin.
  static const double space8 = 40; // Between large sections.
  static const double space9 = 56; // Header breathing room.
}

class MRRadius {
  MRRadius._();
  static const double radiusXs = 8; // Tags, badges, small pills.
  static const double radiusSm = 10; // Admin buttons and fields.
  static const double radiusMd = 14; // Icon buttons, covers.
  static const double radiusLg = 18; // List cards, admin panels.
  static const double radiusXl = 22; // Large cards, banners.
  static const double radius2xl = 26; // Auth fields and hero buttons.
  static const double radiusSheet = 28; // Top corners of bottom sheets.
  static const double radiusHero = 42; // Glass auth card.
  static const double radiusFull = 999; // Dots, avatars, switches.
}

class MRText {
  MRText._();
  static const family = 'Vazirmatn';
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 40,
    height: 1.30,
    fontWeight: FontWeight.w900,
  );
  static const h1 = TextStyle(
    fontFamily: family,
    fontSize: 26,
    height: 1.38,
    fontWeight: FontWeight.w900,
  );
  static const h2 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 1.40,
    fontWeight: FontWeight.w900,
  );
  static const h3 = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.50,
    fontWeight: FontWeight.w900,
  );
  static const bodyLg = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.80,
    fontWeight: FontWeight.w500,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 1.86,
    fontWeight: FontWeight.w400,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 1.67,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w700,
  );
}

class MRMotion {
  MRMotion._();
  static const fast = Duration(milliseconds: 100);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const standard = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static const spring = Cubic(0.3, 1.6, 0.5, 1);
}

const mrBrandGradient = LinearGradient(
  colors: [Color(0xFF8E0000), Color(0xFFE60000)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const mrHeroGradient = LinearGradient(
  colors: [Color(0xFFA00000), Color(0xFFFF0000)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Subscription card in profile / manage-subscription (design-system.md: defined in code).
const mrCardGradient = LinearGradient(colors: [Color(0xFF6E0000), Color(0xFFD00000)], begin: Alignment.centerLeft, end: Alignment.centerRight);
