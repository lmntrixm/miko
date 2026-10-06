import type { AuditEntry, ChapterItem, CommentItem, Coupon, Member, Permission, Plan, Role, SentNotification, Task, Title, TitleRequest, Transaction, User } from './types';

const d = (s: string) => new Date(s).toISOString();

const T = (
  id: string, nameFa: string, nameEn: string, type: Title['type'], status: Title['status'], genres: string[], langs: Title['langs'],
  chapters: number, views: number, rating: number | null, updatedAt: string, weekday = 'دوشنبه',
): Title => ({ id, nameFa, nameEn, type, status, genres, langs, chapters, views, rating, updatedAt: d(updatedAt), author: 'نویسنده نمونه', weekday, summary: '[خلاصه داستان]' });

// All titles are invented; real series are copyrighted and must not appear in sample data.
export const seedTitles: Title[] = [
  T('dawn-blade', 'شمشیر سپیده', 'Dawn Blade', 'manga', 'ongoing', ['اکشن', 'فانتزی'], ['fa', 'en'], 242, 124000, 4.8, '2026-09-28T09:00:00'),
  T('silent-gate', 'دروازهٔ خاموش', 'Silent Gate', 'manga', 'ongoing', ['معمایی', 'ترسناک'], ['fa', 'en'], 140, 98000, 4.6, '2026-09-25T10:00:00', 'جمعه'),
  T('star-cafe', 'کافه ستارگان', 'Star Cafe', 'manga', 'ongoing', ['زندگی روزمره', 'کمدی'], ['en'], 87, 71000, 4.5, '2026-09-20T10:00:00', 'شنبه'),
  T('night-courier', 'پیک شب', 'Night Courier', 'manhwa', 'ongoing', ['اکشن', 'علمی‌تخیلی'], ['fa', 'en'], 112, 210000, 4.7, '2026-09-27T10:00:00', 'یکشنبه'),
  T('last-strike', 'ضربهٔ آخر', 'Last Strike', 'manga', 'finished', ['ورزشی'], ['fa'], 64, 54000, 4.3, '2026-07-28T10:00:00'),
  T('crimson-heir', 'وارث سرخ', 'Crimson Heir', 'manhwa', 'ongoing', ['فانتزی', 'عاشقانه'], ['fa', 'en'], 56, 88000, 4.4, '2026-09-22T10:00:00', 'سه‌شنبه'),
  T('iron-harbor', 'بندر آهنین', 'Iron Harbor', 'comic', 'ongoing', ['ابرقهرمانی', 'معمایی'], ['en'], 48, 41000, 4.3, '2026-09-15T10:00:00', 'چهارشنبه'),
  T('paper-moon', 'ماه کاغذی', 'Paper Moon', 'comic', 'finished', ['روان‌شناختی'], ['fa'], 24, 18000, 4.1, '2026-08-30T10:00:00'),
  T('glass-garden', 'باغ شیشه‌ای', 'Glass Garden', 'manga', 'ongoing', ['عاشقانه'], ['fa', 'en'], 33, 27000, 4.2, '2026-09-26T10:00:00', 'پنجشنبه'),
  T('ember-line', 'خط خاکستر', 'Ember Line', 'manga', 'ongoing', ['اکشن', 'تاریخی'], ['fa'], 71, 39000, 4.4, '2026-09-24T10:00:00'),
  T('tidal-oath', 'سوگند جزر و مد', 'Tidal Oath', 'manhwa', 'ongoing', ['فانتزی'], ['fa', 'en'], 45, 52000, 4.5, '2026-09-23T10:00:00', 'جمعه'),
  T('copper-saints', 'قدیسان مس', 'Copper Saints', 'manga', 'finished', ['تاریخی', 'اکشن'], ['fa', 'en'], 120, 76000, 4.6, '2026-05-02T10:00:00'),
  T('hollow-atlas', 'اطلس تهی', 'Hollow Atlas', 'manga', 'ongoing', ['علمی‌تخیلی'], ['en'], 19, 14000, 4.0, '2026-09-18T10:00:00', 'شنبه'),
  T('wild-signal', 'سیگنال وحشی', 'Wild Signal', 'comic', 'ongoing', ['علمی‌تخیلی', 'معمایی'], ['en'], 12, 9000, null, '2026-09-10T10:00:00'),
  T('velvet-rain', 'باران مخمل', 'Velvet Rain', 'manhwa', 'ongoing', ['عاشقانه', 'روان‌شناختی'], ['fa'], 61, 47000, 4.3, '2026-09-21T10:00:00', 'یکشنبه'),
  T('rust-crown', 'تاج زنگار', 'Rust Crown', 'manga', 'ongoing', ['فانتزی', 'اکشن'], ['fa', 'en'], 98, 66000, 4.5, '2026-09-27T10:00:00', 'دوشنبه'),
  T('pale-orbit', 'مدار رنگ‌پریده', 'Pale Orbit', 'manga', 'ongoing', ['علمی‌تخیلی'], ['fa'], 27, 21000, 4.1, '2026-09-12T10:00:00'),
  T('midnight-ledger', 'دفتر نیمه‌شب', 'Midnight Ledger', 'manhwa', 'finished', ['معمایی'], ['fa', 'en'], 150, 91000, 4.6, '2026-04-01T10:00:00'),
  T('stone-lantern', 'فانوس سنگی', 'Stone Lantern', 'manga', 'ongoing', ['تاریخی', 'ترسناک'], ['fa'], 38, 30000, 4.2, '2026-09-19T10:00:00'),
  T('quiet-harvest', 'برداشت آرام', 'Quiet Harvest', 'manga', 'ongoing', ['زندگی روزمره'], ['fa', 'en'], 52, 25000, 4.4, '2026-09-14T10:00:00'),
  T('neon-orchard', 'باغ نئونی', 'Neon Orchard', 'comic', 'ongoing', ['علمی‌تخیلی', 'کمدی'], ['en'], 18, 12000, 4.0, '2026-09-05T10:00:00'),
  T('draft-comic', '[عنوان کامیک]', '[Comic title]', 'comic', 'draft', ['ابرقهرمانی'], [], 0, 0, null, '2026-09-28T08:00:00'),
];

