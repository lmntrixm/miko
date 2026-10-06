import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/account_repository.dart' show inviteBonusDays;
import '../../data/content_providers.dart';
import '../../data/downloads.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _modeLabel(ThemeMode m) => switch (m) {
        ThemeMode.dark => 'تیره',
        ThemeMode.light => 'روشن',
        ThemeMode.system => 'خودکار',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final profile = ref.watch(profileProvider);
    final sub = ref.watch(subscriptionProvider).asData?.value;
    final plans = ref.watch(plansProvider).asData?.value ?? const <Plan>[];
    final mode = ref.watch(themeModeProvider);
    final used = ref.watch(downloadsProvider).usedMb;
    final notif = ref.watch(notificationPrefsProvider);
    final followed = ref.watch(bookmarksProvider).length;

    return SafeArea(
      bottom: false,
      child: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(profileProvider),
        builder: (p) {
          final plan = plans.where((x) => x.id == sub?.planId).firstOrNull;
          return ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
            Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(gradient: mrBrandGradient, borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
                child: Icon(Icons.person_outline, size: 32, color: c.onBrand),
              ),
              const SizedBox(width: MRSpacing.space3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary)),
                  Directionality(textDirection: TextDirection.ltr, child: Text(p.email, style: MRText.caption.copyWith(color: c.textMuted))),
                ]),
              ),
              const SizedBox(width: MRSpacing.space3),
              MikoIconButton(icon: Icons.edit_outlined, semanticLabel: 'ویرایش پروفایل', onPressed: () => context.push('/edit-profile')),
            ]),
            const SizedBox(height: MRSpacing.space4),
            Container(
              padding: const EdgeInsets.all(MRSpacing.space4),
              decoration: BoxDecoration(gradient: mrCardGradient, borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
              child: sub != null && sub.active
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('اشتراک فعال', style: MRText.caption.copyWith(color: c.onBrand)),
                            Text('اشتراک ${plan?.name ?? ''}', style: MRText.h2.copyWith(color: c.onBrand)),
                          ]),
                        ),
                        Pressable(
                          onTap: () => context.push('/manage-subscription'),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44, minWidth: 80),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                            decoration: BoxDecoration(color: c.onBrand, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
                            child: Text('تمدید', style: MRText.h3.copyWith(color: MikoColors.light.red500)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: MRSpacing.space3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: plan == null ? 0.5 : (sub.daysLeft / plan.days).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: c.onBrand.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation(c.onBrand),
                        ),
                      ),
                      const SizedBox(height: MRSpacing.space2),
                      Text('${faDigits(sub.daysLeft)} روز از اشتراک شما باقی مانده است', style: MRText.caption.copyWith(color: c.onBrand)),
                    ])
                  : Row(children: [
                      Expanded(child: Text('اشتراک فعالی ندارید', style: MRText.h2.copyWith(color: c.onBrand))),
                      Pressable(
                        onTap: () => context.push('/subscription'),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44, minWidth: 80),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                          decoration: BoxDecoration(color: c.onBrand, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
                          child: Text('خرید اشتراک', style: MRText.h3.copyWith(color: MikoColors.light.red500)),
                        ),
                      ),
                    ]),
            ),
            const SizedBox(height: MRSpacing.space3),
            Row(children: [
              for (final (n, l) in [(p.chaptersRead, 'چپتر خوانده‌شده'), (followed, 'اثر دنبال‌شده'), (p.commentCount, 'نظر')])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: MRSpacing.space4),
                    decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                    child: Column(children: [
                      FittedBox(fit: BoxFit.scaleDown, child: Text(faNumber(n), style: MRText.h1.copyWith(fontSize: 24, color: c.textPrimary))),
                      Text(l, textAlign: TextAlign.center, maxLines: 2, style: MRText.caption.copyWith(color: c.textMuted)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: MRSpacing.space3),
            SectionCard(children: [
              MenuRow('زبان و ژانرهای مورد علاقه', value: 'فارسی', onTap: () => context.push('/onboarding-prefs?edit=1')),
              MenuRow('دعوت دوستان و کد هدیه', value: '${faDigits(inviteBonusDays)} روز رایگان', onTap: () => context.push('/invite')),
              MenuRow('تنظیمات اعلان‌ها', value: notif.newChapter || notif.reply || notif.subscription || notif.promo ? 'روشن' : 'خاموش', onTap: () => context.push('/notification-settings')),
              MenuRow('مدیریت دانلودها', value: faSize(used), onTap: () => context.push('/downloads')),
              MenuRow('ظاهر برنامه', value: _modeLabel(mode), onTap: () => _pickTheme(context, ref, mode)),
              MenuRow('تاریخچه پرداخت‌ها', onTap: () => context.push('/payment-history')),
              MenuRow('پشتیبانی و قوانین', onTap: () => context.push('/help-center')),
            ]),
            const SizedBox(height: MRSpacing.space4),
            MikoButton(label: 'خروج از حساب', kind: MikoButtonKind.danger, icon: Icons.logout, onPressed: () => _logout(context, ref)),
          ]);
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(context, title: 'خروج از حساب', body: 'دانلودهای این دستگاه می‌مانند. هر وقت خواستید دوباره وارد شوید.', confirm: 'خروج', destructive: true);
    if (!ok) return;
    await ref.read(sessionProvider.notifier).signOut();
    if (context.mounted) context.go('/auth-login');
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final c = context.mr;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MRRadius.radiusSheet))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MRSpacing.space5),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(header: true, child: Text('ظاهر برنامه', style: MRText.h2.copyWith(color: ctx.mr.textPrimary))),
            const SizedBox(height: MRSpacing.space3),
            for (final m in [ThemeMode.dark, ThemeMode.light, ThemeMode.system])
              Semantics(
                selected: m == current,
                inMutuallyExclusiveGroup: true,
                child: Pressable(
                  onTap: () {
                    ref.read(themeModeProvider.notifier).set(m);
                    Navigator.of(ctx).pop();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Row(children: [
                      Expanded(child: Text(_modeLabel(m), style: MRText.bodyLg.copyWith(color: ctx.mr.textPrimary))),
                      if (m == current) Icon(Icons.check, color: ctx.mr.red400),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
