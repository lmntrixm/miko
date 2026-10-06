# فهرست صفحه‌ها

هر صفحه یک تصویر (`design/screens/…/Name.png`) و یک HTML ایستا (`design/html/…/Name.html`) دارد. ستون «لینک‌ها» صفحه‌هایی است که از این صفحه باز می‌شوند (نسخه طراحی). مسیرها پیشنهادی‌اند.

## اپ موبایل — تیره (41)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `Main` | کشف و دسته‌بندی | 390×844 | `/main` | Library, Notifications, OrigHome, Profile, Reader, RequestTitle, Search |
| `Search` | جستجو | 390×844 | `/search` | Library, Main, OrigHome, Profile, Reader, RequestTitle |
| `Reader` | خواندن چپتر | 390×844 | `/reader` | Comments, Main, ReaderSettings |
| `ReaderSettings` | تنظیمات خواندن | 390×844 | `/reader-settings` | Reader, ReportProblem |
| `Comments` | نظرات چپتر | 390×844 | `/comments` | CommentThread, Reader |
| `Library` | کتابخانه من | 390×844 | `/library` | Downloads, Main, Notifications, OrigHome, Profile, Reader, RequestTitle |
| `Notifications` | اعلان‌ها | 390×844 | `/notifications` | Comments, Main, NotificationSettings, OrigHome, Reader, Subscription |
| `Profile` | پروفایل | 390×844 | `/profile` | Downloads, EditProfile, HelpCenter, InviteFriends, Library, LightProfile, Main, ManageSubscription, NotificationSettings, OnboardingPrefs, OrigHome, PaymentHistory, RequestTitle |
| `Subscription` | خرید اشتراک | 390×844 | `/subscription` | PaymentPending, Profile |
| `ForgotPassword` | فراموشی رمز عبور | 390×844 | `/forgot-password` | AuthLogin, HelpCenter |
| `ComicDetail` | جزئیات اثر کامیک | 390×844 | `/comic-detail` | Library, Main, OrigHome, Profile, Reader, RequestTitle |
| `Paywall` | دیوار اشتراک | 390×844 | `/paywall` | OrigDetail, PaymentPending, Reader |
| `EmptyLibrary` | حالت خالی — کتابخانه | 390×844 | `/empty-library` | Library, Main, OrigHome, Profile, RequestTitle |
| `NoResults` | حالت خالی — جستجو | 390×844 | `/no-results` | OrigDetail |
| `Loading` | بارگذاری (اسکلتون) | 390×844 | `/loading` | — |
| `Offline` | خطا — قطع اینترنت | 390×844 | `/offline` | Reader |
| `Downloads` | مدیریت دانلودها | 390×844 | `/downloads` | Library |
| `PaymentResult` | نتیجه پرداخت | 390×844 | `/payment-result` | Reader, Subscription |
| `OnboardingPrefs` | شخصی‌سازی اولیه | 390×844 | `/onboarding-prefs` | OrigHome |
| `HomeTypes` | خانه — مانگا/مانهوا/کامیک | 390×844 | `/home-types` | ComicDetail, Library, ListAll, Main, Notifications, OrigDetail, Profile, Reader, ReaderWebtoon, RequestTitle |
| `ReaderWebtoon` | خواننده وبتون + فیلتر شب | 390×844 | `/reader-webtoon` | HomeTypes |
| `RequestTitle` | درخواست اثر جدید | 390×844 | `/request-title` | OrigHome |
| `EditProfile` | ویرایش پروفایل و رمز | 390×844 | `/edit-profile` | Profile |
| `PaymentHistory` | تاریخچه پرداخت‌ها | 390×844 | `/payment-history` | ManageSubscription, Profile |
| `CommentThread` | پاسخ‌های نظر | 390×844 | `/comment-thread` | Comments |
| `AuthorPage` | صفحه نویسنده | 390×844 | `/author-page` | OrigDetail |
| `ListAll` | فهرست کامل «بیشتر» | 390×844 | `/list-all` | OrigDetail, OrigHome |
| `PaymentPending` | برگشت از درگاه — در حال بررسی | 390×844 | `/payment-pending` | PaymentHistory, PaymentResult |
| `ManageSubscription` | مدیریت اشتراک و لغو تمدید | 390×844 | `/manage-subscription` | PaymentHistory, Profile, Subscription |
| `TabletReader` | تبلت — خواننده دو صفحه‌ای | 1194×834 | `/tablet-reader` | OrigDetail, ReaderSettings |
| `ReaderLandscape` | گوشی افقی — خواننده | 844×390 | `/reader-landscape` | Reader |
| `AuthLogin` | ورود (قابل ویرایش) | 390×844 | `/auth-login` | AuthSignup, ForgotPassword, OrigHome |
| `AuthSignup` | ثبت‌نام (قابل ویرایش) | 390×844 | `/auth-signup` | AuthLogin, AuthOTP, Legal |
| `AuthOTP` | کد تأیید (قابل ویرایش) | 390×844 | `/auth-o-t-p` | OnboardingPrefs |
| `Legal` | قوانین، حریم خصوصی، درباره ما | 390×844 | `/legal` | Profile |
| `HelpCenter` | پشتیبانی و سؤالات متداول | 390×844 | `/help-center` | Legal, PaymentHistory, Profile, ReportProblem |
| `ReportProblem` | گزارش مشکل | 390×844 | `/report-problem` | Reader |
| `NotificationSettings` | تنظیمات اعلان‌ها | 390×844 | `/notification-settings` | Profile |
| `InviteFriends` | دعوت دوستان و کد هدیه | 390×844 | `/invite-friends` | Profile, Subscription |
| `AppUpdate` | به‌روزرسانی اپ | 390×844 | `/app-update` | OrigHome |
| `Maintenance` | تعمیر و نگهداری | 390×844 | `/maintenance` | Offline |

