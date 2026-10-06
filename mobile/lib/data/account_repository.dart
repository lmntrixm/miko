/// Account, notifications, gifts and support API (docs/api.md). Mock below until the backend exists.
library;

class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.chaptersRead,
    required this.commentCount,
    required this.inviteCode,
    required this.invitedFriends,
    required this.giftDays,
  });

  final String name, email, inviteCode;
  final bool emailVerified;
  final int chaptersRead, commentCount, invitedFriends, giftDays;

  Profile copyWith({String? name, int? giftDays}) => Profile(
        name: name ?? this.name,
        email: email,
        emailVerified: emailVerified,
        chaptersRead: chaptersRead,
        commentCount: commentCount,
        inviteCode: inviteCode,
        invitedFriends: invitedFriends,
        giftDays: giftDays ?? this.giftDays,
      );
}

enum NotifKind { newChapter, subscription, reply, requestAdded }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.minutesAgo,
    this.read = false,
    this.chapterId,
  });

  final String id, title, body;
  final NotifKind kind;
  final int minutesAgo;
  final bool read;

  /// Where a tap leads (reader for chapters, comments for replies).
  final String? chapterId;

  NotificationItem asRead() => NotificationItem(id: id, kind: kind, title: title, body: body, minutesAgo: minutesAgo, read: true, chapterId: chapterId);
  bool get isToday => minutesAgo < 24 * 60;
}

enum ProblemKind { translation, brokenPage, pageOrder, lowQuality, wrongLanguage, other }

class ProblemReport {
  const ProblemReport({required this.kind, required this.description, this.chapterId, this.page, this.lang});
  final ProblemKind kind;
  final String description;
  final String? chapterId, lang;
  final int? page;
}

class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

class InvalidGiftException implements Exception {
  const InvalidGiftException();
}

abstract class AccountRepository {
  Future<Profile> profile();
  Future<void> updateName(String name);
  Future<void> changePassword(String current, String next); // throws WrongPasswordException
  Future<void> deleteAccount();

  Future<List<NotificationItem>> notifications();
  Future<void> markNotificationsRead({String? id}); // null = all

  /// Returns the free days added. Throws [InvalidGiftException].
  Future<int> redeemGift(String code);
  Future<void> reportProblem(ProblemReport report);
}

/// Business rule from the design: every invited friend who subscribes gives both sides free days.
const inviteBonusDays = 7;

class MockAccountRepository implements AccountRepository {
  MockAccountRepository({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  var _profile = const Profile(
    name: 'امیر حسین',
    email: 'demo@miko.test',
    emailVerified: true,
    chaptersRead: 324,
    commentCount: 47,
    inviteCode: 'AMIR-7K2Q',
    invitedFriends: 3,
    giftDays: 14,
  );
  var _password = 'password123';
  final reports = <ProblemReport>[];
  var deleted = false;

  late var _notifs = <NotificationItem>[
    const NotificationItem(id: 'n1', kind: NotifKind.newChapter, title: 'چپتر جدید شمشیر سپیده', body: 'چپتر ۲۴۳ با ترجمهٔ فارسی منتشر شد.', minutesAgo: 10, chapterId: 'dawn-blade~243'),
    const NotificationItem(id: 'n2', kind: NotifKind.newChapter, title: 'چپتر جدید دروازهٔ خاموش', body: 'چپتر ۱۴۱ به زبان انگلیسی در دسترس است.', minutesAgo: 180, chapterId: 'silent-gate~141'),
    const NotificationItem(id: 'n3', kind: NotifKind.subscription, title: 'اشتراک شما رو به پایان است', body: '۵ روز از اشتراک باقی مانده. برای ادامه، تمدید کنید.', minutesAgo: 360, read: true),
    const NotificationItem(id: 'n4', kind: NotifKind.reply, title: 'پاسخ به نظر شما', body: 'رضا ک. به نظر شما در چپتر ۲۴۱ پاسخ داد.', minutesAgo: 2 * 24 * 60, read: true, chapterId: 'dawn-blade~241'),
    const NotificationItem(id: 'n5', kind: NotifKind.requestAdded, title: 'اثر درخواستی اضافه شد', body: 'کافه ستارگان به کتابخانه اضافه شد.', minutesAgo: 4 * 24 * 60, read: true),
  ];

  Future<T> _w<T>(T v) async {
    if (latency != Duration.zero) await Future<void>.delayed(latency);
    return v;
  }

  @override
  Future<Profile> profile() => _w(_profile);

  @override
  Future<void> updateName(String name) async {
    _profile = _profile.copyWith(name: name);
    await _w(null);
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await _w(null);
    if (current != _password) throw const WrongPasswordException();
    _password = next;
  }

  @override
  Future<void> deleteAccount() async {
    deleted = true;
    await _w(null);
  }

  @override
  Future<List<NotificationItem>> notifications() => _w(_notifs);

  @override
  Future<void> markNotificationsRead({String? id}) async {
    _notifs = [for (final n in _notifs) id == null || n.id == id ? n.asRead() : n];
  }

  @override
  Future<int> redeemGift(String code) async {
    await _w(null);
    if (code.trim().toUpperCase() != 'GIFT-TEST') throw const InvalidGiftException();
    _profile = _profile.copyWith(giftDays: _profile.giftDays + 30);
    return 30;
  }

  @override
  Future<void> reportProblem(ProblemReport report) async {
    reports.add(report);
    await _w(null);
  }
}
