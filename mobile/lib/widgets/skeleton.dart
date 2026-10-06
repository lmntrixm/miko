import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';

/// Shimmering block (1400ms linear). Static when the system asks to reduce motion.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = MRRadius.radiusLg});
  final double? width;
  final double height, radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctl.stop();
    } else if (!_ctl.isAnimating) {
      _ctl.repeat();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [c.surface1, c.surface3, c.surface1],
            stops: [(_ctl.value - 0.3).clamp(0.0, 1.0), _ctl.value, (_ctl.value + 0.3).clamp(0.0, 1.0)],
          ),
        ),
      ),
    );
  }
}

/// Generic page skeleton, shown only if loading takes longer than 300ms (flows.md).
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> {
  bool _show = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 300), () => mounted ? setState(() => _show = true) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // Inside a ListView the height is unbounded: give the placeholder a fixed one.
      final h = box.hasBoundedHeight ? box.maxHeight : 360.0;
      if (!_show) return SizedBox(height: h);
      return SizedBox(height: h, child: ClipRect(child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: _body())));
    });
  }

  Widget _body() {
    return Semantics(
      label: 'در حال بارگذاری',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(MRSpacing.space5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Row(children: [
              Skeleton(width: 56, height: 56, radius: MRRadius.radiusMd),
              SizedBox(width: MRSpacing.space3),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton(width: 160, height: 14), SizedBox(height: 8), Skeleton(width: 220, height: 12)])),
            ]),
            const SizedBox(height: MRSpacing.space5),
            const Skeleton(height: 190, radius: MRRadius.radiusXl),
            const SizedBox(height: MRSpacing.space5),
            for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: MRSpacing.space3), child: Skeleton(height: 90)),
          ]),
        ),
      ),
    );
  }
}