## پنل ادمین وب — تیره (16)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `AdminDashboard` | ادمین — داشبورد | 1440×900 | `/admin/dashboard` | AdminTitleEdit, AdminTitles |
| `AdminTitles` | ادمین — مدیریت آثار | 1440×900 | `/admin/titles` | AdminTitleEdit |
| `AdminTitleEdit` | ادمین — ویرایش اثر و آپلود چپتر | 1440×900 | `/admin/title-edit` | AdminTitles, AdminTranslations |
| `AdminUsers` | ادمین — کاربران | 1440×900 | `/admin/users` | AdminUserDetail |
| `AdminSubscriptions` | ادمین — اشتراک و پرداخت‌ها | 1440×900 | `/admin/subscriptions` | — |
| `AdminComments` | ادمین — مدیریت نظرات | 1440×900 | `/admin/comments` | — |
| `AdminMobile` | ادمین موبایل — صف تأیید | 390×844 | `/admin/mobile` | AdminComments, AdminSettings, AdminUsers |
| `AdminNotify` | ادمین — ارسال اعلان | 1440×900 | `/admin/notify` | — |
| `AdminSettings` | ادمین — تنظیمات و دسترسی‌ها | 1440×900 | `/admin/settings` | — |
| `AdminTranslations` | ادمین — جریان ترجمه و انتشار | 1440×900 | `/admin/translations` | AdminTitleEdit |
| `AdminAnalytics` | ادمین — تحلیل‌ها | 1440×900 | `/admin/analytics` | — |
| `AdminActivityLog` | ادمین — گزارش فعالیت | 1440×900 | `/admin/activity-log` | AdminUserDetail |
| `AdminUserDetail` | ادمین — جزئیات کاربر | 1440×900 | `/admin/user-detail` | AdminUsers |
| `AdminFinance` | ادمین — گزارش مالی و فاکتورها | 1440×900 | `/admin/finance` | AdminSubscriptions |
| `AdminRequests` | ادمین — درخواست آثار | 1440×900 | `/admin/requests` | — |
| `AdminLogin` | ادمین — ورود دومرحله‌ای | 1440×900 | `/admin/login` | AdminDashboard, AdminMobile |

## طراحی‌های اصلی (مرجع) (9)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `OrigSplash` | اسپلش | 393×852 | `—` | OrigOnboarding1 |
| `OrigOnboarding1` | معرفی ۱ — دانلود و تماشا | 393×852 | `—` | OrigOnboarding2 |
| `OrigOnboarding2` | معرفی ۲ — کامل‌ترین آرشیو | 393×852 | `—` | OrigOnboarding3 |
| `OrigOnboarding3` | معرفی ۳ — فارسی و انگلیسی | 393×852 | `—` | OrigLogin |
| `OrigLogin` | ورود | 393×852 | `—` | ForgotPassword, OrigOTP, OrigSignup |
| `OrigSignup` | ثبت نام | 393×852 | `—` | OrigLogin, OrigOTP |
| `OrigOTP` | کد تأیید ایمیل | 393×852 | `—` | OrigHome |
| `OrigHome` | خانه | 393×852 | `—` | Library, ListAll, Main, Notifications, OrigDetail, Profile, RequestTitle |
| `OrigDetail` | جزئیات مانگا | 393×852 | `—` | AuthorPage, Comments, OrigHome, Paywall, Reader |

## حالت روشن (56)

