# انتشار اپ میکو

این فایل مراحل ساخت و انتشار را می‌گوید. در محیط توسعهٔ این پروژه Android SDK و Xcode نبود؛ پس **هنوز APK/IPA ساخته و روی دستگاه امتحان نشده**. تنظیمات آماده است و باید یک بار روی دستگاه خودتان اجرا شود.

## شناسه‌ها
- نام نمایشی: «میکو»
- شناسه بسته (Android) و bundle id (iOS): `app.miko.miko` ← اگر شناسه دیگری می‌خواهید قبل از اولین انتشار عوض کنید؛ بعد از انتشار نمی‌شود.

## نسخه‌بندی
در `mobile/pubspec.yaml`: `version: 1.0.0+1` یعنی `نسخه‌نمایشی+شمارهٔ ساخت`.
- نسخهٔ نمایشی `major.minor.patch`: به کاربر نشان داده می‌شود.
- شمارهٔ ساخت: با هر آپلود به فروشگاه یکی اضافه شود (versionCode / CFBundleVersion).

## Android
1. یک keystore بسازید: `keytool -genkey -v -keystore ~/miko-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. فایل `mobile/android/key.properties` (در git نمی‌رود):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/miko-upload.jks
   ```
3. `cd mobile && flutter build appbundle --release` ← خروجی در `build/app/outputs/bundle/release/`.
   بدون `key.properties` ساخت با کلید debug انجام می‌شود (فقط برای آزمایش).
4. کوچک‌سازی (R8) روشن است؛ اگر کرش عجیبی دیدید `android/app/proguard-rules.pro` را ببینید.

## iOS
`cd mobile && flutter build ipa --release` روی macOS، با Team و signing در Xcode (`ios/Runner.xcworkspace`).

## بازگشت از درگاه (deep link)
آدرس بازگشت `miko://payment` در AndroidManifest و Info.plist تعریف شده. باید در پنل درگاه به‌عنوان callback ثبت شود و روی دستگاه واقعی امتحان شود. تا آن موقع ← `PaymentPending` با polling کار می‌کند.

## هنوز باز است
- موتور دانلود شبیه‌سازی است و تا بک‌اند واقعی نیست فایل واقعی نمی‌گیرد.
- مقادیر `[قیمت]`، `[ایمیل پشتیبانی]`، `[domain]`، لینک فروشگاه‌ها و لوگوی نهایی را کاربر باید بدهد.

## پنل ادمین
متغیرها در `admin/.env.example`. رمز: `npm run admin:hash -- 'رمز'`. بدون این‌ها، در production ورود رد می‌شود (فقط با `ADMIN_DEMO=1` حساب نمونه فعال است). نشست با کوکی httpOnly امضاشده، TOTP سمت سرور بررسی می‌شود و ۵ تلاش ناموفق ۱۵ دقیقه قفل می‌کند (شمارنده در حافظهٔ پردازه است؛ برای چند سرور باید در یک انبار مشترک باشد). نقش و نام کاربر هنوز ثابت است تا بک‌اند واقعی کاربران را بدهد.
