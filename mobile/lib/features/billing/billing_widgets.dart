import 'package:flutter/material.dart';

import '../../core/persian.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';

String priceText(Plan p) => p.priceToman == null ? pricePlaceholder : faNumber(p.priceToman!);

/// Plan name + price card used on the paywall (compact, 3 across).
class PlanTile extends StatelessWidget {
  const PlanTile({super.key, required this.plan, required this.selected, required this.onTap});
  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${plan.name}، ${priceText(plan)}',
      child: Pressable(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.red900 : c.surface1,
              borderRadius: BorderRadius.circular(MRRadius.radiusLg),
              border: Border.all(color: selected ? c.red600 : c.border2, width: selected ? 2 : 1),
            ),
            child: ExcludeSemantics(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(plan.name, style: MRText.h3.copyWith(fontSize: 15, color: c.textPrimary)),
                Text(priceText(plan), style: MRText.caption.copyWith(color: c.textMuted)),
              ]),
            ),
          ),
          if (plan.popular)
            PositionedDirectional(
              top: -9,
              start: 0,
              end: 0,
              child: Center(child: ExcludeSemantics(child: MikoCountBadge('محبوب'))),
            ),
        ]),
      ),
    );
  }
}

/// Radio-style plan row on the subscription screen.
class PlanRow extends StatelessWidget {
  const PlanRow({super.key, required this.plan, required this.selected, required this.onTap});
  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${plan.name}، ${priceText(plan)} تومان، ${plan.note}',
      child: Pressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(MRSpacing.space4),
            decoration: BoxDecoration(
              color: selected ? c.red900 : c.surface1,
              borderRadius: BorderRadius.circular(MRRadius.radiusLg),
              border: Border.all(color: selected ? c.red600 : c.border1, width: selected ? 2 : 1),
            ),
            child: Row(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.red500 : c.switchOff, width: 2)),
                child: selected ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.red500, shape: BoxShape.circle))) : null,
              ),
              const SizedBox(width: MRSpacing.space3),
              Text('${priceText(plan)} تومان', style: MRText.h3.copyWith(color: c.textPrimary)),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (plan.popular) ...[const MikoCountBadge('محبوب'), const SizedBox(width: MRSpacing.space2)],
                  Text(plan.name, style: MRText.h3.copyWith(fontSize: 17, color: c.textPrimary)),
                ]),
                Text(plan.note, style: MRText.caption.copyWith(color: c.textMuted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Header with a back arrow, shared by the billing sub-screens.
class BillingHeader extends StatelessWidget {
  const BillingHeader({super.key, required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(MRSpacing.space3, MRSpacing.space2, MRSpacing.space4, MRSpacing.space2),
      child: Row(children: [
        MikoIconButton(icon: Icons.arrow_forward, semanticLabel: 'بازگشت', filled: false, onPressed: onBack),
        Expanded(child: Semantics(header: true, child: Text(title, style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary)))),
      ]),
    );
  }
}

/// Key/value line inside receipt cards. [ltr] for tracking codes.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.ltr = false});
  final String label, value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: MRText.body.copyWith(color: c.textMuted)),
        const Spacer(),
        Text(value, textDirection: ltr ? TextDirection.ltr : null, style: MRText.body.copyWith(color: c.textPrimary)),
      ]),
    );
  }
}

MikoBadge paymentBadge(PaymentStatus s) => switch (s) {
      PaymentStatus.success => const MikoBadge.status('موفق', kind: MikoBadgeKind.success),
      PaymentStatus.failed => const MikoBadge.status('ناموفق', kind: MikoBadgeKind.danger),
      PaymentStatus.refunded => const MikoBadge.status('برگشت داده شد', kind: MikoBadgeKind.info),
      PaymentStatus.pending => const MikoBadge.status('در انتظار', kind: MikoBadgeKind.warning),
    };
