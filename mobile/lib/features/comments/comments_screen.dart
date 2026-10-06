import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _text = TextEditingController();
  bool _spoiler = false;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    await ref
        .read(contentRepositoryProvider)
        .postComment(widget.chapterId, body, spoiler: _spoiler);
    ref.invalidate(commentsProvider(widget.chapterId));
    if (!mounted) return;
    _text.clear();
    setState(() {
      _sending = false;
      _spoiler = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final comments = ref.watch(commentsProvider(widget.chapterId));
    final sort = ref.watch(commentSortProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'نظرات',
              subtitle: comments.asData == null
                  ? ''
                  : '${faDigits(comments.asData!.value.length)} نظر',
            ),
            Divider(height: 1, color: c.border1),
            Expanded(
              child: AsyncView<List<Comment>>(
                value: comments,
                onRetry: () =>
                    ref.invalidate(commentsProvider(widget.chapterId)),
                builder: (list) => ListView(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  children: [
                    Row(
                      children: [
                        _SortChip(
                          'محبوب‌ترین',
                          sort == CommentSort.popular,
                          () => ref
                              .read(commentSortProvider.notifier)
                              .set(CommentSort.popular),
                        ),
                        const SizedBox(width: MRSpacing.space2),
                        _SortChip(
                          'جدیدترین',
                          sort == CommentSort.newest,
                          () => ref
                              .read(commentSortProvider.notifier)
                              .set(CommentSort.newest),
                        ),
                      ],
                    ),
                    const SizedBox(height: MRSpacing.space3),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(MRSpacing.space6),
                        child: Text(
                          'هنوز نظری نیست. اولین نفر باشید.',
                          textAlign: TextAlign.center,
                          style: MRText.body.copyWith(color: c.textMuted),
                        ),
                      ),
                    for (final cm in list)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: MRSpacing.space3,
                        ),
                        child: CommentCard(
                          comment: cm,
                          onLike: () async {
                            await ref
                                .read(contentRepositoryProvider)
                                .toggleLike(cm.id);
                            ref.invalidate(commentsProvider(widget.chapterId));
                          },
                          onReplies: () =>
                              context.push('/comment-thread/${cm.id}'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _Composer(
              controller: _text,
              hint: 'نظرت درباره این چپتر…',
              sending: _sending,
              onSend: _send,
              spoiler: _spoiler,
              onSpoiler: (v) => setState(() => _spoiler = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MRSpacing.space3,
        MRSpacing.space2,
        MRSpacing.space4,
        MRSpacing.space2,
      ),
      child: Row(
        children: [
          MikoIconButton(
            icon: Icons.arrow_forward,
            semanticLabel: 'بازگشت',
            filled: false,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: MRSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: MRText.h2.copyWith(color: c.textPrimary),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: MRText.caption.copyWith(color: c.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.red500 : c.surface2,
            borderRadius: BorderRadius.circular(MRRadius.radiusMd),
            border: selected ? null : Border.all(color: c.border2),
          ),
          child: Text(
            label,
            style: MRText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? c.onBrand : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// One comment with avatar, text (or spoiler cover), like and reply count.
class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.onLike,
    this.onReplies,
    this.nested = false,
  });
  final Comment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReplies;
  final bool nested;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final cm = widget.comment;
    final hideBody = cm.spoiler && !_revealed;
    final avatarColor = cm.isTeam
        ? c.red700
        : (cm.likedByMe && !widget.nested ? c.red800 : c.surface3);
    final highlighted = cm.likedByMe && !widget.nested || cm.isTeam;
    return Container(
      padding: const EdgeInsets.all(MRSpacing.space4),
      decoration: BoxDecoration(
        color: highlighted ? c.red900 : c.surface1,
        borderRadius: BorderRadius.circular(MRRadius.radiusLg),
        border: Border.all(color: highlighted ? c.red800 : c.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(MRRadius.radiusMd),
                ),
                child: Text(
                  cm.author.characters.first,
                  style: MRText.h3.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(width: MRSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cm.author,
                            overflow: TextOverflow.ellipsis,
                            style: MRText.h3.copyWith(color: c.textPrimary),
                          ),
                        ),
                        if (cm.isTeam) ...[
                          const SizedBox(width: MRSpacing.space2),
                          const MikoCountBadge('تیم ترجمه'),
                        ],
                      ],
                    ),
                    Text(
                      faRelative(cm.minutesAgo),
                      style: MRText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'گزارش نظر',
                child: GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.outlined_flag,
                      size: 20,
                      color: c.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MRSpacing.space3),
          if (hideBody)
            Semantics(
              button: true,
              label: 'این نظر حاوی اسپویل است، برای نمایش بزنید',
              child: GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.red900,
                    borderRadius: BorderRadius.circular(MRRadius.radiusMd),
                    border: Border.all(color: c.red800),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      'این نظر حاوی اسپویل است — برای نمایش بزنید',
                      style: MRText.caption.copyWith(color: c.red200),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(cm.body, style: MRText.body.copyWith(color: c.textPrimary)),
          const SizedBox(height: MRSpacing.space2),
          Row(
            children: [
              if (widget.onReplies != null)
                Pressable(
                  onTap: widget.onReplies,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'پاسخ (${faDigits(cm.replyCount)})',
                        style: MRText.caption.copyWith(
                          fontSize: 13,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Semantics(
                button: true,
                toggled: cm.likedByMe,
                label: 'پسندیدن، ${faDigits(cm.likes)} پسند',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onLike,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      minWidth: 44,
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            faDigits(cm.likes),
                            style: MRText.caption.copyWith(
                              fontSize: 13,
                              color: cm.likedByMe ? c.red400 : c.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            cm.likedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: cm.likedByMe ? c.red400 : c.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Input bar shared by comments and reply threads.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.sending,
    this.spoiler,
    this.onSpoiler,
    this.replyTo,
  });
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final bool sending;
  final bool? spoiler;
  final ValueChanged<bool>? onSpoiler;
  final String? replyTo;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Container(
      padding: EdgeInsets.fromLTRB(
        MRSpacing.space4,
        MRSpacing.space3,
        MRSpacing.space4,
        MRSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: c.bgNav,
        border: Border(top: BorderSide(color: c.border1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: MRSpacing.space2),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'در پاسخ به '),
                    TextSpan(
                      text: replyTo,
                      style: TextStyle(
                        color: c.red300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: MRText.caption.copyWith(color: c.textMuted),
              ),
            ),
          Row(
            children: [
              MikoIconButton(
                icon: Icons.send,
                semanticLabel: 'ارسال نظر',
                size: 48,
                onPressed: sending ? null : onSend,
              ),
              const SizedBox(width: MRSpacing.space3),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MRSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(MRRadius.radiusLg),
                    border: Border.all(color: c.border2),
                  ),
                  child: TextField(
                    controller: controller,
                    cursorColor: c.red400,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: MRText.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: MRText.body.copyWith(color: c.textHint),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (spoiler != null)
            Semantics(
              checked: spoiler,
              label: 'علامت‌گذاری به عنوان اسپویل',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSpoiler?.call(!spoiler!),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: spoiler! ? c.red500 : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: spoiler! ? c.red500 : c.switchOff,
                              width: 2,
                            ),
                          ),
                          child: spoiler!
                              ? Icon(Icons.check, size: 16, color: c.onBrand)
                              : null,
                        ),
                        const SizedBox(width: MRSpacing.space2),
                        Text(
                          'علامت‌گذاری به عنوان اسپویل',
                          style: MRText.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CommentThreadScreen extends ConsumerStatefulWidget {
  const CommentThreadScreen({super.key, required this.commentId});
  final String commentId;

  @override
  ConsumerState<CommentThreadScreen> createState() =>
      _CommentThreadScreenState();
}

class _CommentThreadScreenState extends ConsumerState<CommentThreadScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(Comment root) async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    await ref
        .read(contentRepositoryProvider)
        .postComment(root.chapterId, body, parentId: root.id);
    ref.invalidate(repliesProvider(root.id));
    ref.invalidate(commentProvider(root.id));
    if (!mounted) return;
    _text.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final root = ref.watch(commentProvider(widget.commentId));
    final replies = ref.watch(repliesProvider(widget.commentId));
    return Scaffold(
      body: SafeArea(
        child: AsyncView<Comment>(
          value: root,
          onRetry: () => ref.invalidate(commentProvider(widget.commentId)),
          builder: (r) => Column(
            children: [
              _Header(
                title: 'پاسخ‌ها',
                subtitle: '${faDigits(r.replyCount)} پاسخ',
              ),
              Divider(height: 1, color: c.border1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  children: [
                    CommentCard(
                      comment: r,
                      onLike: () async {
                        await ref
                            .read(contentRepositoryProvider)
                            .toggleLike(r.id);
                        ref.invalidate(commentProvider(r.id));
                      },
                    ),
                    const SizedBox(height: MRSpacing.space4),
                    replies.when(
                      data: (list) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: MRSpacing.space4,
                        ),
                        child: Column(
                          children: [
                            for (final rp in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: MRSpacing.space3,
                                ),
                                child: CommentCard(
                                  comment: rp,
                                  nested: true,
                                  onLike: () async {
                                    await ref
                                        .read(contentRepositoryProvider)
                                        .toggleLike(rp.id);
                                    ref.invalidate(repliesProvider(r.id));
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox(height: 40),
                      error: (_, _) => const SizedBox(),
                    ),
                  ],
                ),
              ),
              _Composer(
                controller: _text,
                hint: 'پاسخ شما…',
                replyTo: r.author,
                sending: _sending,
                onSend: () => _send(r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