هر صفحه `LightX` نسخه روشن صفحه `X` است با همان ساختار؛ فقط رنگ‌ها از توکن‌های تم روشن می‌آیند. در کد نباید جدا ساخته شوند — یک صفحه با دو تم.

`LightHome`، `LightDetail`، `LightLibrary`، `LightProfile`، `LightMain`، `LightSearch`، `LightReader`، `LightReaderSettings`، `LightComments`، `LightNotifications`، `LightSubscription`، `LightForgotPassword`، `LightComicDetail`، `LightPaywall`، `LightEmptyLibrary`، `LightNoResults`، `LightLoading`، `LightOffline`، `LightDownloads`، `LightPaymentResult`، `LightOnboardingPrefs`، `LightHomeTypes`، `LightReaderWebtoon`، `LightRequestTitle`، `LightEditProfile`، `LightPaymentHistory`، `LightCommentThread`، `LightAuthorPage`، `LightListAll`، `LightPaymentPending`، `LightManageSubscription`، `LightAuthLogin`، `LightAuthSignup`، `LightAuthOTP`، `LightLegal`، `LightHelpCenter`، `LightReportProblem`، `LightNotificationSettings`، `LightInviteFriends`، `LightAppUpdate`، `LightMaintenance`، `LightAdminDashboard`، `LightAdminTitles`، `LightAdminTitleEdit`، `LightAdminUsers`، `LightAdminUserDetail`، `LightAdminSubscriptions`، `LightAdminFinance`، `LightAdminComments`، `LightAdminRequests`، `LightAdminNotify`، `LightAdminSettings`، `LightAdminTranslations`، `LightAdminAnalytics`، `LightAdminActivityLog`، `LightAdminLogin`

## دیزاین سیستم (10)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `DSFoundations` | ۱ — مبانی | 1440×1560 | `—` | LightDSFoundations |
| `DSComponents` | ۲ — کامپوننت‌های پایه | 1440×1640 | `—` | LightDSComponents |
| `DSPatterns` | ۳ — الگوها | 1440×1500 | `—` | LightDSPatterns |
| `DSAccessibility` | ۴ — دسترس‌پذیری | 1440×1400 | `—` | LightDSAccessibility |
| `DSMotion` | ۵ — حرکت و آیکون اپ | 1440×1320 | `—` | LightDSMotion |
| `LightDSFoundations` | ۱ — مبانی — روشن | 1440×1560 | `—` | DSFoundations |
| `LightDSComponents` | ۲ — کامپوننت‌های پایه — روشن | 1440×1640 | `—` | DSComponents |
| `LightDSPatterns` | ۳ — الگوها — روشن | 1440×1500 | `—` | DSPatterns |
| `LightDSAccessibility` | ۴ — دسترس‌پذیری — روشن | 1440×1400 | `—` | DSAccessibility |
| `LightDSMotion` | ۵ — حرکت و آیکون اپ — روشن | 1440×1320 | `—` | DSMotion |

## تحویل (6)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `UserFlow` | نقشه جریان کاربر | 3000×1720 | `—` | AdminLogin, AppUpdate, AuthLogin, AuthOTP, AuthSignup, AuthorPage, CommentThread, Comments, Downloads, EditProfile, EmptyLibrary, ForgotPassword, HelpCenter, HomeTypes, InviteFriends, Legal, Library, ListAll, Loading, Main, Maintenance, ManageSubscription, NoResults, NotificationSettings, Notifications, Offline, OnboardingPrefs, OrigDetail, OrigOnboarding1, OrigSplash, PaymentHistory, PaymentPending, PaymentResult, Paywall, Profile, Reader, ReaderLandscape, ReaderSettings, ReportProblem, RequestTitle, Search, Subscription, TabletReader |
| `DSSpecs` | مشخصات فنی — دکمه، فیلد، ردیف چپتر | 1440×1640 | `—` | — |
| `DSSpecs2` | مشخصات فنی — بقیه کامپوننت‌ها | 1440×1500 | `—` | — |
| `UsabilityTest` | برنامه تست کاربردپذیری | 1440×1400 | `—` | — |
| `UXCopy` | راهنمای متن و لحن | 1440×1380 | `—` | — |
| `APIMap` | نقشه API صفحات | 1440×1700 | `—` | — |

## بازاریابی (3)

| نام | عنوان | اندازه | مسیر پیشنهادی | لینک‌ها |
|---|---|---|---|---|
| `StoreShots` | اسکرین‌شات‌های فروشگاه اپ | 1860×820 | `—` | — |
| `LandingPage` | صفحه فرود معرفی اپ | 1440×2160 | `—` | — |
| `SocialBanner` | بنر شبکه‌های اجتماعی (۱۰۸۰×۱۰۸۰) | 1080×1080 | `—` | — |
