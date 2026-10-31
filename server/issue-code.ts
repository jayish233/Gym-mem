// Prints a fresh check-in code for the gym. Usage: npm run code [-- <seconds>]
import { issueCode } from './src/attendance/routes.ts';
import { pool } from './src/db/pool.ts';

const ttl = Number(process.argv[2] ?? 60);
// This release has exactly one gym.
const { rows } = await pool.query('select id, name from gyms order by created_at limit 1');
if (!rows[0]) throw new Error('No gym yet. Run npm run seed first.');
const { code, expiresAt } = await issueCode(pool, rows[0].id, ttl);
console.log(`Check-in code for ${rows[0].name}, valid until ${expiresAt.toISOString()}:`);
console.log(code);
await pool.end();