export function seedChapters(titleId: string): ChapterItem[] {
  const t = seedTitles.find((x) => x.id === titleId);
  if (!t) return [];
  const last = Math.max(t.chapters, 0);
  return Array.from({ length: Math.min(last, 6) }, (_, i) => {
    const n = last - i;
    return {
      id: `${titleId}~${n}`,
      titleId,
      number: n,
      titleEn: `Sample chapter ${n}`,
      date: d(new Date(new Date(t.updatedAt).getTime() - i * 7 * 86400000).toISOString()),
      langs: n % 3 === 0 ? ['fa'] : ['fa', 'en'],
      views: Math.max(1000, Math.round(t.views / (i + 2.5))),
      comments: (n * 37) % 700,
    };
  });
}

export const seedTasks: Task[] = [
  { id: 'k1', titleName: 'شمشیر سپیده', chapter: 243, direction: 'FA', column: 'ready', assignee: 'امیر حسین', due: d('2026-09-28T20:00:00'), scheduledAt: d('2026-09-28T20:00:00'), approvedBy: 'امیر حسین' },
  { id: 'k2', titleName: 'کافه ستارگان', chapter: 8, direction: 'JP → EN', column: 'review', assignee: 'محمد (ویراستار)', due: d('2026-09-29T12:00:00'), note: '۲ اصلاح: نام شخصیت در صفحهٔ ۴ و ۹ یکدست نیست' },
  { id: 'k3', titleName: 'پیک شب', chapter: 98, direction: 'EN → FA', column: 'translating', assignee: 'سارا', due: d('2026-09-28T23:00:00'), progress: { done: 12, total: 17 } },
  { id: 'k4', titleName: 'بندر آهنین', chapter: 14, direction: 'EN → FA', column: 'translating', assignee: 'حسین', due: d('2026-09-27T23:00:00'), progress: { done: 7, total: 19 } },
  { id: 'k5', titleName: 'وارث سرخ', chapter: 57, direction: 'EN → FA', column: 'waiting', assignee: 'سارا', due: d('2026-10-01T12:00:00') },
  { id: 'k6', titleName: 'تاج زنگار', chapter: 11, direction: 'EN → FA', column: 'waiting', assignee: 'حسین', due: d('2026-10-03T12:00:00') },
];

export const seedRequests: TitleRequest[] = [
  { id: 'q1', nameEn: 'Sample Request A', firstRequested: d('2026-05-23'), votes: 412, type: 'manga', lang: 'FA', publishRight: 'negotiating', status: 'open' },
  { id: 'q2', nameEn: 'Sample Request B', firstRequested: d('2026-07-05'), votes: 287, type: 'manga', lang: 'FA · EN', publishRight: 'has', status: 'open' },
  { id: 'q3', nameEn: 'Sample Request C', firstRequested: d('2026-08-25'), votes: 241, type: 'manhwa', lang: 'FA', publishRight: 'none', status: 'open' },
  { id: 'q4', nameEn: 'Sample Request D', firstRequested: d('2026-08-31'), votes: 198, type: 'manga', lang: 'EN', publishRight: 'has', status: 'open' },
  { id: 'q5', nameEn: '[Comic title]', firstRequested: d('2026-09-22'), votes: 96, type: 'comic', lang: 'FA', publishRight: 'none', status: 'open' },
];

