import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../widgets/miko_button.dart';

/// Placeholder until HomeTypes is built (next step).
class HomeStubScreen extends ConsumerWidget {
  const HomeStubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('خانه')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            const Text('صفحه خانه به‌زودی'),
            MikoButton(
              label: 'کامپوننت‌ها',
              kind: MikoButtonKind.secondary,
              onPressed: () => context.push('/gallery'),
            ),
            MikoButton(
              label: 'خروج از حساب',
              kind: MikoButtonKind.danger,
              onPressed: () async {
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) context.go('/auth-login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
