import { randomBytes, scryptSync } from 'node:crypto';
const pw = process.argv[2];
if (!pw) { console.error('usage: npm run admin:hash -- "<password>"'); process.exit(1); }
const salt = randomBytes(16).toString('hex');
console.log(`scrypt$${salt}$${scryptSync(pw, salt, 32).toString('hex')}`);
