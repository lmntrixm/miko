import { loadConfig } from './config.js';
import { migrate, pgDb } from './db.js';

const { databaseUrl } = loadConfig();
if (!databaseUrl) throw new Error('DATABASE_URL is required');
const db = pgDb(databaseUrl);
await migrate(db);
await db.close();
console.log('migrations applied');
