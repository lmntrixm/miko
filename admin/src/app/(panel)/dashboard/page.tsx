'use client';

import Link from 'next/link';
import { useState } from 'react';
import { BarChart } from '@/components/Charts';
import { Icon } from '@/components/Icon';
import { Badge, PageHead, SearchBox, Segmented, StatTile } from '@/components/ui';
import { amountPlaceholder } from '@/lib/labels';
import { faDigits, faNumber, jalaliDate, NOW } from '@/lib/format';
import { dailyReads, dashboardTiles, popularThisWeek, recentActivity, scheduled } from '@/lib/stats';
import { useStore } from '@/lib/store';

type Range = '7' | '14' | '30';

export default function DashboardPage() {
  const [range, setRange] = useState<Range>('14');
  const [q, setQ] = useState('');
  const titles = useStore((s) => s.titles);
  const hits = q.trim() ? titles.filter((t) => t.nameFa.includes(q.trim()) || t.nameEn.toLowerCase().includes(q.trim().toLowerCase())).slice(0, 4) : [];
  const n = Number(range);
  const data = dailyReads.slice(0, n);
  const t = dashboardTiles;

  return (
    <>
      <PageHead title="داشبورد" sub={`${new Intl.DateTimeFormat('fa-IR', { weekday: 'long' }).format(NOW)} ${jalaliDate(NOW)}`}>
        <div style={{ position: 'relative' }}>
          <SearchBox value={q} onChange={setQ} placeholder="جستجو در آثار، کاربران…" />
          {hits.length > 0 && (
            <ul className="card" role="listbox" aria-label="نتایج جستجو" style={{ position: 'absolute', insetInlineStart: 0, insetInlineEnd: 0, top: 48, zIndex: 5, listStyle: 'none', margin: 0, padding: 8 }}>
              {hits.map((h) => (
                <li key={h.id}>
                  <Link href={`/titles/${h.id}`} style={{ display: 'block', padding: '6px 8px' }}>{h.nameFa} <span className="muted ltr">{h.nameEn}</span></Link>
                </li>
              ))}
            </ul>
          )}
        </div>
        <Link href="/upload" className="btn primary"><Icon name="plus" size={18} /> چپتر جدید</Link>
      </PageHead>

      <div className="grid g4" style={{ marginBottom: 'var(--space-4)' }}>
        <StatTile label="کاربران فعال امروز" value={faNumber(t.activeToday)} delta={`${faDigits(t.activeDelta)}٪ نسبت به دیروز`} up />
        <StatTile label="اشتراک‌های فعال" value={faNumber(t.subscriptions)} delta={`${faNumber(t.newSubs)} اشتراک جدید این هفته`} up />
        <StatTile label="درآمد این ماه" value={amountPlaceholder} foot="تومان" />
        <StatTile label="چپترهای منتشرشده این ماه" value={faNumber(t.publishedThisMonth)} delta={`${faDigits(Math.abs(t.publishedDelta))}٪ نسبت به ماه قبل`} up={t.publishedDelta >= 0} />
      </div>

      <div className="grid g-main-side" style={{ marginBottom: 'var(--space-4)', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)' }}>
        <section className="card" aria-labelledby="reads">
          <div className="card-head">
            <h2 id="reads">چپترهای خوانده‌شده، {faDigits(n)} روز اخیر</h2>
            <Segmented label="بازه" value={range} onChange={setRange} items={[{ id: '7', label: '۷ روز' }, { id: '14', label: '۱۴ روز' }, { id: '30', label: '۳۰ روز' }]} />
          </div>
          <BarChart data={data} labels={['امروز', `${faDigits(Math.round(n / 2))} روز پیش`, `${faDigits(n)} روز پیش`]} label="چپترهای خوانده‌شده در روز" />
        </section>
        <section className="card" aria-labelledby="popular">
          <div className="card-head">
            <h2 id="popular">محبوب‌ترین‌های هفته</h2>
            <Link href="/analytics" className="sub">همه ›</Link>
          </div>
          <ol className="stack" style={{ listStyle: 'none', padding: 0, margin: 0, gap: 10 }}>
            {popularThisWeek.map((p, i) => (
              <li key={p.titleId} className="row" style={{ flexWrap: 'nowrap' }}>
                <b style={{ color: 'var(--red-400)', width: 18 }}>{faDigits(i + 1)}</b>
                <span className="cover" style={{ width: 32, height: 44 }} aria-hidden="true" />
                <div style={{ flex: 1 }}>
                  <Link href={`/titles/${p.titleId}`} style={{ color: 'var(--text-primary)', fontWeight: 700 }}>{p.name}</Link>
                  <div className="sub">{p.type}</div>
                </div>
                <span className="muted">{faNumber(p.reads)}</span>
              </li>
            ))}
          </ol>
        </section>
      </div>

      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,2fr)' }}>
        <section className="card" aria-labelledby="act">
          <h2 id="act">فعالیت‌های اخیر</h2>
          <ul className="stack" style={{ listStyle: 'none', padding: 0, margin: 0, gap: 10 }}>
            {recentActivity.map((a) => (
              <li key={a.text} className="row" style={{ flexWrap: 'nowrap', alignItems: 'baseline' }}>
                <i className="dot" style={{ background: a.dot }} aria-hidden="true" />
                <span style={{ flex: 1 }}>{a.text}</span>
                <span className="sub">{a.ago}</span>
              </li>
            ))}
          </ul>
        </section>
        <section className="card flush" aria-labelledby="sched">
          <h2 id="sched" style={{ padding: 'var(--space-5) var(--space-5) 0' }}>انتشارهای زمان‌بندی‌شده</h2>
          <div className="table-wrap">
            <table className="t">
              <thead><tr><th>اثر / چپتر</th><th>زبان</th><th>زمان انتشار</th><th>صفحات</th><th>وضعیت</th></tr></thead>
              <tbody>
                {scheduled.map((s) => (
                  <tr key={s.chapter}>
                    <td><b>{s.chapter}</b></td>
                    <td>{s.lang}</td>
                    <td>{s.when}</td>
                    <td>{faDigits(s.pages)}</td>
                    <td>{s.status === 'ready' ? <Badge kind="success">آماده</Badge> : <Badge kind="warning">در انتظار ترجمه</Badge>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </>
  );
}
