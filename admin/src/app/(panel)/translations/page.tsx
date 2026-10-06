'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Avatar, Badge, Button, Field, Modal, PageHead, Segmented } from '@/components/ui';
import { clock, faDigits, jalaliDate, NOW } from '@/lib/format';
import { COLUMN_DOT, COLUMN_LABEL } from '@/lib/labels';
import { addTask, COLUMN_ORDER, moveTask, useStore } from '@/lib/store';
import type { Task, TaskColumn } from '@/lib/types';

const ME = 'سارا';

function dueLabel(due: string) {
  const days = Math.round((new Date(due).getTime() - NOW.getTime()) / 86400000);
  if (days < 0) return 'دیروز';
  if (days === 0) return 'امروز';
  if (days === 1) return 'فردا';
  return `${faDigits(days)} روز`;
}

export default function TranslationsPage() {
  const tasks = useStore((s) => s.tasks);
  const toast = useToast();
  const [mine, setMine] = useState<'all' | 'mine'>('all');
  const [over, setOver] = useState<TaskColumn | null>(null);
  const [adding, setAdding] = useState(false);
  const [draft, setDraft] = useState({ titleName: '', chapter: '', direction: 'EN → FA', assignee: ME, due: '' });
  const [err, setErr] = useState('');

  const shown = tasks.filter((t) => mine === 'all' || t.assignee.startsWith(ME));
  const move = (id: string, col: TaskColumn) => { moveTask(id, col); toast(`به «${COLUMN_LABEL[col]}» منتقل شد`); };

  const create = () => {
    const n = Number(draft.chapter);
    if (!draft.titleName.trim() || !Number.isInteger(n) || n < 1) return setErr('نام اثر و شمارهٔ چپتر را درست وارد کنید.');
    if (!draft.due) return setErr('مهلت را مشخص کنید.');
    addTask({ titleName: draft.titleName.trim(), chapter: n, direction: draft.direction, assignee: draft.assignee, due: new Date(draft.due).toISOString() });
    toast('کار ترجمه ثبت شد');
    setAdding(false);
    setDraft({ titleName: '', chapter: '', direction: 'EN → FA', assignee: ME, due: '' });
  };

  return (
    <>
      <PageHead title="جریان ترجمه و انتشار" sub="هر چپتر از ترجمه تا انتشار این مسیر را طی می‌کند · کارت را با ماوس به ستون بعد ببرید یا از منوی «انتقال» استفاده کنید">
        <Segmented label="فیلتر کارها" value={mine} onChange={setMine} items={[{ id: 'all', label: 'همه کارها' }, { id: 'mine', label: `کارهای ${ME}` }]} />
        <Button variant="primary" icon="plus" onClick={() => { setErr(''); setAdding(true); }}>کار ترجمه جدید</Button>
      </PageHead>

      <div className="kanban">
        {COLUMN_ORDER.map((col) => {
          const list = shown.filter((t) => t.column === col);
          return (
            <section
              key={col}
              className={`kcol ${over === col ? 'over' : ''}`}
              aria-label={COLUMN_LABEL[col]}
              onDragOver={(e) => { e.preventDefault(); setOver(col); }}
              onDragLeave={() => setOver(null)}
              onDrop={(e) => { e.preventDefault(); setOver(null); const id = e.dataTransfer.getData('text/plain'); if (id) move(id, col); }}
            >
              <header>
                <i className="dot" style={{ background: COLUMN_DOT[col] }} aria-hidden="true" />
                <h3 style={{ flex: 1 }}>{COLUMN_LABEL[col]}</h3>
                <span className="badge neutral">{faDigits(list.length)}</span>
              </header>
              {list.map((t) => <Card key={t.id} t={t} onMove={move} />)}
              {list.length === 0 && <p className="sub" style={{ textAlign: 'center', paddingBlock: 24 }}>کاری نیست</p>}
            </section>
          );
        })}
      </div>

      <Modal open={adding} onClose={() => setAdding(false)} title="کار ترجمه جدید" footer={<><Button variant="primary" onClick={create}>ثبت کار</Button><Button onClick={() => setAdding(false)}>انصراف</Button></>}>
        <div className="stack">
          <Field label="نام اثر">{(id) => <input id={id} className="input" value={draft.titleName} onChange={(e) => setDraft({ ...draft, titleName: e.target.value })} />}</Field>
          <div className="grid g2">
            <Field label="شمارهٔ چپتر">{(id) => <input id={id} className="input" inputMode="numeric" value={draft.chapter} onChange={(e) => setDraft({ ...draft, chapter: e.target.value.replace(/\D/g, '') })} />}</Field>
            <Field label="جهت ترجمه">{(id) => <select id={id} className="select" value={draft.direction} onChange={(e) => setDraft({ ...draft, direction: e.target.value })}><option>EN → FA</option><option>JP → EN</option><option>JP → FA</option></select>}</Field>
            <Field label="مسئول">{(id) => <select id={id} className="select" value={draft.assignee} onChange={(e) => setDraft({ ...draft, assignee: e.target.value })}><option>سارا</option><option>حسین</option><option>محمد (ویراستار)</option></select>}</Field>
            <Field label="مهلت">{(id) => <input id={id} className="input" type="date" value={draft.due} onChange={(e) => setDraft({ ...draft, due: e.target.value })} />}</Field>
          </div>
          {err && <p className="err" role="alert">{err}</p>}
        </div>
      </Modal>
    </>
  );
}

function Card({ t, onMove }: { t: Task; onMove: (id: string, c: TaskColumn) => void }) {
  const late = new Date(t.due).getTime() < NOW.getTime() && t.column !== 'ready';
  return (
    <article className={`kcard ${late ? 'late' : ''}`} draggable onDragStart={(e) => e.dataTransfer.setData('text/plain', t.id)}>
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <b>{t.titleName}</b>
        <span className="chip" style={{ height: 22, fontSize: 11 }}><span className="ltr">{t.direction}</span></span>
      </div>
      <span className="sub">چپتر {faDigits(t.chapter)}</span>
      {t.progress && (
        <div>
          <div className="progress" role="progressbar" aria-valuenow={t.progress.done} aria-valuemin={0} aria-valuemax={t.progress.total} aria-label="صفحات ترجمه‌شده"><i style={{ width: `${(t.progress.done / t.progress.total) * 100}%` }} /></div>
          <span className="sub">{faDigits(t.progress.done)} از {faDigits(t.progress.total)} صفحه</span>
        </div>
      )}
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <span className="row" style={{ gap: 6 }}><Avatar name={t.assignee} size="sm" />{t.assignee}</span>
        <span className="due sub">{t.scheduledAt ? `زمان‌بندی: ${dueLabel(t.scheduledAt)} ${clock(t.scheduledAt)}` : `مهلت: ${dueLabel(t.due)}`}</span>
      </div>
      {t.note && <div className="note">{t.note}</div>}
      {t.approvedBy && <span className="sub">تأیید شد · {t.approvedBy}</span>}
      <label className="row" style={{ gap: 6 }}>
        <select className="select" style={{ height: 32, fontSize: 12 }} value={t.column} onChange={(e) => onMove(t.id, e.target.value as TaskColumn)} aria-label={`انتقال ${t.titleName} ${faDigits(t.chapter)}`}>
          {COLUMN_ORDER.map((c) => <option key={c} value={c}>انتقال: {COLUMN_LABEL[c]}</option>)}
        </select>
      </label>
      {t.column === 'ready' && <Badge kind="success">آماده · {jalaliDate(t.due)}</Badge>}
    </article>
  );
}
