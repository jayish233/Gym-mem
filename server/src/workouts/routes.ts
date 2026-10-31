import { Router } from 'express';
import { pool, tx, type Db } from '../db/pool.ts';
import { fail, requireSession, requireTerms, userOf } from '../auth/session.ts';

async function selectDays(db: Db, userId: string, weekday?: number) {
  const { rows } = await db.query(
    `select d.weekday, d.name, d.completed,
            coalesce(json_agg(json_build_object('name', e.name, 'sets', e.sets) order by e.position)
                       filter (where e.id is not null), '[]') as exercises
       from workout_days d left join workout_exercises e on e.workout_day_id = d.id
      where d.user_id = $1 and ($2::smallint is null or d.weekday = $2)
      group by d.id
      order by d.weekday`,
    [userId, weekday ?? null],
  );
  return rows;
}

const MAX_EXERCISES = 50;
const MAX_TEXT = 100;

export const workouts = Router();
workouts.use('/workouts', requireSession, requireTerms);

workouts.get('/workouts', async (_req, res) => {
  res.json(await selectDays(pool, userOf(res).id));
});

// Writes workout_days and workout_exercises only, never attendance (business rule 9).
workouts.put('/workouts/:weekday', async (req, res) => {
  if (!/^[1-7]$/.test(req.params.weekday)) return fail(res, 400, 'invalid_weekday', 'Weekday must be 1 to 7.');
  const weekday = Number(req.params.weekday);
  const body = req.body ?? {};

  let name: string | null = null;
  if (body.name !== undefined) {
    name = typeof body.name === 'string' ? body.name.trim() : '';
    if (!name) return fail(res, 400, 'invalid_name', 'Name the workout, or call it Rest.');
  }
  if (body.completed !== undefined && typeof body.completed !== 'boolean') {
    return fail(res, 400, 'invalid_completed', 'completed must be true or false.');
  }
  if (body.exercises !== undefined && !(Array.isArray(body.exercises) && body.exercises.length <= MAX_EXERCISES)) {
    return fail(res, 400, 'invalid_exercises', `exercises must be a list of at most ${MAX_EXERCISES}.`);
  }
  if (name && name.length > MAX_TEXT) return fail(res, 400, 'invalid_name', `Keep the name under ${MAX_TEXT} characters.`);
  const str = (v: unknown) => (typeof v === 'string' ? v.trim().slice(0, MAX_TEXT) : '');
  const exercises = (body.exercises as unknown[] | undefined)
    ?.map((e) => ({ name: str((e as any)?.name), sets: str((e as any)?.sets) || '3 × 10' }))
    .filter((e) => e.name);

  const userId = userOf(res).id;
  const day = await tx(async (c) => {
    const { rows } = await c.query(
      `update workout_days set name = coalesce($3, name), completed = coalesce($4, completed), updated_at = now()
        where user_id = $1 and weekday = $2 returning id`,
      [userId, weekday, name, body.completed ?? null],
    );
    if (!rows[0]) return undefined;
    if (exercises) {
      await c.query('delete from workout_exercises where workout_day_id = $1', [rows[0].id]);
      for (const [i, e] of exercises.entries()) {
        await c.query('insert into workout_exercises (workout_day_id, position, name, sets) values ($1, $2, $3, $4)', [
          rows[0].id,
          i,
          e.name,
          e.sets,
        ]);
      }
    }
    return (await selectDays(c, userId, weekday))[0];
  });
  if (!day) return fail(res, 404, 'not_found', 'No plan for that day.');
  res.json(day);
});
