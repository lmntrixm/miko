'use client';

import { useState } from 'react';
import { TitleEditor } from '@/components/TitleEditor';
import { Field, PageHead } from '@/components/ui';
import { useStore } from '@/lib/store';

/** Entry from the sidebar: pick a title first, then upload. */
export default function UploadPage() {
  const titles = useStore((s) => s.titles);
  const [id, setId] = useState('');
  if (id) return <TitleEditor key={id} titleId={id} />;
  return (
    <>
      <PageHead title="آپلود چپتر" sub="اثری را انتخاب کنید تا چپتر جدید به آن اضافه شود" />
      <section className="card" style={{ maxWidth: 480 }}>
        <Field label="اثر">
          {(fid) => (
            <select id={fid} className="select" value="" onChange={(e) => setId(e.target.value)}>
              <option value="" disabled>انتخاب اثر…</option>
              {titles.map((t) => <option key={t.id} value={t.id}>{t.nameFa} — {t.nameEn}</option>)}
            </select>
          )}
        </Field>
      </section>
    </>
  );
}
