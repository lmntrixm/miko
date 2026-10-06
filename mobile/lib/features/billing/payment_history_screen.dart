import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/jalali.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/async_view.dart';
import '../../widgets/pressable.dart';
import 'billing_widgets.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final payments = ref.watch(paymentsProvider);
    final sub = ref.watch(subscriptionProvider).asData?.value;
    final plans = ref.watch(plansProvider).asData?.value ?? const <Plan>[];
    final plan = plans.where((p) => p.id == sub?.planId).firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          BillingHeader(title: 'تاریخچه پرداخت‌ها', onBack: () => context.canPop() ? context.pop() : context.go('/home')),
          Expanded(
            child: AsyncView<List<Payment>>(
              value: payments,
              onRetry: () => ref.invalidate(paymentsProvider),
              builder: (list) => ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                if (sub != null && sub.active)
                  Container(
                    padding: const EdgeInsets.all(MRSpacing.space4),
                    margin: const EdgeInsets.only(bottom: MRSpacing.space3),
                    decoration: BoxDecoration(color: c.red900, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.red800)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('اشتراک فعلی', style: MRText.caption.copyWith(color: c.red300)),
                          Text('${plan?.name ?? ''} · تا ${sub.endsAt == null ? '' : Jalali.fromDateTime(sub.endsAt!).format()}', style: MRText.h3.copyWith(color: c.textPrimary)),
                        ]),
                      ),
                      Pressable(
                        onTap: () => context.push('/manage-subscription'),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                          child: Center(widthFactor: 1, child: Text('مدیریت ›', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
                        ),
                      ),
                    ]),
                  ),
                if (list.isEmpty) Padding(padding: const EdgeInsets.all(MRSpacing.space6), child: Text('هنوز پرداختی ثبت نشده.', textAlign: TextAlign.center, style: MRText.body.copyWith(color: c.textMuted))),
                for (final p in list)
                  Container(
                    padding: const EdgeInsets.all(MRSpacing.space4),
                    margin: const EdgeInsets.only(bottom: MRSpacing.space3),
                    decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(child: Text(p.title, style: MRText.h3.copyWith(color: c.textPrimary))),
                        paymentBadge(p.status),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('$amountPlaceholder تومان', style: MRText.caption.copyWith(color: c.textMuted)),
                        const Spacer(),
                        Text(Jalali.fromDateTime(p.date).format(), style: MRText.caption.copyWith(color: c.textMuted)),
                      ]),
                      Row(children: [
                        Pressable(
                          onTap: () => showSnack(context, 'فاکتور به‌زودی در دسترس می‌شود'),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                            child: Center(widthFactor: 1, child: Text(p.status == PaymentStatus.failed ? 'پیگیری' : p.status == PaymentStatus.refunded ? 'جزئیات' : 'دریافت فاکتور', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
                          ),
                        ),
                        const Spacer(),
                        Text(p.trackingCode, textDirection: TextDirection.ltr, style: MRText.caption.copyWith(color: c.textMuted)),
                      ]),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
