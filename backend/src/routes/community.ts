import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../app.js';
import { newId } from '../crypto.js';
import { ApiError, errors } from '../errors.js';

type CommentRow = { id: string; body: string; spoiler: boolean; created_at: string; user_name: string; likes: number; liked: boolean; replies: number; parent_id: string | null };

const commentDto = (r: CommentRow) => ({ id: r.id, body: r.body, spoiler: r.spoiler, createdAt: r.created_at, author: r.user_name, likes: r.likes, liked: r.liked, replies: r.replies, parentId: r.parent_id });

export function communityRoutes(app: FastifyInstance, c: Ctx) {
  const SELECT = `SELECT cm.id, cm.body, cm.spoiler, cm.created_at, cm.parent_id, u.name AS user_name,
      (SELECT count(*) FROM comment_likes l WHERE l.comment_id = cm.id)::int AS likes,
      EXISTS (SELECT 1 FROM comment_likes l WHERE l.comment_id = cm.id AND l.user_id = $2) AS liked,
      (SELECT count(*) FROM comments r WHERE r.parent_id = cm.id AND r.status = 'visible')::int AS replies
    FROM comments cm JOIN users u ON u.id = cm.user_id`;

  const chapterExists = async (id: string) => {
    if (!(await c.db.query('SELECT 1 FROM chapters WHERE id = $1', [id])).length) throw errors.notFound();
  };

  app.get('/chapters/:id/comments', async (req) => {
    const { id } = req.params as { id: string };
    const q = c.parse(z.object({ sort: z.enum(['top', 'new']).default('top'), limit: z.coerce.number().int().min(1).max(50).default(20), offset: z.coerce.number().int().min(0).default(0) }), req.query);
    await chapterExists(id);
    const u = await c.optionalUser(req);
    const order = q.sort === 'top' ? 'likes DESC, cm.created_at DESC' : 'cm.created_at DESC';
    const rows = await c.db.query<CommentRow>(`${SELECT} WHERE cm.chapter_id = $1 AND cm.parent_id IS NULL AND cm.status = 'visible' ORDER BY ${order} LIMIT $3 OFFSET $4`, [id, u?.id ?? null, q.limit + 1, q.offset]);
    return { items: rows.slice(0, q.limit).map(commentDto), nextOffset: rows.length > q.limit ? q.offset + q.limit : null };
  });

  app.post('/chapters/:id/comments', async (req, reply) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ body: z.string().trim().min(1).max(1000), spoiler: z.boolean().default(false), parentId: z.string().optional() }), req.body);
    await chapterExists(id);
    // At most 5 comments a minute per user.
    const recent = await c.db.query<{ n: number }>(`SELECT count(*)::int AS n FROM comments WHERE user_id = $1 AND created_at > $2`, [u.id, new Date(c.now() - 60_000)]);
    if ((recent[0]?.n ?? 0) >= 5) throw new ApiError(429, 'slow_down', 'کمی آهسته‌تر؛ چند دقیقه بعد دوباره نظر بدهید.');
    if (b.parentId && !(await c.db.query('SELECT 1 FROM comments WHERE id = $1 AND chapter_id = $2 AND parent_id IS NULL', [b.parentId, id])).length) throw errors.notFound();
    const cid = newId();
    await c.db.query('INSERT INTO comments (id, chapter_id, user_id, parent_id, body, spoiler, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7)', [cid, id, u.id, b.parentId ?? null, b.body, b.spoiler, new Date(c.now())]);
    const row = (await c.db.query<CommentRow>(`${SELECT} WHERE cm.id = $1`, [cid, u.id]))[0]!;
    return reply.status(201).send(commentDto(row));
  });

  app.get('/comments/:id/replies', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.optionalUser(req);
    const rows = await c.db.query<CommentRow>(`${SELECT} WHERE cm.parent_id = $1 AND cm.status = 'visible' ORDER BY cm.created_at`, [id, u?.id ?? null]);
    return { items: rows.map(commentDto) };
  });

  app.post('/comments/:id/like', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    if (!(await c.db.query(`SELECT 1 FROM comments WHERE id = $1 AND status = 'visible'`, [id])).length) throw errors.notFound();
    const removed = await c.db.query('DELETE FROM comment_likes WHERE comment_id = $1 AND user_id = $2 RETURNING 1', [id, u.id]);
    if (!removed.length) await c.db.query('INSERT INTO comment_likes (comment_id, user_id) VALUES ($1,$2)', [id, u.id]);
    const n = (await c.db.query<{ n: number }>('SELECT count(*)::int AS n FROM comment_likes WHERE comment_id = $1', [id]))[0]!.n;
    return { liked: !removed.length, likes: n };
  });

  app.post('/comments/:id/report', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ reason: z.enum(['spam', 'abuse', 'spoiler', 'other']) }), req.body);
    if (!(await c.db.query('SELECT 1 FROM comments WHERE id = $1', [id])).length) throw errors.notFound();
    await c.db.query('INSERT INTO comment_reports (comment_id, user_id, reason) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING', [id, u.id, b.reason]);
    return { ok: true };
  });

  app.post('/chapters/:id/issues', async (req, reply) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ kind: z.enum(['missing_page', 'bad_translation', 'blurry', 'other']), page: z.number().int().min(1).optional(), description: z.string().max(1000).default('') }), req.body);
    await chapterExists(id);
    await c.db.query('INSERT INTO chapter_issues (id, chapter_id, user_id, kind, page, description) VALUES ($1,$2,$3,$4,$5,$6)', [newId(), id, u.id, b.kind, b.page ?? null, b.description]);
    return reply.status(201).send({ ok: true });
  });

  // ---- title requests ----
  app.get('/requests', async (req) => {
    const u = await c.optionalUser(req);
    const rows = await c.db.query<{ id: string; name: string; type: string; language: string; votes: number; voted: boolean }>(
      `SELECT r.id, r.name, r.type, r.language, (SELECT count(*) FROM request_votes v WHERE v.request_id = r.id)::int AS votes,
        EXISTS (SELECT 1 FROM request_votes v WHERE v.request_id = r.id AND v.user_id = $1) AS voted
       FROM title_requests r ORDER BY votes DESC, r.created_at DESC LIMIT 50`, [u?.id ?? null]);
    return { items: rows };
  });

  app.post('/requests', async (req, reply) => {
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ name: z.string().trim().min(2).max(120), type: z.enum(['manga', 'manhwa', 'comic']), language: z.enum(['fa', 'en']).default('fa') }), req.body);
    const day = await c.db.query<{ n: number }>('SELECT count(*)::int AS n FROM title_requests WHERE user_id = $1 AND created_at > $2', [u.id, new Date(c.now() - 86_400_000)]);
    if ((day[0]?.n ?? 0) >= 5) throw new ApiError(429, 'daily_limit', 'امروز به سقف درخواست‌ها رسیدید. فردا دوباره امتحان کنید.');
    const id = newId();
    await c.db.query('INSERT INTO title_requests (id, user_id, name, type, language, created_at) VALUES ($1,$2,$3,$4,$5,$6)', [id, u.id, b.name, b.type, b.language, new Date(c.now())]);
    await c.db.query('INSERT INTO request_votes (request_id, user_id) VALUES ($1,$2)', [id, u.id]);
    return reply.status(201).send({ id });
  });

  app.post('/requests/:id/vote', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    if (!(await c.db.query('SELECT 1 FROM title_requests WHERE id = $1', [id])).length) throw errors.notFound();
    const removed = await c.db.query('DELETE FROM request_votes WHERE request_id = $1 AND user_id = $2 RETURNING 1', [id, u.id]);
    if (!removed.length) await c.db.query('INSERT INTO request_votes (request_id, user_id) VALUES ($1,$2)', [id, u.id]);
    return { voted: !removed.length, votes: (await c.db.query<{ n: number }>('SELECT count(*)::int AS n FROM request_votes WHERE request_id = $1', [id]))[0]!.n };
  });
}
