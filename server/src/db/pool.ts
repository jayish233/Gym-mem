import pg from 'pg';

// Keep `date` columns as 'YYYY-MM-DD' strings; the default parser shifts them by the server timezone.
pg.types.setTypeParser(1082, (v) => v);

export const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

export type Db = pg.Pool | pg.PoolClient;

export async function tx<T>(fn: (c: pg.PoolClient) => Promise<T>): Promise<T> {
  const c = await pool.connect();
  try {
    await c.query('begin');
    const result = await fn(c);
    await c.query('commit');
    return result;
  } catch (e) {
    await c.query('rollback');
    throw e;
  } finally {
    c.release();
  }
}
