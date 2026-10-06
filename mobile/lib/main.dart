import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/gallery/gallery_screen.dart';
import 'theme/miko_theme.dart';

void main() => runApp(const MikoApp());

class MikoApp extends StatefulWidget {
  const MikoApp({super.key});

  @override
  State<MikoApp> createState() => _MikoAppState();
}

class _MikoAppState extends State<MikoApp> {
  // Dark is the default theme.
  ThemeMode _mode = ThemeMode.dark;

  void _toggle() => setState(
      () => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'میکو',
      debugShowCheckedModeBanner: false,
      theme: MikoTheme.light,
      darkTheme: MikoTheme.dark,
      themeMode: _mode,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: GalleryScreen(onToggleTheme: _toggle),
    );
  }
}
