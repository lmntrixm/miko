/// Search, requests, authors and global app status (docs/api.md). Mock below.
library;

import 'content_repository.dart';
import 'models.dart';

enum SearchSort { popular, updated }

class SearchFilters {
  const SearchFilters({this.type, this.ongoingOnly = false, this.lang, this.sort = SearchSort.popular});
  final WorkType? type;
  final bool ongoingOnly;

  /// `fa` or `en`; null = any.
  final String? lang;
  final SearchSort sort;

  SearchFilters copyWith({WorkType? type, bool clearType = false, bool? ongoingOnly, String? lang, bool clearLang = false, SearchSort? sort}) => SearchFilters(
        type: clearType ? null : (type ?? this.type),
        ongoingOnly: ongoingOnly ?? this.ongoingOnly,
        lang: clearLang ? null : (lang ?? this.lang),
        sort: sort ?? this.sort,
      );
}

class SearchResult {
  const SearchResult(this.works, {this.suggestion});
  final List<Work> works;

  /// "منظورتان این بود؟" — closest title when nothing matched.
  final Work? suggestion;
}

class Author {
  const Author({required this.id, required this.nameFa, required this.nameEn, required this.role, required this.bio, required this.followers, required this.workIds});
  final String id, nameFa, nameEn, role, bio;
  final int followers;
  final List<String> workIds;
}

class TitleRequest {
  const TitleRequest({required this.id, required this.nameEn, required this.votes, required this.status, this.votedByMe = false});
  final String id, nameEn, status;
  final int votes;
  final bool votedByMe;
  TitleRequest copyWith({int? votes, bool? votedByMe}) => TitleRequest(id: id, nameEn: nameEn, votes: votes ?? this.votes, status: status, votedByMe: votedByMe ?? this.votedByMe);
}

enum UpdateKind { none, optional, forced }

/// Result of the start-up status check (HTTP 426 / 503 in the API).
class AppStatus {
  const AppStatus({this.maintenance = false, this.maintenanceUntil, this.update = UpdateKind.none, this.newVersion, this.releaseNotes = const []});
  final bool maintenance;

  /// Backend-provided time label, e.g. «۰۴:۳۰». null → generic wording.
  final String? maintenanceUntil;
  final UpdateKind update;
  final String? newVersion;
  final List<String> releaseNotes;
}

abstract class DiscoveryRepository {
  Future<SearchResult> search(String query, SearchFilters filters);
  Future<Author> author(String id);
  Future<List<TitleRequest>> requests();
  Future<void> submitRequest({required String name, required WorkType type, required String lang, String note = ''});
  Future<void> vote(String requestId);
  Future<AppStatus> appStatus();
}

/// Plain Levenshtein distance for the "did you mean" hint.
int editDistance(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [cur[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

class MockDiscoveryRepository implements DiscoveryRepository {
  MockDiscoveryRepository(this._content, {this.latency = const Duration(milliseconds: 200), this.status = const AppStatus()});
  final ContentRepository _content;
  final Duration latency;
  AppStatus status;

  final _requests = <TitleRequest>[
    const TitleRequest(id: 'r1', nameEn: 'Sample Request A', votes: 412, status: 'در حال بررسی'),
    const TitleRequest(id: 'r2', nameEn: 'Sample Request B', votes: 305, status: 'در صف'),
  ];
  final submitted = <({String name, WorkType type, String lang, String note})>[];

  Future<T> _w<T>(T v) async {
    if (latency != Duration.zero) await Future<void>.delayed(latency);
    return v;
  }

  @override
  Future<SearchResult> search(String query, SearchFilters f) async {
    final q = query.trim().toLowerCase();
    final all = await _content.works();
    var list = all.where((w) {
      if (q.isNotEmpty && !w.nameEn.toLowerCase().contains(q) && !w.nameFa.contains(query.trim())) return false;
      if (f.type != null && w.type != f.type) return false;
      if (f.ongoingOnly && w.status != WorkStatus.ongoing) return false;
      if (f.lang != null && !w.langs.contains(f.lang)) return false;
      return true;
    }).toList();
    list.sort(f.sort == SearchSort.popular ? (a, b) => b.rating.compareTo(a.rating) : (a, b) => b.updatedAt.compareTo(a.updatedAt));
    Work? suggestion;
    if (list.isEmpty && q.length >= 3) {
      var best = 4;
      for (final w in all) {
        for (final name in [w.nameEn.toLowerCase(), w.nameFa]) {
          final d = editDistance(q, name);
          if (d < best) {
            best = d;
            suggestion = w;
          }
        }
      }
    }
    return _w(SearchResult(list, suggestion: suggestion));
  }

  @override
  Future<Author> author(String id) async {
    final all = await _content.works();
    return _w(Author(
      id: id,
      nameFa: 'نویسنده نمونه',
      nameEn: 'Sample Author',
      role: 'نویسنده و تصویرگر',
      bio: '[معرفی کوتاه نویسنده]',
      followers: 18400,
      workIds: [for (final w in all.where((w) => w.authorId == id)) w.id],
    ));
  }

  @override
  Future<List<TitleRequest>> requests() => _w([..._requests]..sort((a, b) => b.votes.compareTo(a.votes)));

  @override
  Future<void> submitRequest({required String name, required WorkType type, required String lang, String note = ''}) async {
    submitted.add((name: name, type: type, lang: lang, note: note));
    _requests.add(TitleRequest(id: 'r${_requests.length + 1}', nameEn: name, votes: 1, status: 'ثبت شد', votedByMe: true));
    await _w(null);
  }

  @override
  Future<void> vote(String requestId) async {
    final i = _requests.indexWhere((r) => r.id == requestId);
    final r = _requests[i];
    _requests[i] = r.copyWith(votedByMe: !r.votedByMe, votes: r.votes + (r.votedByMe ? -1 : 1));
  }

  @override
  Future<AppStatus> appStatus() => _w(status);
}