const U = (id: string, name: string, email: string, plan: string | null, endsIn: number | null, joined: string, chaptersRead: number, status: User['status']): User => ({
  id, name, email, plan, endsIn, joined: d(joined), chaptersRead, status, prefLang: 'فارسی',
  devices: [{ name: 'iPhone 15 · iOS 18', lastSeen: d('2026-09-28T21:30:00'), online: true }, { name: 'Galaxy Tab S9', lastSeen: d('2026-09-25T10:00:00'), online: false }],
  notes: [],
  history: [
    { title: 'شمشیر سپیده · ۲۴۲', progress: 100, lang: 'فارسی', when: d('2026-09-28T21:10:00') },
    { title: 'دروازهٔ خاموش · ۱۴۰', progress: 82, lang: 'فارسی', when: d('2026-09-27T20:00:00') },
    { title: 'کافه ستارگان · ۷', progress: 55, lang: 'انگلیسی', when: d('2026-09-26T20:00:00') },
  ],
  payments: plan ? [`${plan} · A-000281${String(id.length * 7).padStart(3, '0')}`] : [],
});

export const seedUsers: User[] = [
  U('u1', 'کاربر نمونه ۱', 'user1@example.com', '۳ ماهه', 26, '2026-02-02', 324, 'active'),
  U('u2', 'کاربر نمونه ۲', 'user2@example.com', 'سالانه', 210, '2025-11-06', 1042, 'active'),
  U('u3', 'کاربر نمونه ۳', 'user3@example.com', '۱ ماهه', -3, '2026-05-11', 88, 'expired'),
  U('u4', 'Sample User 4', 'user4@example.com', null, null, '2026-09-24', 12, 'free'),
  U('u5', 'کاربر نمونه ۵', 'user5@example.com', '۳ ماهه', 60, '2026-04-30', 567, 'active'),
  U('u6', 'کاربر نمونه ۶', 'user6@example.com', null, null, '2026-06-26', 40, 'blocked'),
  U('u7', 'کاربر نمونه ۷', 'user7@example.com', '۱ ماهه', 18, '2026-06-25', 101, 'active'),
];

export const seedPlans: Plan[] = [
  { id: 'month1', name: 'یک ماهه', days: 30, priceToman: null, active: true, subscribers: 980 },
  { id: 'month3', name: 'سه ماهه', days: 90, priceToman: null, active: true, subscribers: 1645 },
  { id: 'year', name: 'سالانه', days: 365, priceToman: null, active: true, subscribers: 590 },
];
export const seedCoupons: Coupon[] = [
  { code: 'MEHR20', note: '۲۰٪ · ۱۴۲ استفاده', uses: 142, expired: false },
  { code: 'WELCOME', note: '۷ روز رایگان', uses: 310, expired: false },
  { code: 'YALDA04', note: 'منقضی', uses: 95, expired: true },
];
export const seedTransactions: Transaction[] = [
  { code: 'A-000281734', user: 'کاربر نمونه ۱', plan: 'سه ماهه', date: d('2026-09-28T10:22:00'), gateway: '[درگاه ۱]', status: 'success' },
  { code: 'A-000281733', user: 'کاربر نمونه ۷', plan: 'یک ماهه', date: d('2026-09-28T09:50:00'), gateway: '[درگاه ۱]', status: 'success' },
  { code: 'A-000281730', user: 'کاربر نمونه ۳', plan: 'یک ماهه', date: d('2026-09-27T23:14:00'), gateway: '[درگاه ۲]', status: 'failed' },
  { code: 'A-000281726', user: 'کاربر نمونه ۲', plan: 'سالانه', date: d('2026-09-27T21:02:00'), gateway: '[درگاه ۱]', status: 'success' },
  { code: 'A-000281721', user: 'کاربر نمونه ۵', plan: 'سه ماهه', date: d('2026-09-27T18:40:00'), gateway: '[درگاه ۲]', status: 'success' },
  { code: 'A-000281719', user: 'Sample User 4', plan: 'یک ماهه', date: d('2026-09-27T15:33:00'), gateway: '[درگاه ۱]', status: 'failed' },
];

