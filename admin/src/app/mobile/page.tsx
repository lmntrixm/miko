'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useToast } from '@/components/Toast';
import { Badge, Button } from '@/components/ui';
import { faDigits, faNumber, relative } from '@/lib/format';
import { dashboardTiles } from '@/lib/stats';
import { hydrate, moderate, moveTask, useStore } from '@/lib/store';

/** Approval queue for phones: publish, comment moderation and translation sign-off. */
export default function MobileQueue() {
  const router = useRouter();
  const session = useStore((s) => s.session);
  const tasks = useStore((s) => s.tasks);
  const comments = useStore((s) => s.comments);
  const toast = useToast();
  const [ready, setReady] = useState(false);
  const [skipped, setSkipped] = useState<string[]>([]);

  useEffect(() => { hydrate(); setReady(true); }, []);
  useEffect(() => { if (ready && !session) router.replace('/login'); }, [ready, session, router]);
  if (!ready || !session) return <div aria-busy="true" />;

  const publish = tasks.filter((t) => t.column === 'ready' && !skipped.includes(t.id));
  const reported = comments.filter((c) => c.status === 'reported' && !skipped.includes(c.id));
  const review = tasks.filter((t) => t.column === 'review' && !skipped.includes(t.id));
  const total = publish.length + reported.length + review.length;

  return (
    <main style={{ maxWidth: 480, margin: '0 auto', padding: 16, paddingBottom: 80 }}>
      <header className="row" style={{ justifyContent: 'space-between', marginBottom: 16 }}>
        <div><h1 style={{ fontSize: 22 }}>پنل ادمین</h1><span className="sub">{faDigits(total)} کار منتظر شماست</span></div>
        <span className="brand-mark" aria-hidden="true">م</span>
      </header>
      <div className="grid g3" style={{ marginBottom: 16 }}>
        <div className="tile"><div className="value" style={{ fontSize: 20 }}>{faNumber(dashboardTiles.activeToday)}</div><div className="label">فعال امروز</div></div>
        <div className="tile"><div className="value" style={{ fontSize: 20 }}>{faNumber(42)}</div><div className="label">اشتراک امروز</div></div>
        <div className="tile"><div className="value" style={{ fontSize: 20, color: 'var(--warning)' }}>{faDigits(comments.filter((c) => c.status === 'reported').length)}</div><div className="label">گزارش باز</div></div>
      </div>
      <h2 style={{ marginBottom: 8 }}>صف تأیید</h2>
      <div className="stack">
        {total === 0 && <p className="muted card">صف خالی است. 🎉</p>}
        {publish.map((t) => (
          <article key={t.id} className="queue-card" aria-label={`انتشار ${t.titleName}`}>
            <div className="row" style={{ justifyContent: 'space-between' }}><Badge kind="success">انتشار</Badge><span className="sub">{relative(t.due)}</span></div>
            <b>{t.titleName} · چپتر {faDigits(t.chapter)}</b>
            <div className="grid g2"><Button variant="primary" onClick={() => { moveTask(t.id, 'ready'); toast('چپتر منتشر شد'); setSkipped((s) => [...s, t.id]); }}>انتشار</Button><Button onClick={() => setSkipped((s) => [...s, t.id])}>بعداً</Button></div>
          </article>
        ))}
        {reported.map((c) => (
          <article key={c.id} className="queue-card" aria-label={`نظر گزارش‌شده ${c.user}`}>
            <div className="row" style={{ justifyContent: 'space-between' }}><Badge kind="danger">نظر گزارش‌شده</Badge><span className="sub">{relative(c.when)}</span></div>
            <b>{c.work} · {faDigits(c.chapter)}</b>
            <p className="muted" style={{ margin: 0 }}>«{c.body}» · {faDigits(c.reports)} گزارش</p>
            <div className="grid g2"><Button variant="primary" onClick={() => { moderate(c.id, 'delete'); toast('نظر حذف شد'); }}>حذف نظر</Button><Button onClick={() => { moderate(c.id, 'approve'); toast('نظر نگه داشته شد'); }}>نگه‌داشتن</Button></div>
          </article>
        ))}
        {review.map((t) => (
          <article key={t.id} className="queue-card" aria-label={`بازبینی ${t.titleName}`}>
            <div className="row" style={{ justifyContent: 'space-between' }}><Badge kind="warning">ترجمه</Badge><span className="sub">{relative(t.due)}</span></div>
            <b>{t.titleName} · چپتر {faDigits(t.chapter)}</b>
            <p className="muted" style={{ margin: 0 }}>{t.note ?? 'منتظر تأیید ویراستار'}</p>
            <div className="grid g2"><Button variant="primary" onClick={() => { moveTask(t.id, 'ready'); toast('تأیید شد'); }}>تأیید</Button><Button onClick={() => { moveTask(t.id, 'translating'); toast('برگشت داده شد'); }}>برگشت</Button></div>
          </article>
        ))}
      </div>
      <nav aria-label="منوی موبایل" style={{ position: 'fixed', insetInline: 0, bottom: 0, background: 'var(--bg-nav)', borderTop: '1px solid var(--border-1)', display: 'flex', justifyContent: 'space-around', padding: '12px 0' }}>
        <a aria-current="page" style={{ color: 'var(--red-400)' }} href="/mobile">صف تأیید</a>
        <a href="/comments">نظرات</a><a href="/users">کاربران</a><a href="/settings">تنظیمات</a>
      </nav>
    </main>
  );
}
