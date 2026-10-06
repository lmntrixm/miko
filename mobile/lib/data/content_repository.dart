import 'models.dart';

/// Catalogue, reading and comments API (docs/api.md). Swap the mock for the real one later.
abstract class ContentRepository {
  Future<String> userName();
  Future<Subscription> subscription();
  Future<List<Work>> works({WorkType? type});
  Future<Work> work(String id);
  Future<List<Chapter>> chapters(String workId);

  /// Throws [PaywallException] when the chapter is locked for this user.
  Future<Chapter> openChapter(String chapterId);
  Future<ReadingProgress?> lastProgress();

  /// One entry per work, most recent first.
  Future<List<ReadingProgress>> readingList();
  Future<void> saveProgress(ReadingProgress p);

  Future<List<Comment>> comments(String chapterId, CommentSort sort);
  Future<Comment> comment(String id);
  Future<List<Comment>> replies(String commentId);
  Future<void> postComment(
    String chapterId,
    String body, {
    bool spoiler = false,
    String? parentId,
  });
  Future<void> toggleLike(String commentId);

  /// Registers this device for downloads. Throws [DeviceLimitException] (409) past 2 devices.
  Future<void> registerDownloadDevice();
}

/// In-memory fake with invented titles (never real works: copyright).
class MockContentRepository implements ContentRepository {
  MockContentRepository({
    this.subscribed = true,
    this.latency = const Duration(milliseconds: 250),
    bool seedProgress = true,
    this.deviceLimitReached = false,
  }) {
    _comments.addAll(_seedComments());
    if (seedProgress) _seedProgressList();
  }

  bool subscribed;
  bool deviceLimitReached;
  final Duration latency;
  final _progress = <String, ReadingProgress>{};
  final _comments = <Comment>[];
  var _nextId = 100;

  static final _anchor = DateTime(2026, 9, 28);

  static final _works = <Work>[
    Work(
      id: 'dawn-blade',
      nameEn: 'Dawn Blade',
      nameFa: 'شمشیر سپیده',
      type: WorkType.manga,
      description:
          'جنگجویی جوان در سرزمینی که خورشید دیگر طلوع نمی‌کند، شمشیری را پیدا می‌کند که سپیده را با خود دارد. '
          'داستان ماجرای او و هم‌سفرانش برای بازگرداندن روز است.',
      rating: 4.8,
      views: 124000,
      genres: const ['اکشن', 'فانتزی'],
      author: 'نویسنده نمونه',
      chapterCount: 242,
      updatedAt: _anchor,
    ),
    Work(
      id: 'silent-gate',
      nameEn: 'Silent Gate',
      nameFa: 'دروازهٔ خاموش',
      type: WorkType.manga,
      description: 'دروازه‌ای در قلب شهر باز شده و هر کس از آن عبور کند چیزی از یادش می‌رود.',
      rating: 4.6,
      views: 98000,
      genres: const ['معمایی', 'ترسناک'],
      author: 'نویسنده نمونه',
      chapterCount: 140,
      updatedAt: DateTime(2026, 9, 25),
    ),
    Work(
      id: 'star-cafe',
      nameEn: 'Star Cafe',
      nameFa: 'کافه ستارگان',
      type: WorkType.manga,
      description:
          'کافه‌ای کوچک که فقط نیمه‌شب‌ها باز می‌شود و مشتری‌هایش آدم نیستند.',
      rating: 4.5,
      views: 71000,
      genres: const ['زندگی روزمره', 'کمدی'],
      author: 'نویسنده نمونه',
      chapterCount: 87,
      updatedAt: DateTime(2026, 9, 20),
    ),
    Work(
      id: 'last-strike',
      nameEn: 'Last Strike',
      nameFa: 'ضربهٔ آخر',
      type: WorkType.manga,
      description: 'مربی‌ای که زمانی قهرمان بود، آخرین فرصتش را در دست شاگردی نوجوان می‌بیند.',
      rating: 4.3,
      views: 54000,
      genres: const ['ورزشی'],
      author: 'نویسنده نمونه',
      chapterCount: 64,
      updatedAt: DateTime(2026, 9, 18),
    ),
    Work(
      id: 'night-courier',
      nameEn: 'Night Courier',
      nameFa: 'پیک شب',
      type: WorkType.manhwa,
      description: 'پیک شبانهٔ یک شهر زیرزمینی بسته‌هایی را جابه‌جا می‌کند که نباید باز شوند.',
      rating: 4.7,
      views: 210000,
      genres: const ['اکشن', 'علمی‌تخیلی'],
      author: 'نویسنده نمونه',
      chapterCount: 112,
      updatedAt: DateTime(2026, 9, 27),
    ),
    Work(
      id: 'crimson-heir',
      nameEn: 'Crimson Heir',
      nameFa: 'وارث سرخ',
      type: WorkType.manhwa,
      description: 'وارث یک خاندان فراموش‌شده باید پیش از طلوع ماه سرخ حقیقت را پیدا کند.',
      rating: 4.4,
      views: 88000,
      genres: const ['فانتزی', 'عاشقانه'],
      author: 'نویسنده نمونه',
      chapterCount: 56,
      updatedAt: DateTime(2026, 9, 22),
    ),
    Work(
      id: 'iron-harbor',
      nameEn: 'Iron Harbor',
      nameFa: 'بندر آهنین',
      type: WorkType.comic,
      description: 'در بندری که قانون ندارد، یک گزارشگر و یک ناخدای بازنشسته دنبال یک کشتی گم‌شده‌اند.',
      rating: 4.3,
      views: 41000,
      genres: const ['ابرقهرمانی', 'معمایی'],
      author: 'نویسنده نمونه',
      chapterCount: 48,
      updatedAt: DateTime(2026, 9, 15),
    ),
    Work(
      id: 'paper-moon',
      nameEn: 'Paper Moon',
      nameFa: 'ماه کاغذی',
      type: WorkType.comic,
      description:
          'مجموعه‌ای کوتاه دربارهٔ آدم‌هایی که شب‌ها در شهر بیدار می‌مانند.',
      rating: 4.1,
      views: 18000,
      genres: const ['روان‌شناختی'],
      author: 'نویسنده نمونه',
      chapterCount: 24,
      updatedAt: DateTime(2026, 8, 30),
      status: WorkStatus.finished,
    ),
  ];

