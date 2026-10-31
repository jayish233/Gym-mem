import { randomBytes } from 'node:crypto';
import { Router } from 'express';
import { pool, type Db } from '../db/pool.ts';
import { fail, requireSession, requireTerms, sha256, userOf } from '../auth/session.ts';
import {
  addDays,
  currentStreak,
  dayLabel,
  dayState,
  localDate,
  longestStreak,
  monthDays,
  monthName,
  monthSummary,
  weekday,
  type Gym,
  type Membership,
} from './math.ts';

/** Creates a check-in code for a gym and returns its plaintext. Only the hash is stored. */
export async function issueCode(db: Db, gymId: string, ttlSeconds: number): Promise<{ code: string; expiresAt: Date }> {
  const code = randomBytes(9).toString('base64url');
  const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
  await db.query('insert into check_in_codes (gym_id, code_hash, expires_at) values ($1, $2, $3)', [
    gymId,
    sha256(code),
    expiresAt,
  ]);
  return { code, expiresAt };
}

async function load(userId: string) {
  const { rows } = await pool.query(
    `select g.timezone, g.closed_weekdays, m.start_date, m.end_date,
            array(select attendance_date::text from attendance a where a.user_id = u.id and a.gym_id = u.gym_id) as dates
       from users u join gyms g on g.id = u.gym_id join memberships m on m.user_id = u.id
      where u.id = $1`,
    [userId],
  );
  const r = rows[0];
  const gym: Gym = { closedWeekdays: r.closed_weekdays };
  const m: Membership = { startDate: r.start_date, endDate: r.end_date };
  return { gym, m, timezone: r.timezone as string, attended: new Set<string>(r.dates), today: localDate(r.timezone) };
}

export const attendance = Router();
attendance.use('/attendance', requireSession, requireTerms);

attendance.get('/attendance/summary', async (_req, res) => {
  const { gym, m, attended, today } = await load(userOf(res).id);
  const monday = addDays(today, 1 - weekday(today));
  const week = [0, 1, 2, 3, 4, 5, 6].map((i) => {
    const date = addDays(monday, i);
    return { date, state: dayState(date, attended, today, gym, m), weekdayLetter: 'MTWTFSS'[i] };
  });
  const [y, mo] = today.split('-').map(Number);
  res.json({
    currentStreak: currentStreak(attended, today, gym, m),
    longestStreak: longestStreak(attended, today, gym, m),
    checkedInToday: attended.has(today),
    week,
    month: { name: monthName(today), ...monthSummary(y, mo, attended, today, gym, m) },
  });
});

attendance.get('/attendance/calendar', async (req, res) => {
  const year = Number(req.query.year);
  const month = Number(req.query.month);
  if (!Number.isInteger(year) || !Number.isInteger(month) || month < 1 || month > 12) {
    return fail(res, 400, 'invalid_month', 'Send year and month as numbers.');
  }
  const { gym, m, attended, today } = await load(userOf(res).id);
  const key = `${year}-${String(month).padStart(2, '0')}`;
  if (key < m.startDate.slice(0, 7) || key > today.slice(0, 7)) {
    return fail(res, 404, 'month_out_of_range', 'That month is outside your membership.');
  }
  res.json({
    year,
    month,
    ...monthSummary(year, month, attended, today, gym, m),
    currentStreak: currentStreak(attended, today, gym, m),
    longestStreak: longestStreak(attended, today, gym, m),
    days: monthDays(year, month).map((date) => {
      const state = dayState(date, attended, today, gym, m);
      return { date, state, label: dayLabel(date, state) };
    }),
  });
});

attendance.post('/attendance/check-in', async (req, res) => {
  const user = userOf(res);
  const code = typeof req.body?.code === 'string' ? req.body.code.trim() : '';
  const { gym, m, attended, today } = await load(user.id);

  // Every outcome has the same shape (CLAUDE.md 8.3). Dates are null when nothing is recorded today.
  const reply = (result: string, checkedInAt: Date | null = null) =>
    void res.json({
      result,
      attendanceDate: checkedInAt ? today : null,
      checkedInAt: checkedInAt?.toISOString() ?? null,
      currentStreak: currentStreak(attended, today, gym, m),
    });
  const existing = async (): Promise<Date> =>
    (
      await pool.query(
        'select checked_in_at from attendance where user_id = $1 and gym_id = $2 and attendance_date = $3',
        [user.id, user.gym_id, today],
      )
    ).rows[0].checked_in_at;

  // Same order as the app's Scan screen: duplicate, then the expired test hook, then lookup.
  if (attended.has(today)) return reply('duplicate', await existing());
  if (/expired/i.test(code)) return reply('expired');
  if (!code) return reply('invalid');

  const { rows: codes } = await pool.query(
    'select expires_at > now() as live from check_in_codes where gym_id = $1 and code_hash = $2 order by expires_at desc limit 1',
    [user.gym_id, sha256(code)],
  );
  if (!codes[0]) return reply('invalid');
  if (!codes[0].live) return reply('expired');

  // The unique key settles two scans racing for the same day.
  const { rows } = await pool.query(
    `insert into attendance (user_id, gym_id, attendance_date, checked_in_at)
     values ($1, $2, $3, now())
     on conflict do nothing
     returning checked_in_at`,
    [user.id, user.gym_id, today],
  );
  attended.add(today);
  if (!rows[0]) return reply('duplicate', await existing());
  reply('checked_in', rows[0].checked_in_at);
});
