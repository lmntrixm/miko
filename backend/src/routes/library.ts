import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../app.js';
import { errors } from '../errors.js';

export function libraryRoutes(app: FastifyInstance, c: Ctx) {
  const titleCols = `t.id, t.name_fa, t.name_en, t.type`;

  app.post('/me/bookmarks', async (req) => {
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ titleId: z.string(), bookmarked: z.boolean() }), req.body);
    if (!(await c.db.query(`SELECT 1 FROM titles WHERE id = $1 AND status = 'published'`, [b.titleId])).length) throw errors.notFound();
    if (b.bookmarked) await c.db.query('INSERT INTO bookmarks (user_id, title_id) VALUES ($1,$2) ON CONFLICT DO NOTHING', [u.id, b.titleId]);
    else await c.db.query('DELETE FROM bookmarks WHERE user_id = $1 AND title_id = $2', [u.id, b.titleId]);
    return { bookmarked: b.bookmarked };
  });

  // reading: one row per title (its latest chapter); bookmarks; history: every chapter opened.
  app.get('/me/library', async (req) => {
    const u = await c.requireUser(req);
    const { tab } = c.parse(z.object({ tab: z.enum(['reading', 'bookmarks', 'history']).default('reading') }), req.query);
    if (tab === 'bookmarks') {
      const rows = await c.db.query<{ id: string; name_fa: string; name_en: string; type: string }>(`SELECT ${titleCols} FROM bookmarks b JOIN titles t ON t.id = b.title_id WHERE b.user_id = $1 AND t.status = 'published' ORDER BY b.created_at DESC`, [u.id]);
      return { items: rows.map((t) => ({ id: t.id, nameFa: t.name_fa, nameEn: t.name_en, type: t.type })) };
    }
    const latestOnly = tab === 'reading' ? 'DISTINCT ON (t.id)' : '';
    const order = tab === 'reading' ? 'ORDER BY t.id, p.updated_at DESC' : 'ORDER BY p.updated_at DESC';
    const rows = await c.db.query<{ id: string; name_fa: string; name_en: string; type: string; chapter_id: string; number: number; page: number; pages: number; updated_at: string }>(
      `SELECT ${latestOnly} ${titleCols}, ch.id AS chapter_id, ch.number, ch.pages, p.page, p.updated_at
       FROM progress p JOIN chapters ch ON ch.id = p.chapter_id JOIN titles t ON t.id = ch.title_id
       WHERE p.user_id = $1 AND t.status = 'published' ${order}`, [u.id]);
    const items = rows.map((r) => ({ id: r.id, nameFa: r.name_fa, nameEn: r.name_en, type: r.type, chapterId: r.chapter_id, chapterNumber: r.number, page: r.page, pages: r.pages, updatedAt: r.updated_at }));
    // DISTINCT ON forces title ordering; show most recent first.
    items.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
    return { items };
  });

  app.get('/home', async (req) => {
    const q = c.parse(z.object({ type: z.enum(['manga', 'manhwa', 'comic']).optional() }), req.query);
    const u = await c.optionalUser(req);
    const where = q.type ? `AND t.type = '${q.type}'` : '';
    const cols = `t.id, t.name_fa, t.name_en, t.type, t.views`;
    const toDto = (t: { id: string; name_fa: string; name_en: string; type: string; views: number }, extra = {}) => ({ id: t.id, nameFa: t.name_fa, nameEn: t.name_en, type: t.type, views: t.views, ...extra });
    const ranked = await c.db.query<{ id: string; name_fa: string; name_en: string; type: string; views: number }>(`SELECT ${cols} FROM titles t WHERE t.status = 'published' ${where} ORDER BY t.views DESC, t.id LIMIT 10`);
    const latest = await c.db.query<{ id: string; name_fa: string; name_en: string; type: string; views: number; number: number; published_at: string }>(
      `SELECT ${cols}, ch.number, ch.published_at FROM (SELECT DISTINCT ON (title_id) * FROM chapters ORDER BY title_id, number DESC) ch JOIN titles t ON t.id = ch.title_id WHERE t.status = 'published' ${where} ORDER BY ch.published_at DESC, t.id LIMIT 10`);
    const resume = u
      ? await c.db.query<{ id: string; name_fa: string; name_en: string; type: string; views: number; chapter_id: string; number: number; page: number }>(
          `SELECT DISTINCT ON (t.id) ${cols}, ch.id AS chapter_id, ch.number, p.page, p.updated_at FROM progress p JOIN chapters ch ON ch.id = p.chapter_id JOIN titles t ON t.id = ch.title_id WHERE p.user_id = $1 AND t.status = 'published' ${where} ORDER BY t.id, p.updated_at DESC`, [u.id])
      : [];
    return {
      banner: ranked[0] ? toDto(ranked[0]) : null,
      continueReading: resume.slice(0, 10).map((r) => toDto(r, { chapterId: r.chapter_id, chapterNumber: r.number, page: r.page })),
      ranked: ranked.map((t, i) => toDto(t, { rank: i + 1 })),
      latest: latest.map((t) => toDto(t, { chapterNumber: t.number, publishedAt: t.published_at })),
    };
  });

  app.get('/authors/:id', async (req) => {
    const { id } = req.params as { id: string };
    const a = (await c.db.query<{ id: string; name: string; bio: string }>('SELECT * FROM authors WHERE id = $1', [id]))[0];
    if (!a) throw errors.notFound();
    const works = await c.db.query<{ id: string; name_fa: string; name_en: string; type: string }>(`SELECT ${titleCols} FROM titles t WHERE t.author_id = $1 AND t.status = 'published' ORDER BY t.views DESC`, [id]);
    return { id: a.id, name: a.name, bio: a.bio, works: works.map((t) => ({ id: t.id, nameFa: t.name_fa, nameEn: t.name_en, type: t.type })) };
  });
}