  Future<T> _wait<T>(T v) async {
    if (latency != Duration.zero) await Future<void>.delayed(latency);
    return v;
  }

  @override
  Future<String> userName() => _wait('امیر حسین');

  @override
  Future<Subscription> subscription() =>
      _wait(Subscription(active: subscribed, daysLeft: subscribed ? 26 : 0));

  @override
  Future<List<Work>> works({WorkType? type}) =>
      _wait(_works.where((w) => type == null || w.type == type).toList());

  @override
  Future<Work> work(String id) => _wait(_works.firstWhere((w) => w.id == id));

  Chapter _chapter(Work w, int n) => Chapter(
    id: '${w.id}~$n',
    workId: w.id,
    number: n,
    titleEn: 'Sample chapter $n',
    date: w.updatedAt.subtract(Duration(days: 7 * (w.chapterCount - n))),
    pageCount: 14 + (n * 7) % 9,
    commentCount: (n * 37) % 800,
  );

  @override
  Future<List<Chapter>> chapters(String workId) {
    final w = _works.firstWhere((w) => w.id == workId);
    return _wait([for (var n = w.chapterCount; n >= 1; n--) _chapter(w, n)]);
  }

  @override
  Future<Chapter> openChapter(String chapterId) async {
    final i = chapterId.lastIndexOf('~');
    final w = _works.firstWhere((w) => w.id == chapterId.substring(0, i));
    final c = _chapter(w, int.parse(chapterId.substring(i + 1)));
    if (!c.isFree && !subscribed) throw const PaywallException();
    return _wait(c);
  }

