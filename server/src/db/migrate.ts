import { readdir, readFile } from 'node:fs/promises';
import { pool, tx } from './pool.ts';

const dir = new URL('../../migrations/', import.meta.url);

export async function migrate(): Promise<void> {
  await pool.query(
    'create table if not exists schema_migrations (name text primary key, applied_at timestamptz not null default now())',
  );
  const { rows } = await pool.query<{ name: string }>('select name from schema_migrations');
  const applied = new Set(rows.map((r) => r.name));
  for (const name of (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort()) {
    if (applied.has(name)) continue;
    const sql = await readFile(new URL(name, dir), 'utf8');
    await tx(async (c) => {
      await c.query(sql);
      await c.query('insert into schema_migrations (name) values ($1)', [name]);
    });
    console.log(`applied ${name}`);
  }
}

if (import.meta.main) {
  await migrate();
  await pool.end();
}
