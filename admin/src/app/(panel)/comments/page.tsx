'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Avatar, Badge, Button, Confirm, Empty, PageHead, Segmented, Toggle } from '@/components/ui';
import { faDigits, faNumber, relative } from '@/lib/format';
import { moderate, setAutomation, setBlocked, useStore } from '@/lib/store';
import { weekStats } from '@/lib/stats';
import type { CommentItem } from '@/lib/types';

const TAG: Record<string, string> = { spoiler: 'اسپویل', link: 'لینک', spam: 'اسپم', insult: 'توهین' };
type Tab = 'reported' | 'pending' | 'all';

export default function CommentsPage() {
  const comments = useStore((s) => s.comments);
  const users = useStore((s) => s.users);
  const auto = useStore((s) => s.automation);
  const toast = useToast();
  const [tab, setTab] = useState<Tab>('reported');
  const [del, setDel] = useState<CommentItem | null>(null);
  const [word, setWord] = useState('');

  const open = comments.filter((c) => c.status === 'reported' || c.status === 'pending');
  const rows = comments.filter((c) => c.status !== 'deleted' && (tab === 'all' ? true : tab === 'reported' ? c.status === 'reported' : c.status === 'pending'));

  const blockAuthor = (c: CommentItem) => {
    const u = users.find((x) => x.name === c.user);
    if (u) setBlocked(u.id, true);
    moderate(c.id, 'blockUser');
    toast(`«${c.user}» مسدود شد`);
  };

  return (
    <>
      <PageHead title="نظرات و گزارش‌ها" sub={`${faDigits(open.length)} مورد در انتظار بررسی`}>
        <Segmented label="نوع نظرات" value={tab} onChange={setTab} items={[{ id: 'reported', label: 'گزارش‌شده' }, { id: 'pending', label: 'در انتظار تأیید' }, { id: 'all', label: 'همه نظرات' }]} />
      </PageHead>
      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', alignItems: 'start' }}>
        <div className="stack">
          {rows.length === 0 && <section className="card"><Empty>نظری برای بررسی نیست.</Empty></section>}
          {rows.map((c) => (
            <article key={c.id} className="card stack" aria-label={`نظر ${c.user}`}>
              <div className="row" style={{ justifyContent: 'space-between' }}>
                <div className="row"><Avatar name={c.user} /><div><b>{c.user}</b><div className="sub">{c.work} · چپتر {faDigits(c.chapter)} · {relative(c.when)}</div></div></div>
                <div className="row" style={{ gap: 6 }}>
                  {c.tags.map((t) => <Badge key={t} kind="tag">{TAG[t]}</Badge>)}
                  {c.reports > 0 && <Badge kind="neutral">{faDigits(c.reports)} گزارش</Badge>}
                </div>
              </div>
              <p className="card" style={{ background: 'var(--surface-sunken)', margin: 0 }}>{c.body}</p>
              <div className="row">
                <Button variant="ok" size="sm" onClick={() => { moderate(c.id, 'approve'); toast('نظر تأیید و نگه داشته شد'); }}>✓ تأیید و نگه‌داشتن</Button>
                <Button variant="warn" size="sm" onClick={() => { moderate(c.id, 'spoiler'); toast('علامت اسپویل زده شد'); }}>علامت اسپویل</Button>
                <Button variant="danger" size="sm" onClick={() => setDel(c)}>حذف نظر</Button>
                <span className="spacer" />
                <Button size="sm" onClick={() => blockAuthor(c)}>مسدود کردن کاربر</Button>
              </div>
            </article>
          ))}
        </div>
        <div className="stack">
          <section className="card stack" aria-labelledby="ws">
            <h2 id="ws">آمار این هفته</h2>
            {([['نظرات جدید', weekStats.newComments], ['گزارش‌شده', weekStats.reported], ['حذف‌شده', weekStats.deleted], ['کاربران مسدودشده', weekStats.blockedUsers]] as const).map(([l, v]) => (
              <div key={l} className="row" style={{ justifyContent: 'space-between' }}><span className="muted">{l}</span><b>{faNumber(v)}</b></div>
            ))}
          </section>
          <section className="card stack" aria-labelledby="rules">
            <h2 id="rules">قوانین خودکار</h2>
            <label className="row" style={{ justifyContent: 'space-between', flexWrap: 'nowrap' }}>مخفی کردن خودکار نظر با ۵ گزارش اسپویل <Toggle label="مخفی کردن خودکار" checked={auto.hideAfterReports} onChange={(v) => setAutomation({ hideAfterReports: v })} /></label>
            <label className="row" style={{ justifyContent: 'space-between', flexWrap: 'nowrap' }}>مسدود کردن نظرات حاوی لینک <Toggle label="مسدود کردن لینک" checked={auto.blockLinks} onChange={(v) => setAutomation({ blockLinks: v })} /></label>
            <label className="row" style={{ justifyContent: 'space-between', flexWrap: 'nowrap' }}>تأیید دستی نظرات کاربران جدید <Toggle label="تأیید دستی" checked={auto.manualApprove} onChange={(v) => setAutomation({ manualApprove: v })} /></label>
          </section>
          <section className="card stack" aria-labelledby="fw">
            <h2 id="fw">کلمات فیلترشده</h2>
            <div className="row" style={{ gap: 6 }}>
              {auto.filterWords.map((w) => <span key={w} className="chip tag">{w}<button aria-label={`حذف ${w}`} onClick={() => setAutomation({ filterWords: auto.filterWords.filter((x) => x !== w) })}>×</button></span>)}
            </div>
            <input className="input" aria-label="افزودن کلمه" placeholder="افزودن کلمه…" value={word} onChange={(e) => setWord(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && word.trim() && !auto.filterWords.includes(word.trim())) { setAutomation({ filterWords: [...auto.filterWords, word.trim()] }); setWord(''); } }} />
          </section>
        </div>
      </div>
      <Confirm open={!!del} danger title="حذف نظر" confirm="حذف نظر" onClose={() => setDel(null)} body={<>نظر «{del?.user}» حذف می‌شود و برگشت ندارد.</>} onConfirm={() => { if (del) { moderate(del.id, 'delete'); toast('نظر حذف شد'); } }} />
    </>
  );
}
