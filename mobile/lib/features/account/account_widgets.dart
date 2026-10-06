import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';

/// Back arrow + title, shared by the account sub-screens.
class SubHeader extends StatelessWidget {
  const SubHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(MRSpacing.space3, MRSpacing.space2, MRSpacing.space4, MRSpacing.space2),
      child: Row(children: [
        MikoIconButton(icon: Icons.arrow_forward, semanticLabel: 'بازگشت', filled: false, onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        Expanded(child: Semantics(header: true, child: Text(title, style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary)))),
        ?trailing,
      ]),
    );
  }
}

/// Rounded surface used for grouped rows.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.padding = EdgeInsets.zero});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && padding == EdgeInsets.zero) Divider(height: 1, color: c.border1),
          children[i],
        ],
      ]),
    );
  }
}

/// A tappable row with an optional value and a chevron pointing at the end.
class MenuRow extends StatelessWidget {
  const MenuRow(this.title, {super.key, this.value, required this.onTap});
  final String title;
  final String? value;
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
            if (value != null) ...[Text(value!, style: MRText.caption.copyWith(color: c.textMuted)), const SizedBox(width: MRSpacing.space2)],
            Icon(Icons.chevron_left, size: 22, color: c.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Confirmation dialog in the app's style. Returns true when confirmed.
Future<bool> confirmDialog(BuildContext context, {required String title, required String body, required String confirm, bool destructive = false, String cancel = 'انصراف'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.mr;
      return Dialog(
        backgroundColor: c.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
        child: Padding(
          padding: const EdgeInsets.all(MRSpacing.space5),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(header: true, child: Text(title, style: MRText.h2.copyWith(color: c.textPrimary))),
            const SizedBox(height: MRSpacing.space3),
            Text(body, style: MRText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: MRSpacing.space5),
            MikoButton(label: confirm, kind: destructive ? MikoButtonKind.danger : MikoButtonKind.primary, onPressed: () => Navigator.of(ctx).pop(true)),
            const SizedBox(height: MRSpacing.space2),
            MikoButton(label: cancel, kind: MikoButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
          ]),
        ),
      );
    },
  );
  return r ?? false;
}
