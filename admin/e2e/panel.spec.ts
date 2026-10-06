import { expect, test } from '@playwright/test';
import { login } from './helpers';

test('unauthenticated visitors are sent to login; wrong credentials and wrong code are explained', async ({ page }) => {
  await page.goto('/titles');
  await expect(page).toHaveURL(/\/login/);
  await page.getByLabel('ایمیل سازمانی').fill('nope');
  await page.getByLabel('رمز عبور').fill('x');
  await page.getByRole('button', { name: 'ادامه' }).click();
  await expect(page.locator('[role=alert].err, p.err[role=alert]')).toContainText('ایمیل معتبر نیست');
  await page.getByLabel('ایمیل سازمانی').fill('admin@miko.test');
  await page.getByLabel('رمز عبور').fill('wrong-pass');
  await page.getByRole('button', { name: 'ادامه' }).click();
  await expect(page.locator('[role=alert].err, p.err[role=alert]')).toContainText('ایمیل یا رمز عبور درست نیست');
  await page.getByLabel('رمز عبور').fill('password123');
  await page.getByRole('button', { name: 'ادامه' }).click();
  await expect(page.getByText('کد تأیید دومرحله‌ای')).toBeVisible();
  for (let i = 0; i < 6; i++) await page.getByLabel(`رقم ${i + 1}`).fill('9');
  await page.getByRole('button', { name: 'ورود', exact: true }).click();
  await expect(page.locator('[role=alert].err, p.err[role=alert]')).toContainText('کد درست نیست');
});

test('dashboard, sidebar and range switch', async ({ page }) => {
  await login(page);
  await expect(page.getByRole('heading', { name: 'داشبورد' })).toBeVisible();
  await expect(page.getByRole('navigation', { name: 'منوی اصلی' }).getByRole('link')).toHaveCount(13);
  await expect(page.getByText('[مبلغ]').first()).toBeVisible();
  await page.getByRole('button', { name: '۷ روز' }).click();
  await expect(page.getByRole('heading', { name: /۷ روز اخیر/ })).toBeVisible();
});

test('titles: filter, search, paginate, export, add and delete', async ({ page }) => {
  await login(page);
  await page.getByRole('link', { name: 'آثار', exact: true }).click();
  await expect(page.getByText('۲۲ اثر')).toBeVisible();
  await page.getByRole('button', { name: 'کامیک' }).click();
  await expect(page.getByRole('link', { name: 'بندر آهنین' }).first()).toBeVisible();
  await expect(page.getByText('شمشیر سپیده')).toHaveCount(0);
  await page.getByRole('button', { name: 'همه', exact: true }).click();
  await expect(page.getByRole('navigation', { name: 'صفحه‌بندی' })).toBeVisible();
  await page.getByRole('button', { name: 'صفحه ۲' }).click();
  await expect(page.getByText(/نمایش ۹ تا ۱۶ از ۲۲/)).toBeVisible();
  await page.getByRole('searchbox', { name: 'جستجوی نام اثر…' }).fill('Zzz');
  await expect(page.getByText('اثری با این فیلترها پیدا نشد.')).toBeVisible();
  await page.getByRole('searchbox', { name: 'جستجوی نام اثر…' }).fill('');

  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'خروجی Excel' }).click();
  expect((await download).suggestedFilename()).toBe('titles.csv');

  await page.getByRole('button', { name: 'افزودن اثر' }).click();
  await page.getByLabel('نام فارسی').fill('اثر آزمایشی');
  await page.getByLabel('نام انگلیسی').fill('Test Title');
  await page.getByRole('button', { name: 'ساخت پیش‌نویس' }).click();
  await expect(page).toHaveURL(/\/titles\/test-title/);
  await expect(page.getByRole('heading', { name: 'ویرایش اثر و آپلود چپتر' })).toBeVisible();
});

test('chapter upload validates files and adds the chapter', async ({ page }) => {
  await login(page);
  await page.goto('/titles/dawn-blade');
  await page.getByRole('button', { name: 'ذخیرهٔ چپتر' }).count();
  await page.getByLabel('انتخاب فایل صفحات').setInputFiles({ name: 'notes.txt', mimeType: 'text/plain', buffer: Buffer.from('x') });
  await expect(page.locator('[role=alert].err, p.err[role=alert]')).toContainText('پذیرفته نشد');
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
  await page.getByLabel('انتخاب فایل صفحات').setInputFiles([{ name: '2.png', mimeType: 'image/png', buffer: png }, { name: '1.png', mimeType: 'image/png', buffer: png }]);
  await expect(page.getByText(/۲ فایل بارگذاری شد/)).toBeVisible();
  await page.getByLabel('شمارهٔ چپتر').fill('244');
  await page.getByRole('button', { name: 'ذخیرهٔ چپتر' }).click();
  await expect(page.getByText('چپتر ذخیره شد')).toBeVisible();
  await expect(page.getByText('#244')).toBeVisible();
});

