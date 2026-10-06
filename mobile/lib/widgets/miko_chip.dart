import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'pressable.dart';

/// Selectable filter chip (genre, type, language).
class MikoChip extends StatelessWidget {
  const MikoChip({super.key, required this.label, this.selected = false, this.onTap, this.ltr = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Chapter-range chips (`#200 – #250`) use Latin digits, left-to-right.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.red500 : c.surface2,
              borderRadius: BorderRadius.circular(MRRadius.radiusMd),
              border: selected ? null : Border.all(color: c.border2),
            ),
            child: Text(label,
                textDirection: ltr ? TextDirection.ltr : null,
                style: TextStyle(
                  fontFamily: MRText.family,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.onBrand : c.textSecondary,
                )),
          ),
        ),
      ),
    );
  }
}

/// Segmented control (همه / مانگا / مانهوا / کامیک): active item has brand gradient.
class MikoSegmented extends StatelessWidget {
  const MikoSegmented({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(MRRadius.radiusLg),
      ),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == index,
              child: Pressable(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == index ? mrBrandGradient : null,
                    borderRadius: BorderRadius.circular(MRRadius.radiusMd),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                        fontFamily: MRText.family,
                        fontSize: 13,
                        fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                        color: i == index ? c.onBrand : c.textSecondary,
                      )),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
