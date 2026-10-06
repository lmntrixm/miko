import 'package:flutter/material.dart';

import 'miko_tokens.dart';

/// Theme-aware Miko colors. Read with `context.mr`; never use raw hex in widgets.
@immutable
class MikoColors extends ThemeExtension<MikoColors> {
  const MikoColors({required this.red900, required this.red800, required this.red700, required this.red600, required this.red500, required this.red400, required this.red300, required this.red200, required this.bgBase, required this.bgNav, required this.bgPage, required this.surfaceSunken, required this.surface1, required this.surface2, required this.surface3, required this.border1, required this.border2, required this.switchOff, required this.textPrimary, required this.textSecondary, required this.textMuted, required this.textHint, required this.onBrand, required this.success, required this.successBg, required this.warning, required this.warningBg, required this.info, required this.infoBg, required this.danger, required this.dangerBg, required this.scrim});

  final Color red900;
  final Color red800;
  final Color red700;
  final Color red600;
  final Color red500;
  final Color red400;
  final Color red300;
  final Color red200;
  final Color bgBase;
  final Color bgNav;
  final Color bgPage;
  final Color surfaceSunken;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color border1;
  final Color border2;
  final Color switchOff;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textHint;
  final Color onBrand;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color info;
  final Color infoBg;
  final Color danger;
  final Color dangerBg;
  final Color scrim;

  static const dark = MikoColors(
      red900: MRDarkColors.red900,
      red800: MRDarkColors.red800,
      red700: MRDarkColors.red700,
      red600: MRDarkColors.red600,
      red500: MRDarkColors.red500,
      red400: MRDarkColors.red400,
      red300: MRDarkColors.red300,
      red200: MRDarkColors.red200,
      bgBase: MRDarkColors.bgBase,
      bgNav: MRDarkColors.bgNav,
      bgPage: MRDarkColors.bgPage,
      surfaceSunken: MRDarkColors.surfaceSunken,
      surface1: MRDarkColors.surface1,
      surface2: MRDarkColors.surface2,
      surface3: MRDarkColors.surface3,
      border1: MRDarkColors.border1,
      border2: MRDarkColors.border2,
      switchOff: MRDarkColors.switchOff,
      textPrimary: MRDarkColors.textPrimary,
      textSecondary: MRDarkColors.textSecondary,
      textMuted: MRDarkColors.textMuted,
      textHint: MRDarkColors.textHint,
      onBrand: MRDarkColors.onBrand,
      success: MRDarkColors.success,
      successBg: MRDarkColors.successBg,
      warning: MRDarkColors.warning,
      warningBg: MRDarkColors.warningBg,
      info: MRDarkColors.info,
      infoBg: MRDarkColors.infoBg,
      danger: MRDarkColors.danger,
      dangerBg: MRDarkColors.dangerBg,
      scrim: MRDarkColors.scrim,
  );

  static const light = MikoColors(
      red900: MRLightColors.red900,
      red800: MRLightColors.red800,
      red700: MRLightColors.red700,
      red600: MRLightColors.red600,
      red500: MRLightColors.red500,
      red400: MRLightColors.red400,
      red300: MRLightColors.red300,
      red200: MRLightColors.red200,
      bgBase: MRLightColors.bgBase,
      bgNav: MRLightColors.bgNav,
      bgPage: MRLightColors.bgPage,
      surfaceSunken: MRLightColors.surfaceSunken,
      surface1: MRLightColors.surface1,
      surface2: MRLightColors.surface2,
      surface3: MRLightColors.surface3,
      border1: MRLightColors.border1,
      border2: MRLightColors.border2,
      switchOff: MRLightColors.switchOff,
      textPrimary: MRLightColors.textPrimary,
      textSecondary: MRLightColors.textSecondary,
      textMuted: MRLightColors.textMuted,
      textHint: MRLightColors.textHint,
      onBrand: MRLightColors.onBrand,
      success: MRLightColors.success,
      successBg: MRLightColors.successBg,
      warning: MRLightColors.warning,
      warningBg: MRLightColors.warningBg,
      info: MRLightColors.info,
      infoBg: MRLightColors.infoBg,
      danger: MRLightColors.danger,
      dangerBg: MRLightColors.dangerBg,
      scrim: MRLightColors.scrim,
  );

  @override
  MikoColors copyWith({Color? red900, Color? red800, Color? red700, Color? red600, Color? red500, Color? red400, Color? red300, Color? red200, Color? bgBase, Color? bgNav, Color? bgPage, Color? surfaceSunken, Color? surface1, Color? surface2, Color? surface3, Color? border1, Color? border2, Color? switchOff, Color? textPrimary, Color? textSecondary, Color? textMuted, Color? textHint, Color? onBrand, Color? success, Color? successBg, Color? warning, Color? warningBg, Color? info, Color? infoBg, Color? danger, Color? dangerBg, Color? scrim}) => MikoColors(
      red900: red900 ?? this.red900,
      red800: red800 ?? this.red800,
      red700: red700 ?? this.red700,
      red600: red600 ?? this.red600,
      red500: red500 ?? this.red500,
      red400: red400 ?? this.red400,
      red300: red300 ?? this.red300,
      red200: red200 ?? this.red200,
      bgBase: bgBase ?? this.bgBase,
      bgNav: bgNav ?? this.bgNav,
      bgPage: bgPage ?? this.bgPage,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border1: border1 ?? this.border1,
      border2: border2 ?? this.border2,
      switchOff: switchOff ?? this.switchOff,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      onBrand: onBrand ?? this.onBrand,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      scrim: scrim ?? this.scrim,
  );

  @override
  MikoColors lerp(ThemeExtension<MikoColors>? other, double t) {
    if (other is! MikoColors) return this;
    return MikoColors(
      red900: Color.lerp(red900, other.red900, t)!,
      red800: Color.lerp(red800, other.red800, t)!,
      red700: Color.lerp(red700, other.red700, t)!,
      red600: Color.lerp(red600, other.red600, t)!,
      red500: Color.lerp(red500, other.red500, t)!,
      red400: Color.lerp(red400, other.red400, t)!,
      red300: Color.lerp(red300, other.red300, t)!,
      red200: Color.lerp(red200, other.red200, t)!,
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgNav: Color.lerp(bgNav, other.bgNav, t)!,
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border1: Color.lerp(border1, other.border1, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      switchOff: Color.lerp(switchOff, other.switchOff, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension MikoThemeContext on BuildContext {
  MikoColors get mr => Theme.of(this).extension<MikoColors>()!;
}
