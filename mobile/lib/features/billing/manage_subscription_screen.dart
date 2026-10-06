import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/jalali.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_switch.dart';
import '../../widgets/pressable.dart';
import 'billing_widgets.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final sub = ref.watch(subscriptionProvider);
    final plans = ref.watch(plansProvider).asData?.value ?? const <Plan>[];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          BillingHeader(title: 'مدیریت اشتراک', onBack: () => context.canPop() ? context.pop() : context.go('/home')),
          Expanded(
            child: AsyncView<Subscription>(
              value: sub,
              onRetry: () => ref.invalidate(subscriptionProvider),
              builder: (s) {
                if (!s.active) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MRSpacing.space6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('اشتراک فعالی ندارید', style: MRText.h2.copyWith(color: c.textPrimary)),
                        const SizedBox(height: MRSpacing.space2),
                        Text('با اشتراک همهٔ چپترها را بخوانید و دانلود کنید.', textAlign: TextAlign.center, style: MRText.body.copyWith(color: c.textMuted)),
                        const SizedBox(height: MRSpacing.space5),
                        MikoButton(label: 'خرید اشتراک', expand: false, onPressed: () => context.push('/subscription')),
                      ]),
                    ),
                  );
                }
                final plan = plans.where((p) => p.id == s.planId).firstOrNull;
                final end = s.endsAt == null ? '' : Jalali.fromDateTime(s.endsAt!).format();
                return ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                  Container(
                    padding: const EdgeInsets.all(MRSpacing.space5),
                    decoration: BoxDecoration(gradient: mrCardGradient, borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('طرح فعلی', style: MRText.caption.copyWith(color: c.onBrand)),
                      Text(plan?.name ?? '—', style: MRText.h1.copyWith(color: c.onBrand)),
                      const SizedBox(height: MRSpacing.space2),
                      Text(
                        s.autoRenew ? 'تمدید خودکار در $end · ${plan == null ? pricePlaceholder : priceText(plan)} تومان' : 'تا $end فعال است و تمدید نمی‌شود',
                        style: MRText.body.copyWith(color: c.onBrand),
                      ),
                    ]),
                  ),
                  const SizedBox(height: MRSpacing.space4),
                  Container(
                    decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: MRSpacing.space4, end: MRSpacing.space1, top: MRSpacing.space2, bottom: MRSpacing.space2),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('تمدید خودکار', style: MRText.bodyLg.copyWith(color: c.textPrimary)),
                              Text('از کارت ذخیره‌شده در درگاه', style: MRText.caption.copyWith(color: c.textMuted)),
                            ]),
                          ),
                          MikoSwitch(value: s.autoRenew, label: 'تمدید خودکار', onChanged: (v) => _toggle(context, ref, v, end)),
                        ]),
                      ),
                      Divider(height: 1, color: c.border1),
                      _Row('تغییر طرح', trailing: 'سالانه $pricePlaceholder ارزان‌تر', onTap: () => context.push('/subscription')),
                      Divider(height: 1, color: c.border1),
                      _Row('تاریخچه پرداخت‌ها', onTap: () => context.push('/payment-history')),
                    ]),
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on, String end) async {
    final repo = ref.read(contentRepositoryProvider);
    if (!on) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final c = ctx.mr;
          return Dialog(
            backgroundColor: c.surface1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
            child: Padding(
              padding: const EdgeInsets.all(MRSpacing.space5),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('تمدید خودکار خاموش شود؟', style: MRText.h2.copyWith(color: c.textPrimary)),
                const SizedBox(height: MRSpacing.space3),
                Text('تا $end به همهٔ چپترها دسترسی دارید.', style: MRText.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: MRSpacing.space5),
                MikoButton(label: 'خاموش کردن تمدید', kind: MikoButtonKind.danger, onPressed: () => Navigator.of(ctx).pop(true)),
                const SizedBox(height: MRSpacing.space2),
                MikoButton(label: 'نگه داشتن تمدید', kind: MikoButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
              ]),
            ),
          );
        },
      );
      if (ok != true) return;
    }
    await repo.setAutoRenew(on);
    ref.invalidate(subscriptionProvider);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.title, {this.trailing, required this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
          child: Row(children: [
            Expanded(child: Text(title, style: MRText.bodyLg.copyWith(color: c.textPrimary))),
            if (trailing != null) Text(trailing!, style: MRText.caption.copyWith(color: c.textMuted)),
          ]),
        ),
      ),
    );
  }
}
