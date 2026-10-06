import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { hasSubscription, type Ctx } from '../app.js';
import { errors } from '../errors.js';

type TitleRow = { id: string; name_fa: string; name_en: string; type: string; genres: string[]; summary: string; author: string; views: number; updated_at: string; chapters: number };

const dto = (t: TitleRow) => ({ id: t.id, nameFa: t.name_fa, nameEn: t.name_en, type: t.type, genres: t.genres, summary: t.summary, author: t.author, views: t.views, chapters: Number(t.chapters), updatedAt: t.updated_at });

const SELECT = `SELECT t.*, (SELECT count(*) FROM chapters c WHERE c.title_id = t.id)::int AS chapters FROM titles t WHERE t.status = 'published'`;

export function catalogRoutes(app: FastifyInstance, c: Ctx) {
  app.get('/titles', async (req) => {
    const q = c.parse(z.object({ q: z.string().max(100).optional(), type: z.enum(['manga', 'manhwa', 'comic']).optional(), limit: z.coerce.number().int().min(1).max(50).default(20), after: z.string().optional() }), req.query);
    const params: unknown[] = [];
    let where = '';
    if (q.q) { params.push(`%${q.q.replace(/[\\%_]/g, '\\$&')}%`); where += ` AND (t.name_fa ILIKE $${params.length} OR t.name_en ILIKE $${params.length} OR t.author ILIKE $${params.length})`; }
    if (q.type) { params.push(q.type); where += ` AND t.type = $${params.length}`; }
    if (q.after) { params.push(q.after); where += ` AND t.id > $${params.length}`; }
    params.push(q.limit + 1);
    const rows = await c.db.query<TitleRow>(`${SELECT}${where} ORDER BY t.id LIMIT $${params.length}`, params);
    const page = rows.slice(0, q.limit);
    return { items: page.map(dto), nextCursor: rows.length > q.limit ? page[page.length - 1]!.id : null };
  });

  app.get('/titles/ranked', async (req) => {
    const q = c.parse(z.object({ by: z.enum(['popular']).default('popular'), limit: z.coerce.number().int().min(1).max(50).default(10) }), req.query);
    const rows = await c.db.query<TitleRow>(`${SELECT} ORDER BY t.views DESC, t.id LIMIT $1`, [q.limit]);
    return { items: rows.map((t, i) => ({ rank: i + 1, ...dto(t) })) };
  });

  app.get('/genres', async () => {
    const rows = await c.db.query<{ genre: string; n: number }>(`SELECT g AS genre, count(*)::int AS n FROM titles t, unnest(t.genres) g WHERE t.status = 'published' GROUP BY g ORDER BY n DESC, g`);
    return { items: rows };
  });

  app.get('/titles/:id', async (req) => {
    const { id } = req.params as { id: string };
    const t = (await c.db.query<TitleRow>(`${SELECT} AND t.id = $1`, [id]))[0];
    if (!t) throw errors.notFound();
    return dto(t);
  });

  app.get('/titles/:id/chapters', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.optionalUser(req);
    if (!(await c.db.query(`SELECT 1 FROM titles WHERE id = $1 AND status = 'published'`, [id])).length) throw errors.notFound();
    const rows = await c.db.query<{ id: string; number: number; pages: number; published_at: string; read: boolean }>(
      `SELECT c.id, c.number, c.pages, c.published_at, (p.chapter_id IS NOT NULL) AS read FROM chapters c LEFT JOIN progress p ON p.chapter_id = c.id AND p.user_id = $2 WHERE c.title_id = $1 ORDER BY c.number DESC`,
      [id, u?.id ?? null],
    );
    const subscribed = hasSubscription(u, c.now());
    return { items: rows.map((r) => ({ id: r.id, number: r.number, pages: r.pages, publishedAt: r.published_at, read: r.read, locked: r.number > c.config.freeChapters && !subscribed })) };
  });

  app.get('/plans', async () => {
    const rows = await c.db.query<{ id: string; name: string; months: number; price_toman: number | null }>('SELECT * FROM plans ORDER BY months');
    // priceToman null = price not decided yet; clients show the "[قیمت]" label.
    return { items: rows.map((r) => ({ id: r.id, name: r.name, months: r.months, priceToman: r.price_toman })) };
  });
}
