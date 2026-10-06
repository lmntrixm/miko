import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';

enum MikoBadgeKind { success, info, warning, danger, tag, language }

/// Small status/type label: 11px/700, always text on a matching background.
class MikoBadge extends StatelessWidget {
  const MikoBadge(this.label, {super.key, this.kind = MikoBadgeKind.tag});
  final String label;
  final MikoBadgeKind kind;

  /// Ongoing / finished / pending / blocked.
  const MikoBadge.status(this.label, {super.key, required this.kind});

  /// `FA · EN`, always LTR on surface-3.
  const MikoBadge.language({super.key})
      : label = 'FA · EN',
        kind = MikoBadgeKind.language;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final (Color fg, Color bg, Color? border) = switch (kind) {
      MikoBadgeKind.success => (c.success, c.successBg, null),
      MikoBadgeKind.info => (c.info, c.infoBg, null),
      MikoBadgeKind.warning => (c.warning, c.warningBg, null),
      MikoBadgeKind.danger => (c.danger, c.dangerBg, null),
      MikoBadgeKind.tag => (c.red200, c.red900, c.red800),
      MikoBadgeKind.language => (c.textSecondary, c.surface3, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MRRadius.radiusXs),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(label,
          textDirection: kind == MikoBadgeKind.language ? TextDirection.ltr : null,
          style: MRText.label.copyWith(color: fg)),
    );
  }
}

/// Menu counter: red-500 pill with Persian digits.
class MikoCountBadge extends StatelessWidget {
  const MikoCountBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: c.red500, borderRadius: BorderRadius.circular(MRRadius.radiusFull)),
      child: Text(text, style: MRText.label.copyWith(color: c.onBrand)),
    );
  }
}
