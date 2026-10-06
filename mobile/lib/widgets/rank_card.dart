import 'package:flutter/material.dart';

import '../core/persian.dart';
import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'cover_placeholder.dart';
import 'pressable.dart';

/// "محبوب‌ترین‌ها" card: red card, cover breaking out of the top edge, big rank number.
class RankCard extends StatelessWidget {
  const RankCard({
    super.key,
    required this.rank,
    required this.title,
    required this.rating,
    required this.views,
    this.nextChapterIn,
    this.onTap,
  });

  final int rank;
  final String title;
  final double rating;
  final int views;
  final String? nextChapterIn;
  final VoidCallback? onTap;

  // Per design-system.md: lighter red than #D00000 is banned under small white text.
  static const _gradients = [
    [Color(0xFFD00000), Color(0xFFA00000)],
    [Color(0xFFB00000), Color(0xFF8E0000)],
    [Color(0xFF9E0000), Color(0xFF7A0000)],
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final g = _gradients[(rank - 1).clamp(0, 2)];
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 104 + 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 24,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: g),
                ),
                child: Row(
                  children: [
                    Text(
                      faDigits(rank),
                      style: MRText.h1.copyWith(
                        fontSize: 34,
                        color: c.onBrand,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: MRSpacing.space3),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MRText.h3.copyWith(color: c.onBrand),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: c.onBrand,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                faDigits(
                                  rating
                                      .toStringAsFixed(1)
                                      .replaceAll('.', '٫'),
                                ),
                                style: MRText.caption.copyWith(
                                  color: c.onBrand,
                                ),
                              ),
                              const SizedBox(width: MRSpacing.space3),
                              Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: c.onBrand,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                faCompact(views),
                                style: MRText.caption.copyWith(
                                  color: c.onBrand,
                                ),
                              ),
                            ],
                          ),
                          if (nextChapterIn != null)
                            Text(
                              nextChapterIn!,
                              style: MRText.caption.copyWith(color: c.onBrand),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 88),
                  ],
                ),
              ),
            ),
            const PositionedDirectional(
              end: 16,
              top: 0,
              child: CoverPlaceholder(width: 88, height: 128),
            ),
          ],
        ),
      ),
    );
  }
}