  @override
  Future<ReadingProgress?> lastProgress() async {
    final list = _sorted();
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<List<ReadingProgress>> readingList() => _wait(_sorted());

  List<ReadingProgress> _sorted() =>
      _progress.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  void _seedProgressList() {
    // (work, chapter, page, minutes before the anchor, language)
    final seeds = [
      (0, 242, 2, 30, 'fa'),
      (1, 140, 10, 600, 'fa'),
      (2, 7, 4, 3000, 'en'),
    ];
    for (final (wi, n, page, mins, lang) in seeds) {
      final w = _works[wi];
      final ch = _chapter(w, n);
      _progress[w.id] = ReadingProgress(
        workId: w.id,
        chapterId: ch.id,
        chapterNumber: n,
        page: page,
        pageCount: ch.pageCount,
        updatedAt: _anchor.subtract(Duration(minutes: mins)),
        lang: lang,
      );
    }
  }

  @override
  Future<void> saveProgress(ReadingProgress p) async => _progress[p.workId] = p;

  @override
  Future<void> registerDownloadDevice() async {
    if (deviceLimitReached) throw const DeviceLimitException();
  }

  List<Comment> _seedComments() => [
    const Comment(
      id: 'c1',
      chapterId: '',
      author: 'سارا م.',
      body: 'ترجمه این چپتر خیلی روان بود، مرسی از تیم ترجمه. صحنه آخر فوق‌العاده بود!',
      minutesAgo: 120,
      likes: 129,
      replyCount: 3,
      likedByMe: true,
    ),
    const Comment(
      id: 'c2',
      chapterId: '',
      author: 'رضا ک.',
      body: 'مرگ شخصیت اصلی در صفحه ۱۲ اتفاق می‌افته!',
      minutesAgo: 300,
      likes: 64,
      replyCount: 0,
      spoiler: true,
    ),
    const Comment(
      id: 'c3',
      chapterId: '',
      author: 'Nima',
      body: 'کسی می‌دونه نسخه انگلیسی چپتر بعدی کی میاد؟',
      minutesAgo: 1440,
      likes: 31,
      replyCount: 0,
    ),
    const Comment(
      id: 'r1',
      chapterId: '',
      author: 'تیم ترجمه',
      body: 'ممنون از لطفت! چپتر بعدی امشب ساعت ۲۰ منتشر می‌شه.',
      minutesAgo: 60,
      likes: 58,
      isTeam: true,
      parentId: 'c1',
    ),
    const Comment(
      id: 'r2',
      chapterId: '',
      author: 'رضا ک.',
      body: 'موافقم، مخصوصاً دیالوگ صفحه ۱۲.',
      minutesAgo: 40,
      likes: 12,
      parentId: 'c1',
    ),
    const Comment(
      id: 'r3',
      chapterId: '',
      author: 'Nima',
      body: 'نسخه انگلیسی هم همین امشب میاد؟',
      minutesAgo: 10,
      likes: 3,
      parentId: 'c1',
    ),
  ];

  // Seed comments belong to every chapter (chapterId '' = shared sample data).
  bool _in(Comment c, String chapterId) =>
      c.chapterId.isEmpty || c.chapterId == chapterId;

  @override
  Future<List<Comment>> comments(String chapterId, CommentSort sort) {
    final list = _comments
        .where((c) => c.parentId == null && _in(c, chapterId))
        .toList();
    list.sort(
      sort == CommentSort.popular
          ? (a, b) => b.likes.compareTo(a.likes)
          : (a, b) => a.minutesAgo.compareTo(b.minutesAgo),
    );
    return _wait(list);
  }

  @override
  Future<Comment> comment(String id) =>
      _wait(_comments.firstWhere((c) => c.id == id));

  @override
  Future<List<Comment>> replies(String commentId) =>
      _wait(_comments.where((c) => c.parentId == commentId).toList());

  @override
  Future<void> postComment(
    String chapterId,
    String body, {
    bool spoiler = false,
    String? parentId,
  }) async {
    _comments.add(
      Comment(
        id: 'n${_nextId++}',
        chapterId: chapterId,
        author: 'شما',
        body: body,
        minutesAgo: 0,
        spoiler: spoiler,
        parentId: parentId,
      ),
    );
    if (parentId != null) {
      final i = _comments.indexWhere((c) => c.id == parentId);
      _comments[i] = _comments[i].copyWith(
        replyCount: _comments[i].replyCount + 1,
      );
    }
    await _wait(null);
  }

  @override
  Future<void> toggleLike(String commentId) async {
    final i = _comments.indexWhere((c) => c.id == commentId);
    final c = _comments[i];
    _comments[i] = c.copyWith(
      likedByMe: !c.likedByMe,
      likes: c.likes + (c.likedByMe ? -1 : 1),
    );
  }
}
