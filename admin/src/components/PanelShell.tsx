'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState, type ReactNode } from 'react';
import { Icon, type IconName } from './Icon';
import { Avatar } from './ui';
import { faDigits } from '@/lib/format';
import { hydrate, logout, setTheme, useStore } from '@/lib/store';

const NAV: { href: string; label: string; icon: IconName; badge?: 'requests' | 'comments' }[] = [
  { href: '/dashboard', label: 'داشبورد', icon: 'grid' },
  { href: '/titles', label: 'آثار', icon: 'book' },
  { href: '/upload', label: 'آپلود چپتر', icon: 'upload' },
  { href: '/translations', label: 'ترجمه و انتشار', icon: 'kanban' },
  { href: '/requests', label: 'درخواست آثار', icon: 'plusCircle', badge: 'requests' },
  { href: '/users', label: 'کاربران', icon: 'users' },
  { href: '/subscriptions', label: 'اشتراک و پرداخت', icon: 'card' },
  { href: '/finance', label: 'گزارش مالی', icon: 'receipt' },
  { href: '/comments', label: 'نظرات و گزارش‌ها', icon: 'chat', badge: 'comments' },
  { href: '/analytics', label: 'تحلیل‌ها', icon: 'chart' },
  { href: '/notify', label: 'ارسال اعلان', icon: 'bell' },
  { href: '/activity-log', label: 'گزارش فعالیت', icon: 'clock' },
  { href: '/settings', label: 'تنظیمات', icon: 'gear' },
];

/** Sidebar + auth gate for every panel page. Unauthenticated visitors are sent to /login (client-side mock). */
export function PanelShell({ children }: { children: ReactNode }) {
  const path = usePathname();
  const router = useRouter();
  const session = useStore((s) => s.session);
  const openRequests = useStore((s) => s.requests.filter((r) => r.status === 'open').length);
  const toReview = useStore((s) => s.comments.filter((c) => c.status === 'reported' || c.status === 'pending').length);
  const [ready, setReady] = useState(false);
  const [theme, setT] = useState<'dark' | 'light'>('dark');

  useEffect(() => {
    hydrate();
    setReady(true);
    setT(document.documentElement.dataset.theme === 'light' ? 'light' : 'dark');
  }, []);

  useEffect(() => {
    if (ready && !session) router.replace('/login');
  }, [ready, session, router]);

  if (!ready || !session) return <div className="main" aria-busy="true" />;

  const badges = { requests: openRequests, comments: toReview };
  const flip = () => {
    const n = theme === 'dark' ? 'light' : 'dark';
    setTheme(n);
    setT(n);
  };

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">م</span>
          <div>
            <b style={{ display: 'block' }}>میکو</b>
            <span className="sub">پنل مدیریت</span>
          </div>
        </div>
        <nav className="nav" aria-label="منوی اصلی">
          {NAV.map((n) => {
            const active = path === n.href || path.startsWith(n.href + '/') || (n.href === '/titles' && path.startsWith('/titles'));
            const count = n.badge ? badges[n.badge] : 0;
            return (
              <Link key={n.href} href={n.href} aria-current={active ? 'page' : undefined}>
                <Icon name={n.icon} />
                {n.label}
                {count > 0 && (
                  <span className="count" aria-label={`${faDigits(count)} مورد`}>
                    {faDigits(count)}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
        <div className="row" style={{ justifyContent: 'space-between', padding: '8px 4px' }}>
          <span className="sub">{theme === 'dark' ? 'تم تیره' : 'تم روشن'}</span>
          <button className="iconbtn" onClick={flip} aria-label={theme === 'dark' ? 'تغییر به تم روشن' : 'تغییر به تم تیره'}>
            <Icon name={theme === 'dark' ? 'sun' : 'moon'} size={16} />
          </button>
        </div>
        <div className="userbox">
          <Avatar name={session.name} size="sm" color="var(--red-700)" />
          <div className="who">
            <b>{session.name}</b>
            <span className="sub">مدیر کل</span>
          </div>
          <button
            className="iconbtn"
            aria-label="خروج از پنل"
            onClick={() => {
              logout();
              router.replace('/login');
            }}
          >
            <Icon name="logout" size={16} />
          </button>
        </div>
      </aside>
      <main className="main" id="main">
        {children}
      </main>
    </div>
  );
}
