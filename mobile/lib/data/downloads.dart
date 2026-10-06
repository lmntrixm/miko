import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_providers.dart';
import 'models.dart';
import 'network.dart';
import 'providers.dart';

enum DownloadState { queued, downloading, done }

/// A chapter download. Carries a snapshot of the work/chapter so it can be read offline.
class DownloadItem {
  const DownloadItem({
    required this.chapterId,
    required this.workId,
    required this.workNameFa,
    required this.workNameEn,
    required this.type,
    required this.workChapterCount,
    required this.number,
    required this.titleEn,
    required this.pageCount,
    required this.sizeMb,
    this.state = DownloadState.queued,
    this.progress = 0,
  });

  final String chapterId, workId, workNameFa, workNameEn, titleEn;
  final WorkType type;
  final int workChapterCount, number, pageCount;
  final double sizeMb;
  final DownloadState state;
  final double progress;

  bool get isDone => state == DownloadState.done;

  DownloadItem copyWith({DownloadState? state, double? progress}) =>
      DownloadItem(
        chapterId: chapterId,
        workId: workId,
        workNameFa: workNameFa,
        workNameEn: workNameEn,
        type: type,
        workChapterCount: workChapterCount,
        number: number,
        titleEn: titleEn,
        pageCount: pageCount,
        sizeMb: sizeMb,
        state: state ?? this.state,
        progress: progress ?? this.progress,
      );

  /// Minimal work/chapter for the reader when offline.
  Work toWork() => Work(
    id: workId,
    nameEn: workNameEn,
    nameFa: workNameFa,
    type: type,
    description: '',
    rating: 0,
    views: 0,
    genres: const [],
    author: '',
    chapterCount: workChapterCount,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  Chapter toChapter() => Chapter(
    id: chapterId,
    workId: workId,
    number: number,
    titleEn: titleEn,
    date: DateTime.fromMillisecondsSinceEpoch(0),
    pageCount: pageCount,
    commentCount: 0,
  );

  Map<String, Object?> toJson() => {
    'chapterId': chapterId,
    'workId': workId,
    'workNameFa': workNameFa,
    'workNameEn': workNameEn,
    'type': type.name,
    'workChapterCount': workChapterCount,
    'number': number,
    'titleEn': titleEn,
    'pageCount': pageCount,
    'sizeMb': sizeMb,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
    chapterId: j['chapterId'] as String,
    workId: j['workId'] as String,
    workNameFa: j['workNameFa'] as String,
    workNameEn: j['workNameEn'] as String,
    type: WorkType.values.byName(j['type'] as String),
    workChapterCount: j['workChapterCount'] as int,
    number: j['number'] as int,
    titleEn: j['titleEn'] as String,
    pageCount: j['pageCount'] as int,
    sizeMb: (j['sizeMb'] as num).toDouble(),
    state: DownloadState.done,
    progress: 1,
  );
}

class DownloadsState {
  const DownloadsState({
    this.items = const [],
    this.wifiOnly = true,
    this.paused = false,
    this.justCompleted,
  });
  final List<DownloadItem> items;
  final bool wifiOnly, paused;

  /// Last finished download; the shell announces it ("دانلود کامل شد").
  final DownloadItem? justCompleted;

  List<DownloadItem> get done => items.where((i) => i.isDone).toList();
  List<DownloadItem> get active => items.where((i) => !i.isDone).toList();
  double get usedMb => done.fold(0, (a, i) => a + i.sizeMb);
  double get queuedMb => active.fold(0, (a, i) => a + i.sizeMb);

  DownloadsState copyWith({
    List<DownloadItem>? items,
    bool? wifiOnly,
    bool? paused,
    DownloadItem? justCompleted,
  }) => DownloadsState(
    items: items ?? this.items,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    paused: paused ?? this.paused,
    justCompleted: justCompleted,
  );
}

enum EnqueueResult { started, alreadyThere, needsSubscription, deviceLimit }

/// Total space the plan allows. [config] until the real quota comes from the backend.
const downloadQuotaMb = 4096.0;

/// Whether the mock engine ticks on its own. Tests turn it off and call [DownloadsController.tick].
final downloadAutoTickProvider = Provider<bool>((ref) => true);

/// Download queue + persistence. The engine here only *simulates* transfer progress;
/// swap `tick` for a real background downloader when files exist.
class DownloadsController extends Notifier<DownloadsState> {
  static const _doneKey = 'downloads_done';
  static const _wifiKey = 'downloads_wifi_only';
  Timer? _timer;