test('translation board: move a card, filter by assignee', async ({ page }) => {
  await login(page);
  await page.goto('/translations');
  const waiting = page.getByRole('region', { name: 'در انتظار ترجمه' });
  await expect(waiting.getByText('وارث سرخ')).toBeVisible();
  await page.getByLabel('انتقال وارث سرخ ۵۷').selectOption('translating');
  await expect(page.getByRole('region', { name: 'در حال ترجمه' }).getByText('وارث سرخ')).toBeVisible();
  await page.getByRole('button', { name: 'کارهای سارا' }).click();
  await expect(page.getByText('بندر آهنین')).toHaveCount(0);
});

test('requests: needs publish right to be added; rejecting asks first', async ({ page }) => {
  await login(page);
  await page.goto('/requests');
  const rows = page.getByRole('row');
  await expect(rows.filter({ hasText: 'Sample Request A' }).getByRole('button', { name: 'افزودن به آثار' })).toBeDisabled();
  await rows.filter({ hasText: 'Sample Request B' }).getByRole('button', { name: 'افزودن به آثار' }).click();
  await expect(page.getByText(/به آثار \(پیش‌نویس\) اضافه شد/)).toBeVisible();
  await rows.filter({ hasText: 'Sample Request C' }).getByRole('button', { name: 'رد و اطلاع' }).click();
  await page.getByRole('button', { name: 'رد و اطلاع‌رسانی' }).click();
  await page.getByRole('button', { name: 'ردشده' }).click();
  await expect(page.getByText('Sample Request C')).toBeVisible();
});

test('users: select, add days, block, open the full file', async ({ page }) => {
  await login(page);
  await page.goto('/users');
  await page.getByRole('row', { name: /کاربر نمونه ۲/ }).click();
  await page.getByRole('button', { name: 'افزودن روز اشتراک' }).click();
  await page.getByLabel(/تعداد روز/).fill('10');
  await page.getByRole('button', { name: 'افزودن', exact: true }).click();
  await expect(page.getByText('۲۲۰ روز دیگر').first()).toBeVisible();
  await page.getByRole('button', { name: 'مسدود کردن' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'مسدود کردن' }).click();
  await expect(page.locator('.badge', { hasText: 'مسدود' }).first()).toBeVisible();
  await page.getByRole('link', { name: /مشاهده پروندهٔ کامل/ }).click();
  await expect(page.getByRole('heading', { name: 'کاربر نمونه ۲' })).toBeVisible();
  await page.getByText('+ افزودن یادداشت').click();
  await page.getByLabel('متن یادداشت').fill('یادداشت آزمایشی');
  await page.getByRole('button', { name: 'ثبت', exact: true }).click();
  await expect(page.getByText('یادداشت آزمایشی')).toBeVisible();
});

test('comments moderation, notify preview, settings permissions and audit trail', async ({ page }) => {
  await login(page);
  await page.goto('/comments');
  await page.getByRole('article', { name: 'نظر کاربر ۸۸۲۱' }).getByRole('button', { name: 'حذف نظر' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'حذف نظر' }).click();
  await expect(page.getByRole('article', { name: 'نظر کاربر ۸۸۲۱' })).toHaveCount(0);

  await page.goto('/notify');
  await page.getByLabel(/عنوان/).fill('چپتر جدید آمد');
  await page.getByLabel('متن اعلان').fill('همین حالا بخوانید');
  await expect(page.locator('.phone')).toContainText('چپتر جدید آمد');
  await page.getByRole('button', { name: 'ارسال اعلان' }).click();
  await expect(page.getByText(/ارسال شد/).first()).toBeVisible();

  await page.goto('/settings');
  const cb = page.getByRole('checkbox', { name: 'مدیریت کاربران برای ویراستار محتوا' });
  await expect(cb).toHaveAttribute('aria-checked', 'false');
  await cb.click();
  await expect(cb).toHaveAttribute('aria-checked', 'true');
  await expect(page.getByRole('checkbox', { name: 'مدیریت کاربران برای مدیر کل' })).toBeDisabled();

  await page.goto('/activity-log');
  await expect(page.getByText('دسترسی «مدیریت کاربران» را برای نقش داد')).toBeVisible();
  await expect(page.getByText('نظر «کاربر ۸۸۲۱» در دروازهٔ خاموش ۱۴۰ را حذف کرد')).toBeVisible();
  await page.getByRole('button', { name: 'تنظیمات', exact: true }).click();
  await expect(page.getByText('دسترسی «مدیریت کاربران»')).toBeVisible();
});

test('theme toggle persists and every page loads without console errors', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(e.message));
  await login(page);
  await page.getByRole('button', { name: 'تغییر به تم روشن' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  for (const p of ['dashboard', 'titles', 'upload', 'translations', 'requests', 'users', 'users/u1', 'subscriptions', 'finance', 'comments', 'analytics', 'notify', 'activity-log', 'settings', 'mobile']) {
    await page.goto(`/${p}`);
    await expect(page.locator('main, #main').first()).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  }
  expect(errors).toEqual([]);
});

test('mobile queue works on a phone viewport', async ({ page }) => {
  await login(page);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/mobile');
  await expect(page.getByRole('heading', { name: 'صف تأیید' })).toBeVisible();
  await page.getByRole('article', { name: /نظر گزارش‌شده/ }).first().getByRole('button', { name: 'نگه‌داشتن' }).click();
  await expect(page.getByText('نظر نگه داشته شد')).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(overflow).toBe(false);
});
