# میکو (Miko)

اپ موبایل خواندن آنلاین مانگا، مانهوا و کامیک (فارسی و انگلیسی) و پنل مدیریت وب.

| پوشه | چیست |
|---|---|
| `mobile/` | اپ Flutter (Dart، Riverpod، go_router) |
| `admin/` | پنل ادمین Next.js 16 (App Router، TypeScript) |
| `design/`, `docs/` | طراحی، توکن‌ها، نقشه صفحه‌ها/جریان‌ها/API (منبع حقیقت) |

راهنمای کار با Claude Code در `CLAUDE.md` است.

## اپ موبایل

```bash
cd mobile
flutter pub get
flutter analyze && flutter test     # ۴۹ تست
flutter run                          # نیاز به شبیه‌ساز/دستگاه
```

- حساب آزمایشی: `demo@miko.test` / `password123`، همه کدها `123456`، کد تخفیف `WELCOME`، کد هدیه `GIFT-TEST`.
- داده‌ی اپ ساختگی است (`lib/data/*_repository.dart`، پیاده‌سازی `Mock…`). برای بک‌اند واقعی فقط همین پیاده‌سازی‌ها عوض می‌شوند.
- تم تیره پیش‌فرض است؛ روشن و خودکار از «پروفایل ← ظاهر برنامه».
- فونت Vazirmatn داخل اپ بسته‌بندی شده (`mobile/assets/fonts`).

## پنل ادمین

```bash
cd admin
npm install
npm run dev                          # http://localhost:3000
npm test                             # vitest (منطق و store)
npm run build && npm run e2e         # Playwright روی Chromium نصب‌شده (CHROMIUM_PATH)
```

- ورود آزمایشی (فقط با `ADMIN_DEMO=1` یا `npm run dev`): `admin@miko.test` / `password123`، کد دومرحله‌ای از Authenticator با راز `JBSWY3DPEHPK3PXP`.
- توکن‌های رنگ از `design/tokens/tokens.json` به `src/styles/tokens.css` تولید می‌شوند (`npm run tokens`).
- داده در `src/lib/store.ts` (ساختگی، در sessionStorage). **ورود و نشست سمت سرور است** (کوکی httpOnly امضاشده، TOTP، قفل بعد از ۵ تلاش)؛ تنظیم محیط‌های واقعی در `admin/.env.example` و `docs/release.md`. CI در `.github/workflows/ci.yml`.

## جای‌خالی‌ها (از طراحی؛ حدس زده نشده‌اند)

`[قیمت]` · `[مبلغ]` · `[ایمیل پشتیبانی]` · `[لینک دانلود]` و لینک فروشگاه · `[درگاه]` · `[دامنه]` · لوگوی نهایی · کاورهای واقعی · متن نهایی قوانین/حریم خصوصی.

## هنوز وصل نشده

- بک‌اند واقعی، درگاه بانکی و deep link برگشت از درگاه
- push notification (FCM/APNs)، آپلود تصویر پروفایل و اسکرین‌شات گزارش
- دانلود واقعی فایل‌ها (موتور دانلود فعلاً شبیه‌سازی است)
