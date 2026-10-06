import type { Db } from './db.js';

/** Invented sample content (no real works). */
export async function seed(db: Db): Promise<void> {
  const titles: [string, string, string, string, string[], number][] = [
    ['sample-moon', 'نمونه: مهمان ماه', 'Sample Moon Guest', 'manga', ['فانتزی', 'ماجراجویی'], 1200],
    ['sample-tower', 'نمونه: برج هزارطبقه', 'Sample Thousand Tower', 'manhwa', ['اکشن', 'فانتزی'], 3400],
    ['sample-hero', 'نمونه: قهرمان شهر', 'Sample City Hero', 'comic', ['ابرقهرمانی'], 800],
  ];
  await db.query("INSERT INTO authors (id, name, bio) VALUES ('sample-author', 'نویسنده نمونه', 'معرفی نمونه') ON CONFLICT DO NOTHING");
  for (const [id, fa, en, type, genres, views] of titles) {
    await db.query(`INSERT INTO titles (id, name_fa, name_en, type, status, genres, views, summary, author, author_id) VALUES ($1,$2,$3,$4,'published',$5,$6,'خلاصهٔ نمونه','نویسنده نمونه','sample-author') ON CONFLICT DO NOTHING`, [id, fa, en, type, genres, views]);
    for (let n = 1; n <= 6; n++) await db.query('INSERT INTO chapters (id, title_id, number, pages) VALUES ($1,$2,$3,$4) ON CONFLICT DO NOTHING', [`${id}-${n}`, id, n, 8]);
  }
  // price_toman stays null until real prices are decided ([قیمت]).
  for (const [id, name, months] of [['m1', 'ماهانه', 1], ['m3', 'سه‌ماهه', 3], ['m12', 'سالانه', 12]] as const)
    await db.query('INSERT INTO plans (id, name, months) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING', [id, name, months]);
}
