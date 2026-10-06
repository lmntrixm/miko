import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_repository.dart';
import 'models.dart';
import 'providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => MockContentRepository(),
);

final userNameProvider = FutureProvider(
  (ref) => ref.watch(contentRepositoryProvider).userName(),
);
final plansProvider = FutureProvider((ref) => ref.watch(contentRepositoryProvider).plans());
final paymentsProvider = FutureProvider.autoDispose((ref) => ref.watch(contentRepositoryProvider).payments());
final subscriptionProvider = FutureProvider(
  (ref) => ref.watch(contentRepositoryProvider).subscription(),
);
final worksProvider = FutureProvider.family<List<Work>, WorkType?>(
  (ref, t) => ref.watch(contentRepositoryProvider).works(type: t),
);
final workProvider = FutureProvider.family<Work, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).work(id),
);
final chaptersProvider = FutureProvider.family<List<Chapter>, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).chapters(id),
);
final openChapterProvider = FutureProvider.autoDispose.family<Chapter, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).openChapter(id),
);
final lastProgressProvider = FutureProvider(
  (ref) => ref.watch(contentRepositoryProvider).lastProgress(),
);
final readingListProvider = FutureProvider(
  (ref) => ref.watch(contentRepositoryProvider).readingList(),
);

final commentSortProvider = NotifierProvider<_SortNotifier, CommentSort>(
  _SortNotifier.new,
);

class _SortNotifier extends Notifier<CommentSort> {
  @override
  CommentSort build() => CommentSort.popular;
  void set(CommentSort s) => state = s;
}

final commentsProvider = FutureProvider.autoDispose
    .family<List<Comment>, String>(
      (ref, chapterId) => ref
          .watch(contentRepositoryProvider)
          .comments(chapterId, ref.watch(commentSortProvider)),
    );
final commentProvider = FutureProvider.autoDispose.family<Comment, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).comment(id),
);
final repliesProvider = FutureProvider.autoDispose
    .family<List<Comment>, String>(
      (ref, id) => ref.watch(contentRepositoryProvider).replies(id),
    );

// ---- reader settings (persisted) ----

enum ReaderLayout { vertical, paged, webtoon }

enum ImageQuality { low, medium, original }

class ReaderSettings {
  const ReaderSettings({
    this.layout,
    this.rtl,
    this.brightness = 0.7,
    this.quality = ImageQuality.original,
    this.keepScreenOn = false,
    this.autoNext = false,
    this.nightFilter = 0.35,
  });

  /// null = follow the work type's default (manga RTL paged, comic LTR paged, manhwa webtoon).
  final ReaderLayout? layout;
  final bool? rtl;
  final double brightness;
  final ImageQuality quality;
  final bool keepScreenOn;
  final bool autoNext;
  final double nightFilter;

  ReaderSettings copyWith({
    ReaderLayout? layout,
    bool? rtl,
    double? brightness,
    ImageQuality? quality,
    bool? keepScreenOn,
    bool? autoNext,
    double? nightFilter,
  }) => ReaderSettings(
    layout: layout ?? this.layout,
    rtl: rtl ?? this.rtl,
    brightness: brightness ?? this.brightness,
    quality: quality ?? this.quality,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    autoNext: autoNext ?? this.autoNext,
    nightFilter: nightFilter ?? this.nightFilter,
  );

  /// Effective layout/direction for [type].
  ReaderLayout layoutFor(WorkType type) =>
      layout ??
      (type.defaultMode == ReadMode.webtoon
          ? ReaderLayout.webtoon
          : ReaderLayout.paged);
  bool rtlFor(WorkType type) => rtl ?? (type.defaultMode != ReadMode.pagedLtr);

  Map<String, Object?> toJson() => {
    'layout': layout?.name,
    'rtl': rtl,
    'brightness': brightness,
    'quality': quality.name,
    'keepScreenOn': keepScreenOn,
    'autoNext': autoNext,
    'nightFilter': nightFilter,
  };

  factory ReaderSettings.fromJson(Map<String, dynamic> j) => ReaderSettings(
    layout: ReaderLayout.values.asNameMap()[j['layout']],
    rtl: j['rtl'] as bool?,
    brightness: (j['brightness'] as num?)?.toDouble() ?? 0.7,
    quality:
        ImageQuality.values.asNameMap()[j['quality']] ?? ImageQuality.original,
    keepScreenOn: j['keepScreenOn'] as bool? ?? false,
    autoNext: j['autoNext'] as bool? ?? false,
    nightFilter: (j['nightFilter'] as num?)?.toDouble() ?? 0.35,
  );
}

class ReaderSettingsController extends Notifier<ReaderSettings> {
  static const _key = 'reader_settings';

  @override
  ReaderSettings build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    if (raw == null) return const ReaderSettings();
    try {
      return ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReaderSettings();
    }
  }

  void update(ReaderSettings s) {
    state = s;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode(s.toJson()));
  }
}

final readerSettingsProvider =
    NotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );

/// Bookmarked work ids ("نشان کردن").
class BookmarksController extends Notifier<Set<String>> {
  static const _key = 'bookmarks';

  @override
  Set<String> build() =>
      (ref.watch(sharedPrefsProvider).getStringList(_key) ?? const []).toSet();

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    ref.read(sharedPrefsProvider).setStringList(_key, state.toList());
  }
}

final bookmarksProvider = NotifierProvider<BookmarksController, Set<String>>(
  BookmarksController.new,
);
