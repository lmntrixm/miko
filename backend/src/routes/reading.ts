import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { hasSubscription, type Ctx } from '../app.js';
import { signMediaUrl } from '../crypto.js';
import { errors } from '../errors.js';

type ChapterRow = { id: string; title_id: string; number: number; pages: number };

export function readingRoutes(app: FastifyInstance, c: Ctx) {
  const chapter = async (id: string) => {
    const r = (await c.db.query<ChapterRow>(`SELECT ch.id, ch.title_id, ch.number, ch.pages FROM chapters ch JOIN titles t ON t.id = ch.title_id WHERE ch.id = $1 AND t.status = 'published'`, [id]))[0];
    if (!r) throw errors.notFound();
    return r;
  };

  app.get('/chapters/:id/pages', async (req) => {
    const { id } = req.params as { id: string };
    const { lang } = c.parse(z.object({ lang: z.enum(['fa', 'en']).default('fa') }), req.query);
    const u = await c.requireUser(req);
    const ch = await chapter(id);
    if (ch.number > c.config.freeChapters && !hasSubscription(u, c.now())) throw errors.paymentRequired();
    const pages = Array.from({ length: ch.pages }, (_, i) => signMediaUrl(c.config.jwtSecret, `/media/${ch.id}/${lang}/${i + 1}.webp`, u.id, c.now()));
    return { pages, expiresInSec: 600 };
  });

  app.put('/me/progress/:chapterId', async (req) => {
    const { chapterId } = req.params as { chapterId: string };
    const u = await c.requireUser(req);
    const { page } = c.parse(z.object({ page: z.number().int().min(1) }), req.body);
    const ch = await chapter(chapterId);
    if (page > ch.pages) throw errors.invalid('شمارهٔ صفحه از تعداد صفحات بیشتر است.');
    await c.db.query(
      `INSERT INTO progress (user_id, chapter_id, page) VALUES ($1,$2,$3) ON CONFLICT (user_id, chapter_id) DO UPDATE SET page = EXCLUDED.page, updated_at = now()`,
      [u.id, chapterId, page],
    );
    return { ok: true };
  });

  app.post('/chapters/:id/download', async (req) => {
    const { id } = req.params as { id: string };
    const u = await c.requireUser(req);
    const body = c.parse(z.object({ deviceId: z.string().min(8).max(100), deviceName: z.string().max(80).default('') }), req.body);
    await chapter(id);
    // Offline files last until the subscription ends, so downloading needs one.
    if (!hasSubscription(u, c.now())) throw errors.paymentRequired();
    const known = await c.db.query<{ device_id: string }>('SELECT device_id FROM devices WHERE user_id = $1', [u.id]);
    if (!known.some((d) => d.device_id === body.deviceId)) {
      if (known.length >= c.config.maxDevices) throw errors.deviceLimit();
      await c.db.query('INSERT INTO devices (user_id, device_id, name) VALUES ($1,$2,$3)', [u.id, body.deviceId, body.deviceName]);
    }
    const ch = await chapter(id);
    return { allowed: true, expiresAt: u.subscription_ends_at, pages: Array.from({ length: ch.pages }, (_, i) => signMediaUrl(c.config.jwtSecret, `/media/${ch.id}/fa/${i + 1}.webp`, u.id, c.now())) };
  });

  app.get('/me/devices', async (req) => {
    const u = await c.requireUser(req);
    const rows = await c.db.query<{ device_id: string; name: string; created_at: string }>('SELECT device_id, name, created_at FROM devices WHERE user_id = $1 ORDER BY created_at', [u.id]);
    return { items: rows.map((r) => ({ deviceId: r.device_id, name: r.name, addedAt: r.created_at })) };
  });

  app.delete('/me/devices/:deviceId', async (req, reply) => {
    const u = await c.requireUser(req);
    const { deviceId } = req.params as { deviceId: string };
    await c.db.query('DELETE FROM devices WHERE user_id = $1 AND device_id = $2', [u.id, deviceId]);
    return reply.status(204).send();
  });
}