export const seedComments: CommentItem[] = [
  { id: 'c1', user: 'کاربر نمونه ۸', work: 'شمشیر سپیده', chapter: 242, when: d('2026-09-28T21:20:00'), body: 'کسایی که هنوز نخوندن بدونن توی چپتر بعدی [متن اسپویل حذف شد برای نمایش…]', tags: ['spoiler'], reports: 9, status: 'reported' },
  { id: 'c2', user: 'کاربر ۸۸۲۱', work: 'دروازهٔ خاموش', chapter: 140, when: d('2026-09-28T15:40:00'), body: 'برای دانلود رایگان همه چپترها به [لینک] مراجعه کنید!!!', tags: ['link', 'spam'], reports: 6, status: 'reported' },
  { id: 'c3', user: 'کاربر نمونه ۹', work: 'کافه ستارگان', chapter: 7, when: d('2026-09-28T18:40:00'), body: '[متن نظر گزارش‌شده به دلیل توهین به کاربر دیگر]', tags: ['insult'], reports: 3, status: 'reported' },
  { id: 'c4', user: 'کاربر نمونه ۱۰', work: 'پیک شب', chapter: 98, when: d('2026-09-28T20:00:00'), body: 'ترجمه این چپتر عالی بود، ممنون!', tags: [], reports: 0, status: 'pending' },
];

export const seedSent: SentNotification[] = [
  { id: 's1', title: 'چپتر ۱۰۹۷ شمشیر سپیده منتشر شد', audience: 'دنبال‌کنندگان اثر', channels: ['پوش', 'درون‌برنامه'], sent: 12804, openRate: 41, when: d('2026-09-27T18:30:00') },
  { id: 's2', title: 'تخفیف ۲۰٪ اشتراک مهر', audience: 'همه کاربران', channels: ['ایمیل', 'پوش'], sent: 47950, openRate: 18, when: d('2026-09-25T12:00:00') },
  { id: 's3', title: 'اشتراک شما رو به پایان است', audience: 'رو به انقضا', channels: ['درون‌برنامه'], sent: 312, openRate: 63, when: d('2026-09-24T12:00:00') },
  { id: 's4', title: 'کافه ستارگان به زبان انگلیسی اضافه شد', audience: 'همه کاربران', channels: ['پوش'], sent: 47201, openRate: 27, when: d('2026-09-21T12:00:00') },
];

export const seedAudit: AuditEntry[] = [
  { id: 'a1', when: d('2026-09-28T10:42:00'), member: 'مدیر نمونه', section: 'content', action: 'انتشار چپتر ۲۴۳ شمشیر سپیده را برای ۲۰:۰۰ زمان‌بندی کرد', device: '[IP] · Mac' },
  { id: 'a2', when: d('2026-09-28T10:15:00'), member: 'ناظر نمونه', section: 'content', action: 'نظر گزارش‌شده در دروازهٔ خاموش ۱۴۰ را حذف کرد (اسپویل)', device: '[IP] · Android' },
  { id: 'a3', when: d('2026-09-28T09:58:00'), member: 'مترجم نمونه', section: 'content', action: '۱۲ صفحه ترجمهٔ پیک شب ۹۸ را آپلود کرد', device: '[IP] · Windows' },
  { id: 'a4', when: d('2026-09-28T09:30:00'), member: 'مدیر نمونه', section: 'users', action: 'کاربر «کاربر نمونه ۶» را به دلیل اسپم مسدود کرد', device: '[IP] · Mac' },
  { id: 'a5', when: d('2026-09-28T09:02:00'), member: 'مدیر نمونه', section: 'payment', action: 'کد تخفیف MEHR20 را تا ۱۵ مهر تمدید کرد', device: '[IP] · Mac' },
  { id: 'a6', when: d('2026-09-27T22:10:00'), member: 'ویراستار نمونه', section: 'content', action: 'بازبینی کافه ستارگان ۸ را با ۲ اصلاح برگرداند', device: '[IP] · Mac' },
  { id: 'a7', when: d('2026-09-27T18:45:00'), member: 'مدیر نمونه', section: 'settings', action: 'دسترسی «مشاهده پرداخت‌ها» را از نقش ویراستار برداشت', device: '[IP] · Mac' },
];

export const seedMembers: Member[] = [
  { id: 'm1', name: 'مدیر نمونه', role: 'admin', lastSeen: 'آنلاین', online: true },
  { id: 'm2', name: 'مترجم نمونه', role: 'translator', lastSeen: '۱ ساعت پیش' },
  { id: 'm3', name: 'ویراستار نمونه', role: 'editor', lastSeen: 'امروز' },
  { id: 'm4', name: 'ناظر نمونه', role: 'moderator', lastSeen: 'دیروز' },
];

const A = (...roles: Role[]) => roles;
export const seedPermissions: Record<Permission, Role[]> = {
  'افزودن و ویرایش آثار': A('admin', 'editor'),
  'آپلود چپتر': A('admin', 'editor', 'translator'),
  'انتشار و زمان‌بندی': A('admin', 'editor'),
  'مدیریت کاربران': A('admin'),
  'مشاهده پرداخت‌ها': A('admin'),
  'مدیریت نظرات': A('admin', 'editor', 'moderator'),
  'ارسال اعلان': A('admin', 'editor'),
  'تغییر تنظیمات': A('admin'),
};
