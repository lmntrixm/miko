import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/providers.dart';
import 'data/account_providers.dart';
import 'features/status/status_gate.dart';
import 'router.dart';
import 'theme/miko_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      // Errors are shown with an explicit retry button; no silent auto-retries.
      retry: (_, _) => null,
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MikoApp(),
    ),
  );
}

class MikoApp extends ConsumerWidget {
  const MikoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'میکو',
      debugShowCheckedModeBanner: false,
      theme: MikoTheme.light,
      darkTheme: MikoTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => StatusGate(
        onOpenDownloads: () => ref.read(routerProvider).go('/downloads'),
        child: child ?? const SizedBox(),
      ),
    );
  }
}
