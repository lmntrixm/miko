import 'package:flutter/material.dart';

import '../core/persian.dart';
import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'cover_placeholder.dart';
import 'pressable.dart';

enum ChapterState { unread, read, reading, locked }

/// One chapter in the title-detail list. Latin number/title, Persian date and counts.
class ChapterRow extends StatelessWidget {
  const ChapterRow({
    super.key,
    required this.number,
    required this.title,
    required this.dateLabel,
    this.commentCount = 0,
    this.state = ChapterState.unread,
    this.progress = 0,
    this.onTap,
  });

  final int number;
  final String title;
  final String dateLabel;
  final int commentCount;
  final ChapterState state;

  /// 0..1, shown only when [state] is [ChapterState.reading].
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final read = state == ChapterState.read;
    final borderColor = read ? c.switchOff : c.red600;
    return Opacity(
      opacity: read ? 0.7 : 1,
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'چپتر ${faDigits(number)}',
        child: Container(
          height: 104,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor, width: 2),
            color: c.surface1,
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  const SizedBox(width: MRSpacing.space4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$number',
                                style: MRText.h3.copyWith(color: c.textPrimary),
                              ),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MRText.caption.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          dateLabel,
                          style: MRText.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (state == ChapterState.locked)
                    Icon(Icons.lock_outline, size: 22, color: c.textMuted)
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          faDigits(commentCount),
                          style: MRText.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  const SizedBox(width: MRSpacing.space3),
                  const CoverPlaceholder(width: 130, height: 104, radius: 0),
                ],
              ),
              if (state == ChapterState.reading)
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0, 1),
                      child: Container(height: 3, color: c.red500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
