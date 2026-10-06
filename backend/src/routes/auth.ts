import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { userDto, type Ctx, type UserRow } from '../app.js';
import { hashPassword, newCode, newId, safeEqual, hmac, signJwt, verifyPassword } from '../crypto.js';
import { ApiError, errors } from '../errors.js';

const TOKEN_TTL = 30 * 24 * 3600;
const CODE_TTL_MS = 10 * 60_000;
const MAX_CODE_ATTEMPTS = 5;

const email = z.string().trim().toLowerCase().email();
const password = z.string().min(8).max(200);

export function authRoutes(app: FastifyInstance, c: Ctx) {
  const codeHash = (e: string, code: string) => hmac(c.config.jwtSecret, `${e}|${code}`);

  const issueCode = async (e: string, purpose: 'signup' | 'reset', newPasswordHash?: string) => {
    await c.db.query('DELETE FROM otp_codes WHERE email = $1 AND purpose = $2', [e, purpose]);
    const code = newCode();
    await c.db.query('INSERT INTO otp_codes (id, email, purpose, code_hash, expires_at, new_password_hash) VALUES ($1,$2,$3,$4,$5,$6)', [newId(), e, purpose, codeHash(e, code), new Date(c.now() + CODE_TTL_MS), newPasswordHash ?? null]);
    await c.mailer.sendCode(e, code, purpose);
  };

  /** Checks and consumes a code. Wrong guesses count; the 5th kills the code. */
  const consumeCode = async (e: string, purpose: 'signup' | 'reset', code: string) => {
    const row = (await c.db.query<{ id: string; code_hash: string; attempts: number; expires_at: string; new_password_hash: string | null }>('SELECT * FROM otp_codes WHERE email = $1 AND purpose = $2', [e, purpose]))[0];
    if (!row || new Date(row.expires_at).getTime() < c.now()) throw new ApiError(400, 'code_expired', 'کد منقضی شده است. کد جدید بگیرید.');
    if (!safeEqual(row.code_hash, codeHash(e, code))) {
      if (row.attempts + 1 >= MAX_CODE_ATTEMPTS) {
        await c.db.query('DELETE FROM otp_codes WHERE id = $1', [row.id]);
        throw errors.tooMany();
      }
      await c.db.query('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1', [row.id]);
      throw new ApiError(400, 'code_wrong', 'کد درست نیست. دوباره امتحان کنید.');
    }
    await c.db.query('DELETE FROM otp_codes WHERE id = $1', [row.id]);
    return row;
  };

  app.post('/auth/signup', async (req) => {
    const b = c.parse(z.object({ name: z.string().trim().min(2).max(60), email, password }), req.body);
    const existing = (await c.db.query<{ verified: boolean }>('SELECT verified FROM users WHERE email = $1', [b.email]))[0];
    if (existing?.verified) throw new ApiError(409, 'email_taken', 'با این ایمیل قبلاً ثبت‌نام شده است. وارد شوید.');
    if (existing) await c.db.query('UPDATE users SET name = $2, password_hash = $3 WHERE email = $1', [b.email, b.name, hashPassword(b.password)]);
    else await c.db.query('INSERT INTO users (id, name, email, password_hash) VALUES ($1,$2,$3,$4)', [newId(), b.name, b.email, hashPassword(b.password)]);
    await issueCode(b.email, 'signup');
    return { ok: true };
  });

  app.post('/auth/verify', async (req) => {
    const b = c.parse(z.object({ email, code: z.string().regex(/^\d{6}$/) }), req.body);
    await consumeCode(b.email, 'signup', b.code);
    await c.db.query('UPDATE users SET verified = true WHERE email = $1', [b.email]);
    const u = (await c.db.query<UserRow>('SELECT id, name, email, verified, genres, language, subscription_ends_at FROM users WHERE email = $1', [b.email]))[0]!;
    return { token: signJwt(c.config.jwtSecret, u.id, TOKEN_TTL, c.now()), user: userDto(u, c.now()) };
  });

  // Per-email lockout for password guessing (in-process; use a shared store with several instances).
  const fails = new Map<string, { n: number; until: number }>();
  app.post('/auth/login', async (req) => {
    const b = c.parse(z.object({ email, password: z.string().min(1).max(200) }), req.body);
    const f = fails.get(b.email);
    if (f && f.n >= 5 && f.until > c.now()) throw errors.tooMany();
    const u = (await c.db.query<UserRow & { password_hash: string }>('SELECT * FROM users WHERE email = $1 AND verified', [b.email]))[0];
    // Hash check runs even for unknown emails so timing doesn't reveal them.
    const ok = verifyPassword(b.password, u?.password_hash ?? 'scrypt$00$00');
    if (!u || !ok) {
      fails.set(b.email, { n: f && f.until > c.now() ? f.n + 1 : 1, until: c.now() + 15 * 60_000 });
      throw new ApiError(401, 'bad_credentials', 'ایمیل یا رمز عبور درست نیست.');
    }
    fails.delete(b.email);
    return { token: signJwt(c.config.jwtSecret, u.id, TOKEN_TTL, c.now()), user: userDto(u, c.now()) };
  });

  // Step 1: { email } sends a code. Step 2: { email, code, password } sets the new password.
  // Always answers ok on step 1 so the endpoint can't be used to find registered emails.
  app.post('/auth/password/reset', async (req) => {
    const b = c.parse(z.object({ email, code: z.string().regex(/^\d{6}$/).optional(), password: password.optional() }), req.body);
    if (!b.code) {
      const exists = (await c.db.query('SELECT 1 FROM users WHERE email = $1 AND verified', [b.email])).length > 0;
      if (exists) await issueCode(b.email, 'reset');
      return { ok: true };
    }
    if (!b.password) throw errors.invalid('رمز جدید را وارد کنید.');
    await consumeCode(b.email, 'reset', b.code);
    await c.db.query('UPDATE users SET password_hash = $2 WHERE email = $1', [b.email, hashPassword(b.password)]);
    return { ok: true };
  });

  app.get('/me', async (req) => userDto(await c.requireUser(req), c.now()));

  app.put('/me/preferences', async (req) => {
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ genres: z.array(z.string().max(40)).max(30), language: z.enum(['fa', 'en', 'both']) }), req.body);
    await c.db.query('UPDATE users SET genres = $2, language = $3 WHERE id = $1', [u.id, b.genres, b.language]);
    return { ok: true };
  });

  app.patch('/me', async (req) => {
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ name: z.string().trim().min(2).max(60).optional(), currentPassword: z.string().optional(), password: password.optional() }), req.body);
    if (b.password) {
      const row = (await c.db.query<{ password_hash: string }>('SELECT password_hash FROM users WHERE id = $1', [u.id]))[0]!;
      if (!b.currentPassword || !verifyPassword(b.currentPassword, row.password_hash)) throw new ApiError(400, 'bad_current_password', 'رمز فعلی درست نیست.');
      await c.db.query('UPDATE users SET password_hash = $2 WHERE id = $1', [u.id, hashPassword(b.password)]);
    }
    if (b.name) await c.db.query('UPDATE users SET name = $2 WHERE id = $1', [u.id, b.name]);
    return userDto((await c.requireUser(req)), c.now());
  });

  app.delete('/me', async (req, reply) => {
    const u = await c.requireUser(req);
    const b = c.parse(z.object({ password: z.string() }), req.body);
    const row = (await c.db.query<{ password_hash: string }>('SELECT password_hash FROM users WHERE id = $1', [u.id]))[0]!;
    if (!verifyPassword(b.password, row.password_hash)) throw new ApiError(400, 'bad_current_password', 'رمز عبور درست نیست.');
    await c.db.query('DELETE FROM users WHERE id = $1', [u.id]);
    return reply.status(204).send();
  });
}
