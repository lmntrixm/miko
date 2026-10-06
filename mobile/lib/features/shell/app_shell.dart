import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/downloads.dart';
import '../../widgets/miko_tab_bar.dart';

/// Bottom-tab scaffold: profile · search · home · library · add (fixed visual order).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Snackbars are live regions, so screen readers announce "download finished".
    ref.listen(downloadsProvider.select((s) => s.justCompleted), (_, done) {
      if (done == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar(); // completion beats a stale "started" message
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'دانلود ${done.workNameFa} ${faDigits(done.number)} کامل شد',
          ),
        ),
      );
    });
    return Scaffold(
      body: shell,
      bottomNavigationBar: MikoTabBar(
        index: shell.currentIndex,
        // Tapping the active tab pops back to its root.
        onChanged: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
