import { buildApp, type Mailer } from './app.js';
import { loadConfig } from './config.js';
import { migrate, pgDb, pgliteDb } from './db.js';
import { seed } from './seed.js';

const config = loadConfig();
const db = config.databaseUrl ? pgDb(config.databaseUrl) : await pgliteDb('.pglite');
await migrate(db);
if (process.env.SEED === '1') await seed(db);

// Dev mailer prints codes. Production must provide a real sender: refuse to boot without one.
if (process.env.NODE_ENV === 'production') throw new Error('No production Mailer configured yet ([ایمیل] sender is a placeholder)');
const mailer: Mailer = { sendCode: async (email, code, purpose) => console.log(`[dev mail] ${purpose} code for ${email}: ${code}`) };

const app = await buildApp({ db, config, mailer });
await app.listen({ port: config.port, host: '0.0.0.0' });
console.log(`miko backend on :${config.port}`);
