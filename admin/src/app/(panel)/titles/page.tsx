'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { useToast } from '@/components/Toast';
import { Badge, Button, Check, Confirm, Empty, Field, IconButton, Modal, PageHead, Pagination, SearchBox, Segmented } from '@/components/ui';
import { downloadCsv, faDigits, faNumber, relative } from '@/lib/format';
import { langsText, STATUS_KIND, STATUS_LABEL } from '@/lib/labels';
import { addTitle, deleteTitle, useStore } from '@/lib/store';
import { TYPE_LABEL, type Title, type WorkType } from '@/lib/types';

const PAGE = 8;
type TypeFilter = 'all' | WorkType;

export default function TitlesPage() {
  const titles = useStore((s) => s.titles);
  const toast = useToast();
  const router = useRouter();
  const [type, setType] = useState<TypeFilter>('all');
  const [status, setStatus] = useState<'all' | Title['status']>('all');
  const [lang, setLang] = useState<'all' | 'fa' | 'en'>('all');
  const [q, setQ] = useState('');
  const [page, setPage] = useState(1);
  const [sel, setSel] = useState<Set<string>>(new Set());
  const [del, setDel] = useState<Title | null>(null);
  const [adding, setAdding] = useState(false);
  const [draft, setDraft] = useState({ nameFa: '', nameEn: '', type: 'manga' as WorkType });
  const [err, setErr] = useState('');

  const rows = useMemo(() => {
    const k = q.trim().toLowerCase();
    return titles.filter((t) => (type === 'all' || t.type === type) && (status === 'all' || t.status === status) && (lang === 'all' || t.langs.includes(lang)) && (!k || t.nameFa.includes(q.trim()) || t.nameEn.toLowerCase().includes(k)));
  }, [titles, type, status, lang, q]);
  const pages = Math.max(1, Math.ceil(rows.length / PAGE));
  const cur = Math.min(page, pages);
  const visible = rows.slice((cur - 1) * PAGE, cur * PAGE);
  const totalChapters = titles.reduce((a, t) => a + t.chapters, 0);
  const allOnPage = visible.length > 0 && visible.every((t) => sel.has(t.id));

  const toggle = (id: string) => setSel((s) => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  const reset = <T,>(set: (v: T) => void) => (v: T) => { set(v); setPage(1); };

  const exportCsv = () => {
    const list = sel.size ? titles.filter((t) => sel.has(t.id)) : rows;
    downloadCsv('titles.csv', [['نام فارسی', 'نام انگلیسی', 'نوع', 'وضعیت', 'چپتر', 'بازدید'], ...list.map((t) => [t.nameFa, t.nameEn, TYPE_LABEL[t.type], STATUS_LABEL[t.status], t.chapters, t.views])]);
    toast(`${faDigits(list.length)} اثر در فایل CSV ذخیره شد`);
  };

  const create = () => {
    if (draft.nameFa.trim().length < 2 || draft.nameEn.trim().length < 2) return setErr('نام فارسی و انگلیسی را وارد کنید');
    const id = addTitle({ nameFa: draft.nameFa.trim(), nameEn: draft.nameEn.trim(), type: draft.type });
    toast('اثر به‌صورت پیش‌نویس ساخته شد');
    setAdding(false);
    setDraft({ nameFa: '', nameEn: '', type: 'manga' });
    router.push(`/titles/${id}`);
  };

  return (
    <>
      <PageHead title="آثار" sub={`${faNumber(titles.length)} اثر · ${faNumber(totalChapters)} چپتر`}>
        <Button icon="download" onClick={exportCsv}>خروجی Excel</Button>
        <Button variant="primary" icon="plus" onClick={() => { setErr(''); setAdding(true); }}>افزودن اثر</Button>
      </PageHead>

      <div className="row" style={{ marginBottom: 'var(--space-4)' }}>
        <Segmented label="نوع" value={type} onChange={reset(setType)} items={[{ id: 'all', label: 'همه' }, { id: 'manga', label: 'مانگا' }, { id: 'manhwa', label: 'مانهوا' }, { id: 'comic', label: 'کامیک' }]} />
        <label className="row" style={{ gap: 6 }}>
          <span className="sub">وضعیت</span>
          <select className="select" style={{ width: 140 }} value={status} onChange={(e) => reset(setStatus)(e.target.value as typeof status)}>
            <option value="all">همه</option><option value="ongoing">در حال انتشار</option><option value="finished">تمام‌شده</option><option value="draft">پیش‌نویس</option>
          </select>
        </label>
        <label className="row" style={{ gap: 6 }}>
          <span className="sub">زبان</span>
          <select className="select" style={{ width: 100 }} value={lang} onChange={(e) => reset(setLang)(e.target.value as typeof lang)}>
            <option value="all">همه</option><option value="fa">FA</option><option value="en">EN</option>
          </select>
        </label>
        <span className="spacer" />
        <SearchBox value={q} onChange={reset(setQ)} placeholder="جستجوی نام اثر…" />
      </div>

      <section className="card flush" aria-label="فهرست آثار">
        <div className="table-wrap">
          <table className="t">
            <thead>
              <tr>
                <th style={{ width: 44 }}><Check label="انتخاب همه" checked={allOnPage} onChange={(v) => setSel((s) => { const n = new Set(s); visible.forEach((t) => (v ? n.add(t.id) : n.delete(t.id))); return n; })} /></th>
                <th>اثر</th><th>نوع</th><th>ژانر</th><th>چپترها</th><th>زبان‌ها</th><th>وضعیت</th><th>بازدید</th><th>امتیاز</th><th>بروزرسانی</th><th>عملیات</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((t) => (
                <tr key={t.id} aria-selected={sel.has(t.id)}>
                  <td><Check label={`انتخاب ${t.nameFa}`} checked={sel.has(t.id)} onChange={() => toggle(t.id)} /></td>
                  <td>
                    <div className="cell-main">
                      <span className="cover" aria-hidden="true" />
                      <div>
                        <b><Link href={`/titles/${t.id}`} style={{ color: 'inherit' }}>{t.nameFa}</Link></b>
                        <span className="sub ltr">{t.nameEn}</span>
                      </div>
                    </div>
                  </td>
                  <td>{TYPE_LABEL[t.type]}</td>
                  <td>{t.genres.join('، ') || '—'}</td>
                  <td>{faNumber(t.chapters)}</td>
                  <td><span className="ltr">{langsText(t.langs)}</span></td>
                  <td><Badge kind={STATUS_KIND[t.status]}>{STATUS_LABEL[t.status]}</Badge></td>
                  <td>{t.views ? faNumber(t.views) : '—'}</td>
                  <td>{t.rating ? <>{faDigits(t.rating.toFixed(1).replace('.', '٫'))} <span style={{ color: 'var(--red-400)' }} aria-hidden="true">★</span></> : '—'}</td>
                  <td>{relative(t.updatedAt)}</td>
                  <td>
                    <div className="row" style={{ gap: 6, flexWrap: 'nowrap' }}>
                      <Link href={`/titles/${t.id}`} className="iconbtn" aria-label={`ویرایش ${t.nameFa}`}><Icon name="edit" size={16} /></Link>
                      <IconButton icon="trash" danger label={`حذف ${t.nameFa}`} onClick={() => setDel(t)} />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {visible.length === 0 && <Empty>اثری با این فیلترها پیدا نشد.</Empty>}
        </div>
        <div className="row" style={{ justifyContent: 'space-between', padding: '0 var(--space-4)', borderTop: '1px solid var(--border-1)' }}>
          <Pagination page={cur} pages={pages} onChange={setPage} />
          <span className="sub" aria-live="polite">نمایش {faDigits(rows.length ? (cur - 1) * PAGE + 1 : 0)} تا {faDigits(Math.min(cur * PAGE, rows.length))} از {faNumber(rows.length)}</span>
        </div>
      </section>

      <Confirm open={!!del} danger title="حذف اثر" confirm="حذف اثر" onClose={() => setDel(null)} body={<>اثر «{del?.nameFa}» با همهٔ چپترهایش حذف می‌شود و برگشت ندارد.</>} onConfirm={() => { if (del) { deleteTitle(del.id); toast('اثر حذف شد'); } }} />
      <Modal open={adding} onClose={() => setAdding(false)} title="افزودن اثر" footer={<><Button variant="primary" onClick={create}>ساخت پیش‌نویس</Button><Button onClick={() => setAdding(false)}>انصراف</Button></>}>
        <div className="stack">
          <Field label="نام فارسی">{(id) => <input id={id} className="input" value={draft.nameFa} onChange={(e) => setDraft({ ...draft, nameFa: e.target.value })} />}</Field>
          <Field label="نام انگلیسی">{(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} value={draft.nameEn} onChange={(e) => setDraft({ ...draft, nameEn: e.target.value })} />}</Field>
          <Field label="نوع">{(id) => <select id={id} className="select" value={draft.type} onChange={(e) => setDraft({ ...draft, type: e.target.value as WorkType })}><option value="manga">مانگا</option><option value="manhwa">مانهوا</option><option value="comic">کامیک</option></select>}</Field>
          {err && <p className="err" role="alert">{err}</p>}
        </div>
      </Modal>
    </>
  );
}
