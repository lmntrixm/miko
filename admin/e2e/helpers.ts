import { expect, type Page } from '@playwright/test';
import { totp } from '../src/server/auth';

export const DEMO_TOTP_SECRET = 'JBSWY3DPEHPK3PXP';

export async function login(page: Page) {
  await page.goto('/login');
  await page.getByLabel('ایمیل سازمانی').fill('admin@miko.test');
  await page.getByLabel('رمز عبور').fill('password123');
  await page.getByRole('button', { name: 'ادامه' }).click();
  const digits = totp(DEMO_TOTP_SECRET);
  for (let i = 0; i < 6; i++) await page.getByLabel(`رقم ${i + 1}`).fill(digits[i]);
  await page.getByRole('button', { name: 'ورود', exact: true }).click();
  await expect(page).toHaveURL(/\/dashboard/);
}
