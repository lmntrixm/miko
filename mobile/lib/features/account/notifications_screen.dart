import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/account_repository.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAll(WidgetRef ref) async {
    await ref.read(accountRepositoryProvider).markNotificationsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _open(BuildContext context, WidgetRef ref, NotificationItem n) async {
    await ref.read(accountRepositoryProvider).markNotificationsRead(id: n.id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    if (!context.mounted) return;
    switch (n.kind) {
      case NotifKind.newChapter:
        if (n.chapterId != null) context.push('/reader/${n.chapterId}');
      case NotifKind.subscription:
        context.push('/manage-subscription');
      case NotifKind.reply:
        if (n.chapterId != null) context.push('/comments/${n.chapterId}');
      case NotifKind.requestAdded:
        context.go('/library');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          SubHeader(
            title: 'اعلان‌ها',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Pressable(
                onTap: () => _markAll(ref),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: Center(widthFactor: 1, child: Text('همه خوانده شد', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
                ),
              ),
              MikoIconButton(icon: Icons.settings_outlined, semanticLabel: 'تنظیمات اعلان‌ها', filled: false, onPressed: () => context.push('/notification-settings')),
            ]),
          ),
          Expanded(
            child: AsyncView<List<NotificationItem>>(
              value: list,
              onRetry: () => ref.invalidate(notificationsProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return Center(child: Text('اعلان تازه‌ای ندارید', style: MRText.body.copyWith(color: c.textMuted)));
                }
                final today = items.where((n) => n.isToday).toList();
                final week = items.where((n) => !n.isToday).toList();
                Widget group(String title, List<NotificationItem> g) => g.isEmpty
                    ? const SizedBox()
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Padding(
                          padding: const EdgeInsets.only(top: MRSpacing.space3, bottom: MRSpacing.space2),
                          child: Semantics(header: true, child: Text(title, style: MRText.h3.copyWith(fontSize: 14, color: c.textMuted))),
                        ),
                        for (final n in g) Padding(padding: const EdgeInsets.only(bottom: MRSpacing.space3), child: _NotificationCard(item: n, onTap: () => _open(context, ref, n))),
                      ]);
                return ListView(padding: const EdgeInsets.fromLTRB(MRSpacing.space4, 0, MRSpacing.space4, MRSpacing.space6), children: [group('امروز', today), group('این هفته', week)]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final unread = !item.read;
    final Widget leading = switch (item.kind) {
      NotifKind.newChapter || NotifKind.requestAdded => const CoverPlaceholder(width: 56, height: 72, radius: 12),
      NotifKind.subscription => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(gradient: mrBrandGradient, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
          child: Icon(Icons.credit_card, color: c.onBrand),
        ),
      NotifKind.reply => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
          child: Icon(Icons.chat_bubble_outline, color: c.red400),
        ),
    };
    return Semantics(
      label: '${unread ? 'خوانده‌نشده، ' : ''}${item.title}. ${item.body}',
      button: true,
      child: Pressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(MRSpacing.space3),
            decoration: BoxDecoration(color: unread ? c.red900 : c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: unread ? c.red800 : c.border1)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: MRText.h3.copyWith(color: c.textPrimary)),
                  Text(item.body, style: MRText.caption.copyWith(color: c.textSecondary)),
                  Text(faRelative(item.minutesAgo), style: MRText.caption.copyWith(color: c.textMuted)),
                ]),
              ),
              const SizedBox(width: MRSpacing.space3),
              leading,
              if (unread) Container(width: 9, height: 9, margin: const EdgeInsetsDirectional.only(start: MRSpacing.space3), decoration: BoxDecoration(color: c.red400, shape: BoxShape.circle)),
            ]),
          ),
        ),
      ),
    );
  }
}
