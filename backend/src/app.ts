import cors from '@fastify/cors';
import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { ZodError, type ZodType } from 'zod';
import type { Config } from './config.js';
import { readJwt } from './crypto.js';
import type { Db } from './db.js';
import { ApiError, errors } from './errors.js';
import { authRoutes } from './routes/auth.js';
import { catalogRoutes } from './routes/catalog.js';
import { readingRoutes } from './routes/reading.js';

/** Sends one-time codes. Dev: console. Real: email/SMS provider ([ایمیل] sender not decided yet). */
export interface Mailer {
  sendCode(email: string, code: string, purpose: 'signup' | 'reset'): Promise<void>;
}

export type Deps = { db: Db; config: Config; mailer: Mailer; now?: () => number };

export type UserRow = {
  id: string; name: string; email: string; verified: boolean; genres: string[]; language: string;
  subscription_ends_at: string | null;
};

export type Ctx = Deps & { now: () => number; parse: <T>(schema: ZodType<T>, data: unknown) => T; requireUser: (req: FastifyRequest) => Promise<UserRow>; optionalUser: (req: FastifyRequest) => Promise<UserRow | null> };

export function hasSubscription(u: UserRow | null, nowMs: number): boolean {
  return !!u?.subscription_ends_at && new Date(u.subscription_ends_at).getTime() > nowMs;
}

export function userDto(u: UserRow, nowMs: number) {
  return { id: u.id, name: u.name, email: u.email, genres: u.genres, language: u.language, subscribed: hasSubscription(u, nowMs), subscriptionEndsAt: u.subscription_ends_at };
}

export async function buildApp(deps: Deps): Promise<FastifyInstance> {
  const now = deps.now ?? Date.now;
  const app = Fastify({ logger: false });
  await app.register(cors, { origin: false });

  const userById = async (id: string) =>
    (await deps.db.query<UserRow>('SELECT id, name, email, verified, genres, language, subscription_ends_at FROM users WHERE id = $1 AND verified', [id]))[0] ?? null;

  const optionalUser = async (req: FastifyRequest) => {
    const m = req.headers.authorization?.match(/^Bearer (.+)$/);
    const sub = m?.[1] ? readJwt(deps.config.jwtSecret, m[1], now()) : null;
    return sub ? userById(sub) : null;
  };
  const requireUser = async (req: FastifyRequest) => {
    const u = await optionalUser(req);
    if (!u) throw errors.unauthorized();
    return u;
  };
  const parse = <T>(schema: ZodType<T>, data: unknown): T => {
    const r = schema.safeParse(data);
    if (!r.success) throw errors.invalid();
    return r.data;
  };

  app.setErrorHandler((err, _req, reply) => {
    if (err instanceof ApiError) return reply.status(err.status).send({ error: { code: err.code, message: err.message } });
    if (err instanceof ZodError) return reply.status(400).send({ error: { code: 'invalid', message: errors.invalid().message } });
    const status = (err as { statusCode?: number }).statusCode;
    if (status && status < 500) return reply.status(status).send({ error: { code: 'invalid', message: errors.invalid().message } });
    app.log.error(err);
    return reply.status(500).send({ error: { code: 'server_error', message: 'مشکلی از سمت ما پیش آمد. کمی بعد دوباره امتحان کنید.' } });
  });
  app.setNotFoundHandler((_req, reply) => reply.status(404).send({ error: { code: 'not_found', message: errors.notFound().message } }));

  const ctx: Ctx = { ...deps, now, parse, requireUser, optionalUser };
  app.get('/health', async () => ({ ok: true }));
  await app.register(async (v1) => {
    authRoutes(v1, ctx);
    catalogRoutes(v1, ctx);
    readingRoutes(v1, ctx);
  }, { prefix: '/v1' });
  return app;
}
