import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  fullyParallel: false,
  workers: 1,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:3100',
    viewport: { width: 1440, height: 900 },
    locale: 'fa-IR',
    // Locally: the pre-installed browser (never download one). On CI: the one Playwright installs.
    launchOptions: { executablePath: process.env.CI ? undefined : (process.env.CHROMIUM_PATH ?? '/opt/pw-browsers/chromium-1194/chrome-linux/chrome') },
  },
  webServer: {
    command: 'npx next start -p 3100',
    env: { ADMIN_DEMO: '1', INSECURE_COOKIES: '1' },
    url: 'http://localhost:3100/login',
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
