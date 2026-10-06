import 'package:flutter/material.dart';

import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../core/persian.dart';

/// Stand-in for a scanned page until real (licensed) page images exist.
/// Always paper-white with ink borders, regardless of app theme (like a printed page).
class ReaderPagePlaceholder extends StatelessWidget {
  const ReaderPagePlaceholder({
    super.key,
    required this.page,
    required this.lang,
    this.borderless = false,
  });
  final int page; // 0-based
  final String lang; // FA / EN / FA · EN
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    const paper = MikoColors.light;
    Widget panel(String label, {int flex = 1}) => Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: paper.surface3,
          border: Border.all(color: paper.textPrimary, width: 2),
        ),
        child: Text(
          label,
          style: MRText.caption.copyWith(color: paper.textMuted),
        ),
      ),
    );
    const gap = SizedBox(width: 8, height: 8);
    final label = 'صفحه ${faDigits(page + 1)}';
    final layout = switch (page % 3) {
      0 => Column(
        children: [
          panel('$label · پنل ۱', flex: 2),
          gap,
          Expanded(
            flex: 3,
            child: Row(children: [panel('پنل ۲'), gap, panel('پنل ۳')]),
          ),
          gap,
          panel('پنل ۴', flex: 2),
        ],
      ),
      1 => Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [panel('$label · پنل ۱', flex: 2), gap, panel('پنل ۲')],
            ),
          ),
          gap,
          panel('پنل ۳', flex: 2),
        ],
      ),
      _ => Column(
        children: [
          panel('$label · پنل ۱', flex: 2),
          gap,
          panel('پنل ۲', flex: 2),
          gap,
          panel('پنل ۳'),
        ],
      ),
    };
    return Semantics(
      label: '$label، نسخه $lang',
      image: true,
      child: Container(
        color: paper.bgBase,
        padding: borderless ? EdgeInsets.zero : const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned.fill(child: layout),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: paper.textPrimary,
                child: Text(
                  lang,
                  textDirection: TextDirection.ltr,
                  style: MRText.label.copyWith(
                    fontSize: 10,
                    color: paper.bgBase,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
