import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'account_repository.dart';
import 'providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) => MockAccountRepository());

final profileProvider = FutureProvider((ref) => ref.watch(accountRepositoryProvider).profile());
final notificationsProvider = FutureProvider.autoDispose((ref) => ref.watch(accountRepositoryProvider).notifications());

/// Unread count for the bell badge; kept alive so the badge is always current.
final unreadCountProvider = FutureProvider((ref) async {
  final list = await ref.watch(accountRepositoryProvider).notifications();
  return list.where((n) => !n.read).length;
});

/// Share sheet. Replaced by a fake in tests.
abstract class ShareService {
  Future<void> share(String text);
}

class PlatformShare implements ShareService {
  @override
  Future<void> share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => PlatformShare());

// ---- appearance ----

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.dark; // dark is the default
  }

  void set(ThemeMode m) {
    state = m;
    ref.read(sharedPrefsProvider).setString(_key, m.name);
  }

  void toggle() => set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

// ---- notification settings (persisted locally; sync to backend + FCM permission come later) ----

class NotificationPrefs {
  const NotificationPrefs({
    this.newChapter = true,
    this.reply = true,
    this.subscription = true,
    this.promo = false,
    this.mutedWorks = const {},
    this.dnd = true,
    this.dndFromMin = 23 * 60,
    this.dndToMin = 8 * 60,
  });

  final bool newChapter, reply, subscription, promo, dnd;
  final Set<String> mutedWorks;
  final int dndFromMin, dndToMin;

  NotificationPrefs copyWith({bool? newChapter, bool? reply, bool? subscription, bool? promo, bool? dnd, Set<String>? mutedWorks, int? dndFromMin, int? dndToMin}) => NotificationPrefs(
        newChapter: newChapter ?? this.newChapter,
        reply: reply ?? this.reply,
        subscription: subscription ?? this.subscription,
        promo: promo ?? this.promo,
        dnd: dnd ?? this.dnd,
        mutedWorks: mutedWorks ?? this.mutedWorks,
        dndFromMin: dndFromMin ?? this.dndFromMin,
        dndToMin: dndToMin ?? this.dndToMin,
      );

  Map<String, Object?> toJson() => {'newChapter': newChapter, 'reply': reply, 'subscription': subscription, 'promo': promo, 'dnd': dnd, 'muted': mutedWorks.toList(), 'from': dndFromMin, 'to': dndToMin};

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) => NotificationPrefs(
        newChapter: j['newChapter'] as bool? ?? true,
        reply: j['reply'] as bool? ?? true,
        subscription: j['subscription'] as bool? ?? true,
        promo: j['promo'] as bool? ?? false,
        dnd: j['dnd'] as bool? ?? true,
        mutedWorks: ((j['muted'] as List?) ?? const []).cast<String>().toSet(),
        dndFromMin: j['from'] as int? ?? 23 * 60,
        dndToMin: j['to'] as int? ?? 8 * 60,
      );
}

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const _key = 'notification_prefs';

  @override
  NotificationPrefs build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    try {
      return raw == null ? const NotificationPrefs() : NotificationPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  void update(NotificationPrefs p) {
    state = p;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode(p.toJson()));
  }
}

final notificationPrefsProvider = NotifierProvider<NotificationPrefsController, NotificationPrefs>(NotificationPrefsController.new);
