import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/miko_tab_bar.dart';

/// Bottom-tab scaffold: profile · search · home · library · add (fixed visual order).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: MikoTabBar(
        index: shell.currentIndex,
        // Tapping the active tab pops back to its root.
        onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
