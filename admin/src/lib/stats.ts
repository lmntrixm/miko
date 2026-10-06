/** Sample metrics for the dashboard, analytics and finance pages (the real numbers come from /v1/admin/stats). */
import { faDigits } from './format';

export const dailyReads = [58210, 52440, 47300, 45100, 43200, 41900, 38600, 36800, 34900, 33200, 31000, 29400, 27100, 24800, 22300, 21000, 19800, 24100, 26300, 23900, 22100, 20500, 19000, 18200, 21700, 23300, 22800, 20100, 19500, 18800];

export const dashboardTiles = { activeToday: 12480, activeDelta: 8, subscriptions: 3215, newSubs: 124, publishedThisMonth: 186, publishedDelta: -3 };

export const popularThisWeek = [
  { titleId: 'dawn-blade', name: 'شمشیر سپیده', type: 'مانگا', reads: 55786 },
  { titleId: 'silent-gate', name: 'دروازهٔ خاموش', type: 'مانگا', reads: 52767 },
  { titleId: 'night-courier', name: 'پیک شب', type: 'مانهوا', reads: 43145 },
  { titleId: 'crimson-heir', name: 'وارث سرخ', type: 'مانهوا', reads: 31022 },
  { titleId: 'star-cafe', name: 'کافه ستارگان', type: 'مانگا', reads: 27410 },
];

export const scheduled = [
  { chapter: 'شمشیر سپیده · ۲۴۳', when: 'امروز ۲۰:۰۰', lang: 'فارسی', pages: 18, status: 'ready' as const },
  { chapter: 'پیک شب · ۹۸', when: 'فردا ۱۸:۳۰', lang: 'فارسی', pages: 17, status: 'waiting' as const },
  { chapter: 'کافه ستارگان · ۸', when: 'چهارشنبه ۱۲:۰۰', lang: 'انگلیسی', pages: 20, status: 'ready' as const },
];

export const recentActivity = [
  { text: 'چپتر ۲۴۳ شمشیر سپیده منتشر شد', dot: 'var(--red-400)', ago: '۱۰ دقیقه' },
  { text: '۳ گزارش جدید برای نظرات ثبت شد', dot: 'var(--warning)', ago: '۲۵ دقیقه' },
  { text: 'مترجم «سارا» چپتر ۹۸ را آپلود کرد', dot: 'var(--info)', ago: '۱ ساعت' },
  { text: '۴۲ اشتراک جدید امروز', dot: 'var(--success)', ago: '۲ ساعت' },
];

export const funnel = [
  { label: 'نصب اپ', value: 68400 },
  { label: 'ثبت‌نام', value: 48120 },
  { label: 'خواندن چپتر رایگان', value: 31200 },
  { label: 'دیدن Paywall', value: 18900 },
  { label: 'خرید اشتراک', value: 3215 },
];
export const churn = [6.8, 6.5, 6.9, 6.4, 6.2, 6.1];
export const churnLabels = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور'];
export const languageSplit = [{ label: 'فارسی', pct: 64, color: 'var(--red-500)' }, { label: 'انگلیسی', pct: 22, color: 'var(--info)' }, { label: 'دوزبانه', pct: 14, color: 'var(--warning)' }];
export const dropOff = [
  { work: 'کافه ستارگان · ۸', completion: 48, cause: 'افت کیفیت اسکن · صفحهٔ ۴' },
  { work: 'دروازهٔ خاموش · ۱۴۰', completion: 71, cause: 'صفحات جابه‌جا شده' },
  { work: 'شمشیر سپیده · ۲۴۲', completion: 88, cause: '—' },
  { work: 'پیک شب · ۹۷ (EN)', completion: 64, cause: 'ترجمهٔ فارسی موجود نیست' },
];

export const financeMonths = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور'];
export const financeSeries = [[120, 130, 140, 150, 160, 170], [260, 270, 300, 310, 330, 360], [60, 62, 68, 70, 76, 80]]; // relative units: real amounts stay [مبلغ]
export const financeNames = ['یک ماهه', 'سه ماهه', 'سالانه'];

export const settlements = [
  { gateway: '[درگاه ۱]', status: 'settled' as const, text: 'آخرین تسویه: ۵ مهر · ۸۲٪ تراکنش‌ها' },
  { gateway: '[درگاه ۲]', status: 'pending' as const, text: 'تسویهٔ بعدی: ۸ مهر · ۱۸٪ تراکنش‌ها' },
];
export const invoices = [
  { no: 'INV-1405-0921', user: 'کاربر نمونه ۱', plan: 'سه ماهه', date: '2026-09-28T10:22:00' },
  { no: 'INV-1405-0920', user: 'کاربر نمونه ۷', plan: 'یک ماهه', date: '2026-09-28T09:50:00' },
  { no: 'INV-1405-0918', user: 'کاربر نمونه ۲', plan: 'سالانه', date: '2026-09-27T21:02:00' },
];

export const weekStats = { newComments: 4820, reported: 87, deleted: 31, blockedUsers: 4 };
export const audienceSizes: Record<string, number> = { all: 48120, active: 3215, expiring: 284, followers: 9430 };
export const fa = faDigits;
