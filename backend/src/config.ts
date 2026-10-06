export type Config = { port: number; jwtSecret: string; databaseUrl?: string; freeChapters: number; maxDevices: number };

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const jwtSecret = env.JWT_SECRET ?? '';
  if (env.NODE_ENV === 'production' && jwtSecret.length < 32) throw new Error('JWT_SECRET must be at least 32 characters in production');
  return {
    port: Number(env.PORT ?? 4000),
    jwtSecret: jwtSecret || 'dev-only-secret-change-me-0000000000',
    databaseUrl: env.DATABASE_URL,
    freeChapters: 3,
    maxDevices: 2,
  };
}
