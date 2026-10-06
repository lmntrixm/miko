import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PGlite } from '@electric-sql/pglite';
import pg from 'pg';

export interface Db {
  query<T = Record<string, unknown>>(sql: string, params?: unknown[]): Promise<T[]>;
  close(): Promise<void>;
}

export function pgDb(url: string): Db {
  const pool = new pg.Pool({ connectionString: url });
  return {
    query: async <T>(sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows as T[],
    close: () => pool.end(),
  };
}

/** In-process Postgres (WASM): used by tests and for local dev without a server. */
export async function pgliteDb(dataDir?: string): Promise<Db> {
  const db = new PGlite(dataDir);
  await db.waitReady;
  return {
    query: async <T>(sql: string, params: unknown[] = []) => (await db.query(sql, params)).rows as T[],
    close: () => db.close(),
  };
}

export async function migrate(db: Db, dir = join(import.meta.dirname, '..', 'migrations')): Promise<void> {
  await db.query('CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())');
  const done = new Set((await db.query<{ name: string }>('SELECT name FROM schema_migrations')).map((r) => r.name));
  for (const f of readdirSync(dir).filter((x) => x.endsWith('.sql')).sort()) {
    if (done.has(f)) continue;
    const sql = readFileSync(join(dir, f), 'utf8');
    for (const stmt of sql.split(/;\s*\n/).map((s) => s.trim()).filter(Boolean)) await db.query(stmt);
    await db.query('INSERT INTO schema_migrations (name) VALUES ($1)', [f]);
  }
}
