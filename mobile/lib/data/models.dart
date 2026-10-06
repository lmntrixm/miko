/// Domain models. "Work" = اثر (a manga, manhwa or comic series).
enum WorkType {
  manga('مانگا'),
  manhwa('مانهوا'),
  comic('کامیک');

  const WorkType(this.label);
  final String label;

  /// Reading direction comes from the work type (CLAUDE.md): manga RTL,
  /// comic LTR, manhwa (webtoon) vertical scroll.
  ReadMode get defaultMode => switch (this) {
    WorkType.manga => ReadMode.pagedRtl,
    WorkType.comic => ReadMode.pagedLtr,
    WorkType.manhwa => ReadMode.webtoon,
  };

  /// Persian word for one unit: چپتر / ایشو / قسمت.
  String get unit => switch (this) {
    WorkType.manga => 'چپتر',
    WorkType.comic => 'ایشو',
    WorkType.manhwa => 'قسمت',
  };
}

enum ReadMode { pagedRtl, pagedLtr, webtoon }

enum WorkStatus { ongoing, finished }

class Work {
  const Work({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.type,
    required this.description,
    required this.rating,
    required this.views,
    required this.genres,
    required this.author,
    required this.chapterCount,
    required this.updatedAt,
    this.status = WorkStatus.ongoing,
  });

  final String id;
  final String nameEn; // Latin, rendered LTR
  final String nameFa;
  final WorkType type;
  final String description;
  final double rating;
  final int views;
  final List<String> genres;
  final String author;
  final int chapterCount;
  final DateTime updatedAt;
  final WorkStatus status;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.workId,
    required this.number,
    required this.titleEn,
    required this.date,
    required this.pageCount,
    required this.commentCount,
  });

  final String id;
  final String workId;
  final int number;
  final String titleEn;
  final DateTime date;
  final int pageCount;
  final int commentCount;

  /// The first three chapters of every work are free.
  bool get isFree => number <= 3;
}

class ReadingProgress {
  const ReadingProgress({
    required this.workId,
    required this.chapterId,
    required this.chapterNumber,
    required this.page,
    required this.pageCount,
    required this.updatedAt,
    this.lang = 'fa',
  });
  final String workId, chapterId;
  final int chapterNumber, page, pageCount;
  final DateTime updatedAt;

  /// Reading language the user last used: fa / en / both.
  final String lang;
  double get fraction => pageCount == 0 ? 0 : (page + 1) / pageCount;
}

class Subscription {
  const Subscription({required this.active, this.daysLeft = 0});
  final bool active;
  final int daysLeft;
}

class Comment {
  const Comment({
    required this.id,
    required this.chapterId,
    required this.author,
    required this.body,
    required this.minutesAgo,
    this.likes = 0,
    this.replyCount = 0,
    this.spoiler = false,
    this.likedByMe = false,
    this.isTeam = false,
    this.parentId,
  });

  final String id, chapterId, author, body;
  final int minutesAgo, likes, replyCount;
  final bool spoiler, likedByMe, isTeam;
  final String? parentId;

  Comment copyWith({int? likes, int? replyCount, bool? likedByMe}) => Comment(
    id: id,
    chapterId: chapterId,
    author: author,
    body: body,
    minutesAgo: minutesAgo,
    likes: likes ?? this.likes,
    replyCount: replyCount ?? this.replyCount,
    spoiler: spoiler,
    likedByMe: likedByMe ?? this.likedByMe,
    isTeam: isTeam,
    parentId: parentId,
  );
}

enum CommentSort { popular, newest }

/// HTTP 402: chapter needs a subscription → Paywall.
class PaywallException implements Exception {
  const PaywallException();
}

/// HTTP 409: downloads are limited to 2 devices.
class DeviceLimitException implements Exception {
  const DeviceLimitException();
}

/// Chapter is not downloaded and there is no connection.
class OfflineException implements Exception {
  const OfflineException();
}
