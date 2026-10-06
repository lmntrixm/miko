import 'package:flutter/material.dart';

import 'miko_colors.dart';
import 'miko_tokens.dart';

abstract final class MikoTheme {
  static ThemeData get dark => _build(MikoColors.dark, Brightness.dark);
  static ThemeData get light => _build(MikoColors.light, Brightness.light);

  static ThemeData _build(MikoColors c, Brightness b) {
    TextStyle t(TextStyle s, Color color) => s.copyWith(color: color);
    final textTheme = TextTheme(
      displayLarge: t(MRText.display, c.textPrimary),
      headlineMedium: t(MRText.h1, c.textPrimary),
      titleLarge: t(MRText.h2, c.textPrimary),
      titleMedium: t(MRText.h3, c.textPrimary),
      bodyLarge: t(MRText.bodyLg, c.textPrimary),
      bodyMedium: t(MRText.body, c.textPrimary),
      bodySmall: t(MRText.caption, c.textMuted),
      labelSmall: t(MRText.label, c.textMuted),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: MRText.family,
      scaffoldBackgroundColor: c.bgPage,
      canvasColor: c.bgPage,
      dividerColor: c.border1,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: b,
        primary: c.red500,
        onPrimary: c.onBrand,
        secondary: c.red400,
        onSecondary: c.onBrand,
        error: c.danger,
        onError: c.onBrand,
        surface: c.surface1,
        onSurface: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgPage,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface3,
        contentTextStyle: MRText.body.copyWith(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MRRadius.radiusLg),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      extensions: [c],
    );
  }
}
