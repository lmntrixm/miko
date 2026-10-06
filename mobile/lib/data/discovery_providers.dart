
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_providers.dart';
import 'discovery_repository.dart';
import 'providers.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) => MockDiscoveryRepository(ref.watch(contentRepositoryProvider)));

final authorProvider = FutureProvider.family((ref, String id) => ref.watch(discoveryRepositoryProvider).author(id));
final requestsProvider = FutureProvider.autoDispose((ref) => ref.watch(discoveryRepositoryProvider).requests());
final appStatusProvider = FutureProvider((ref) => ref.watch(discoveryRepositoryProvider).appStatus());

/// Recent searches, newest first, max 8.
class RecentSearches extends Notifier<List<String>> {
  static const _key = 'recent_searches';

  @override
  List<String> build() => ref.watch(sharedPrefsProvider).getStringList(_key) ?? const [];

  void add(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    state = [t, ...state.where((e) => e != t)].take(8).toList();
    ref.read(sharedPrefsProvider).setStringList(_key, state);
  }

  void clear() {
    state = const [];
    ref.read(sharedPrefsProvider).remove(_key);
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);

/// Followed authors (persisted ids).
class FollowedAuthors extends Notifier<Set<String>> {
  static const _key = 'followed_authors';

  @override
  Set<String> build() => (ref.watch(sharedPrefsProvider).getStringList(_key) ?? const []).toSet();

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    ref.read(sharedPrefsProvider).setStringList(_key, state.toList());
  }
}

final followedAuthorsProvider = NotifierProvider<FollowedAuthors, Set<String>>(FollowedAuthors.new);

/// Optional-update prompt is shown once per version.
class DismissedUpdate extends Notifier<String?> {
  static const _key = 'dismissed_update';
  @override
  String? build() => ref.watch(sharedPrefsProvider).getString(_key);
  void dismiss(String version) {
    state = version;
    ref.read(sharedPrefsProvider).setString(_key, version);
  }
}

final dismissedUpdateProvider = NotifierProvider<DismissedUpdate, String?>(DismissedUpdate.new);

// Search UI state.
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();
  void set(SearchFilters f) => state = f;
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new);

final searchResultProvider = FutureProvider.autoDispose((ref) {
  final q = ref.watch(searchQueryProvider);
  final f = ref.watch(searchFiltersProvider);
  if (q.trim().isEmpty) return Future.value(const SearchResult([]));
  return ref.watch(discoveryRepositoryProvider).search(q, f);
});

