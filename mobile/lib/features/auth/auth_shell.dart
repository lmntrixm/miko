import 'package:flutter/material.dart';

import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/cover_placeholder.dart';

/// Tilted cover collage + scrim, shared by splash and every auth screen.
class CoverCollage extends StatelessWidget {
  const CoverCollage({super.key, this.scrim = 0.55});
  final double scrim;

  static const _left = [300.0, 300.0, 300.0], _right = [340.0, 260.0, 300.0];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    Widget col(List<double> hs) => Expanded(
      child: Column(
        children: [
          for (final h in hs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CoverPlaceholder(height: h, radius: 22),
            ),
        ],
      ),
    );
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.bgBase),
          Positioned(
            left: -20,
            right: -20,
            top: -20,
            child: Transform.rotate(
              angle: -0.07,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [col(_left), const SizedBox(width: 16), col(_right)],
              ),
            ),
          ),
          ColoredBox(color: c.bgBase.withValues(alpha: scrim)),
        ],
      ),
    );
  }
}

/// Glass card (radius-hero, red-600 outline) over the collage.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.leading});
  final Widget child;

  /// Optional top-start widget (e.g. back button).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CoverCollage(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
                      decoration: BoxDecoration(
                        color: c.bgPage.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(
                          MRRadius.radiusHero,
                        ),
                        border: Border.all(color: c.red600),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (leading != null)
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 4,
              start: 8,
              child: leading!,
            ),
        ],
      ),
    );
  }
}

/// Small text link used under auth forms.
class AuthLink extends StatelessWidget {
  const AuthLink(
    this.label, {
    super.key,
    required this.onTap,
    this.muted = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: MRText.caption.copyWith(
                fontSize: 13,
                color: muted ? c.textPrimary : c.red300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
