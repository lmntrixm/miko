import type { Metadata } from 'next';
import localFont from 'next/font/local';
import '@/styles/globals.css';
import { ToastProvider } from '@/components/Toast';

const vazirmatn = localFont({
  src: [
    { path: '../fonts/Vazirmatn-Regular.ttf', weight: '400' },
    { path: '../fonts/Vazirmatn-Medium.ttf', weight: '500' },
    { path: '../fonts/Vazirmatn-Bold.ttf', weight: '700' },
    { path: '../fonts/Vazirmatn-Black.ttf', weight: '900' },
  ],
  variable: '--font-vazirmatn',
  display: 'swap',
});

export const metadata: Metadata = {
  title: { default: 'میکو · پنل مدیریت', template: '%s · پنل میکو' },
  robots: { index: false, follow: false },
};

// Runs before paint so the saved theme never flashes. Dark is the default.
const themeScript = `try{var t=localStorage.getItem('miko_admin_theme');document.documentElement.dataset.theme=t==='light'?'light':'dark'}catch(e){document.documentElement.dataset.theme='dark'}`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl" data-theme="dark" className={vazirmatn.variable} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body>
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
