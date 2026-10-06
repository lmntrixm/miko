import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'pressable.dart';

enum MikoButtonKind { primary, hero, secondary, danger }

/// Action button. Only one primary/hero (filled red) per screen.
class MikoButton extends StatelessWidget {
  const MikoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = MikoButtonKind.primary,
    this.loading = false,
    this.loadingLabel,
    this.icon,
    this.height,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MikoButtonKind kind;
  final bool loading;

  /// Shown while [loading], e.g. «در حال ورود…».
  final String? loadingLabel;
  final IconData? icon;
  final double? height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final enabled = onPressed != null && !loading;
    final h = height ?? (kind == MikoButtonKind.hero ? 60 : 52);
    final radius = BorderRadius.circular(
        kind == MikoButtonKind.hero ? MRRadius.radius2xl : MRRadius.radiusLg);

    Color fg;
    Decoration deco;
    switch (kind) {
      case MikoButtonKind.primary:
      case MikoButtonKind.hero:
        fg = c.onBrand;
        deco = BoxDecoration(
          borderRadius: radius,
          gradient: enabled
              ? (kind == MikoButtonKind.hero ? mrHeroGradient : mrBrandGradient)
              : null,
          color: enabled ? null : c.surface3,
        );
      case MikoButtonKind.secondary:
        fg = c.textPrimary;
        deco = BoxDecoration(borderRadius: radius, color: c.surface2);
      case MikoButtonKind.danger:
        fg = c.danger;
        deco = BoxDecoration(
            borderRadius: radius, border: Border.all(color: c.red800));
    }
    if (!enabled && !loading) fg = c.textHint;

    final text = loading ? (loadingLabel ?? label) : label;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (loading || icon != null) const SizedBox(width: MRSpacing.space2),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: MRText.h3.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ),
      ],
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: Container(
        constraints: BoxConstraints(minHeight: h, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space5),
        decoration: deco,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

/// Icon-only button: 44×44 minimum and a mandatory Persian screen-reader label.
class MikoIconButton extends StatelessWidget {
  const MikoIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 44,
    this.filled = true,
  });
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      child: Container(
        width: size < 44 ? 44 : size,
        height: size < 44 ? 44 : size,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? c.surface3 : null,
            borderRadius: BorderRadius.circular(MRRadius.radiusMd),
          ),
          child: Icon(icon, size: 22, color: c.textPrimary),
        ),
      ),
    );
  }
}
