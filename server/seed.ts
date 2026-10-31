import bcrypt from 'bcryptjs';
import { issueCode } from './src/attendance/routes.ts';
import { addDays, isOpenDay, localDate, weekday, type Gym, type Membership } from './src/attendance/math.ts';
import { BCRYPT_COST } from './src/auth/routes.ts';
import { migrate } from './src/db/migrate.ts';
import { pool, tx } from './src/db/pool.ts';

export const SEED_EMAIL = 'priya.sharma@example.com';
const GYM = 'Iron Works Fitness';
const TIMEZONE = 'Asia/Kolkata';
const gym: Gym = { closedWeekdays: [7] };
const membership: Membership = { startDate: '2026-01-12', endDate: '2027-03-14' };

// Same plan as buildSeedPlan in lib/data/mock/seed.dart, Monday first.
const plan: [string, [string, string][]][] = [
  ['Chest', [['Bench press', '4 × 8'], ['Incline dumbbell press', '3 × 10'], ['Cable fly', '3 × 12']]],
  ['Back', [['Pull-up', '4 × 6'], ['Barbell row', '4 × 8']]],
  ['Shoulders', [['Overhead press', '4 × 8'], ['Lateral raise', '3 × 15']]],
  ['Arms', [['Barbell curl', '3 × 10'], ['Triceps pushdown', '3 × 12']]],
  ['Legs', [['Back squat', '4 × 8'], ['Leg press', '3 × 12'], ['Romanian deadlift', '3 × 10']]],
  ['Cardio', [['Incline walk', '30 min']]],
  ['Rest', []],
];

/** Same pattern as buildSeedAttendance: 12 present, 1 missed, 21 present, 1 missed, then 4 present 1 missed. */
export function seedAttendance(today: string): string[] {
  const yesterday = addDays(today, -1);
  const dates: string[] = [];
  let i = 0;
  for (let d = yesterday > membership.endDate ? membership.endDate : yesterday; d >= membership.startDate; d = addDays(d, -1)) {
    if (!isOpenDay(d, gym, membership)) continue;
    if (i < 12 || (i > 12 && i < 34) || (i > 34 && (i - 35) % 5 < 4)) dates.push(d);
    i++;
  }
  return dates;
}

/** Recreates the seed gym and member from scratch, so running it twice gives the same state. */
export async function seed(password: string) {
  if (password.length < 8) throw new Error('SEED_PASSWORD must be at least 8 characters.');
  const passwordHash = await bcrypt.hash(password, BCRYPT_COST);
  const today = localDate(TIMEZONE);
  return tx(async (c) => {
    await c.query('delete from users where email = $1', [SEED_EMAIL]);
    await c.query('delete from gyms where name = $1', [GYM]); // cascades to everything the gym owns
    const g = await c.query('insert into gyms (name, timezone, closed_weekdays) values ($1, $2, $3) returning id', [
      GYM,
      TIMEZONE,
      gym.closedWeekdays,
    ]);
    const gymId: string = g.rows[0].id;
    const u = await c.query(
      'insert into users (gym_id, name, email, phone, password_hash) values ($1, $2, $3, $4, $5) returning id',
      [gymId, 'Priya Sharma', SEED_EMAIL, '+91 98101 20034', passwordHash],
    );
    const userId: string = u.rows[0].id;
    await c.query('insert into memberships (user_id, gym_id, start_date, end_date) values ($1, $2, $3, $4)', [
      userId,
      gymId,
      membership.startDate,
      membership.endDate,
    ]);
    await c.query(
      `insert into attendance (user_id, gym_id, attendance_date, checked_in_at)
       select $1, $2, d, (d + time '18:30') at time zone $4 from unnest($3::date[]) d`,
      [userId, gymId, seedAttendance(today), TIMEZONE],
    );
    for (const [i, [name, exercises]] of plan.entries()) {
      const day = await c.query(
        'insert into workout_days (user_id, weekday, name, completed) values ($1, $2, $3, $4) returning id',
        [userId, i + 1, name, i + 1 < weekday(today)],
      );
      for (const [pos, [ex, sets]] of exercises.entries()) {
        await c.query('insert into workout_exercises (workout_day_id, position, name, sets) values ($1, $2, $3, $4)', [
          day.rows[0].id,
          pos,
          ex,
          sets,
        ]);
      }
    }
    return { userId, gymId, ...(await issueCode(c, gymId, 24 * 60 * 60)) };
  });
}

if (import.meta.main) {
  await migrate();
  const { code, expiresAt } = await seed(process.env.SEED_PASSWORD ?? '');
  console.log(`Seeded ${GYM} and member ${SEED_EMAIL} (password from SEED_PASSWORD, not printed).`);
  console.log(`Development check-in code, valid 24 hours (a real gym code lasts 60 seconds), until ${expiresAt.toISOString()}:`);
  console.log(code);
  await pool.end();
}