  @override
  DownloadsState build() {
    final p = ref.watch(sharedPrefsProvider);
    ref.onDispose(() => _timer?.cancel());
    // Re-evaluate when connectivity changes so wifi-only downloads resume.
    ref.listen(networkStatusProvider, (_, _) => _ensureTimer());
    var items = <DownloadItem>[];
    try {
      items = [
        for (final j in jsonDecode(p.getString(_doneKey) ?? '[]') as List)
          DownloadItem.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {}
    return DownloadsState(items: items, wifiOnly: p.getBool(_wifiKey) ?? true);
  }

  void _persist() {
    final p = ref.read(sharedPrefsProvider);
    p.setString(_doneKey, jsonEncode([for (final i in state.done) i.toJson()]));
    p.setBool(_wifiKey, state.wifiOnly);
  }

  DownloadItem? downloaded(String chapterId) =>
      state.done.where((i) => i.chapterId == chapterId).firstOrNull;

  Future<EnqueueResult> enqueue(Work work, Chapter chapter) async {
    if (state.items.any((i) => i.chapterId == chapter.id)) {
      return EnqueueResult.alreadyThere;
    }
    final sub = await ref.read(subscriptionProvider.future);
    if (!sub.active) return EnqueueResult.needsSubscription;
    try {
      await ref.read(contentRepositoryProvider).registerDownloadDevice();
    } on DeviceLimitException {
      return EnqueueResult.deviceLimit;
    }
    final item = DownloadItem(
      chapterId: chapter.id,
      workId: work.id,
      workNameFa: work.nameFa,
      workNameEn: work.nameEn,
      type: work.type,
      workChapterCount: work.chapterCount,
      number: chapter.number,
      titleEn: chapter.titleEn,
      pageCount: chapter.pageCount,
      sizeMb: chapter.pageCount * 3.2,
    );
    state = state.copyWith(items: [...state.items, item]);
    _ensureTimer();
    return EnqueueResult.started;
  }

  void cancel(String chapterId) {
    state = state.copyWith(
      items: state.items.where((i) => i.chapterId != chapterId).toList(),
    );
  }

  /// Removes every downloaded chapter of [workId].
  void deleteWork(String workId) {
    state = state.copyWith(
      items: state.items
          .where((i) => !(i.workId == workId && i.isDone))
          .toList(),
    );
    _persist();
  }

  void setWifiOnly(bool v) {
    state = state.copyWith(wifiOnly: v);
    _persist();
    _ensureTimer();
  }

  void togglePause() {
    state = state.copyWith(paused: !state.paused);
    _ensureTimer();
  }

  bool get _canTransfer {
    final net = ref.read(networkStatusProvider);
    if (net.isOffline || state.paused) return false;
    return !(state.wifiOnly && net == NetworkStatus.mobile);
  }

  void _ensureTimer() {
    if (!ref.read(downloadAutoTickProvider)) return;
    final need = state.active.isNotEmpty && _canTransfer;
    if (need && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => tick());
    } else if (!need) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Advances the first active item by [step] (0..1). One transfer at a time, rest stay queued.
  void tick({double step = 0.1}) {
    if (!_canTransfer) return;
    final active = state.active;
    if (active.isEmpty) return;
    final cur = active.first;
    final next = (cur.progress + step).clamp(0.0, 1.0);
    final finished = next > 0.999; // float steps never sum to exactly 1
    final updated = cur.copyWith(
      state: finished ? DownloadState.done : DownloadState.downloading,
      progress: next,
    );
    state = state.copyWith(
      items: [
        for (final i in state.items) i.chapterId == cur.chapterId ? updated : i,
      ],
      justCompleted: finished ? updated : null,
    );
    if (finished) {
      _persist();
      _ensureTimer();
    }
  }
}

final downloadsProvider = NotifierProvider<DownloadsController, DownloadsState>(
  DownloadsController.new,
);
