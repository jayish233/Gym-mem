// End-to-end against a real database. Wipes and reseeds the seed gym, so point
// DATABASE_URL at a development or test database.
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import { after, before, test } from 'node:test';
import { localDate, weekday } from '../src/attendance/math.ts';
import { issueCode } from '../src/attendance/routes.ts';
import { app } from '../src/app.ts';
import { migrate } from '../src/db/migrate.ts';
import { pool } from '../src/db/pool.ts';
import { SEED_EMAIL, seed } from '../seed.ts';

const skip = !process.env.DATABASE_URL && 'DATABASE_URL is not set';
const PASSWORD = 'correct-horse-1';
let base = '';
let code = '';
let seeded: { userId: string; gymId: string };
const server = app.listen(0);

async function call(method: string, path: string, token?: string, body?: unknown) {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token && { authorization: `Bearer ${token}` }) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : undefined };
}

const login = async (email: string, password: string) => (await call('POST', '/auth/login', undefined, { email, password })).body.token;

before(async () => {
  if (skip) return;
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  await migrate();
  ({ code, ...seeded } = await seed(PASSWORD));
});
after(async () => {
  server.close();
  await pool.end();
});

test('login, terms gate, and logout', { skip }, async () => {
  const wrong = await call('POST', '/auth/login', undefined, { email: SEED_EMAIL, password: 'nope-nope' });
  const unknown = await call('POST', '/auth/login', undefined, { email: 'x@example.com', password: PASSWORD });
  assert.equal(wrong.status, 401);
  assert.deepEqual(unknown, wrong);
  assert.equal(wrong.body.message, 'Email or password is incorrect.');

  const ok = await call('POST', '/auth/login', undefined, { email: ` ${SEED_EMAIL.toUpperCase()} `, password: PASSWORD });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.termsAccepted, false);
  const token = ok.body.token;

  assert.equal((await call('GET', '/me', token)).status, 200);
  for (const path of ['/attendance/summary', '/workouts']) {
    const r = await call('GET', path, token);
    assert.equal(r.status, 403);
    assert.equal(r.body.error, 'terms_required');
  }
  assert.equal((await call('POST', '/auth/accept-terms', token)).status, 204);
  assert.equal((await call('GET', '/workouts', token)).status, 200);

  assert.equal((await call('POST', '/auth/logout', token)).status, 204);
  assert.equal((await call('GET', '/me', token)).status, 401);
  assert.equal((await call('POST', '/auth/logout', token)).status, 204);
  assert.equal((await call('GET', '/me')).status, 401);
});

test('no route accepts a 6-digit code', { skip }, async () => {
  for (const path of ['/auth/verify', '/auth/code', '/auth/otp', '/auth/send-code', '/auth/register', '/signin/code']) {
    assert.equal((await call('POST', path, undefined, { email: SEED_EMAIL, code: '123456' })).status, 404);
  }
  assert.equal((await call('POST', '/auth/login', undefined, { email: SEED_EMAIL, code: '123456' })).status, 401);
  assert.equal((await call('POST', '/auth/login', undefined, { email: SEED_EMAIL, password: '123456' })).status, 401);
});

test('check-in, streaks, workouts, profile', { skip }, async () => {
  const token = await login(SEED_EMAIL, PASSWORD);
  const today = localDate('Asia/Kolkata');

  const summary = (await call('GET', '/attendance/summary', token)).body;
  assert.equal(summary.today, today);
  assert.equal(summary.currentStreak, 12);
  assert.equal(summary.longestStreak, 21);
  assert.equal(summary.checkedInToday, false);
  assert.equal(summary.week.length, 7);
  assert.equal(summary.week[0].weekdayLetter, 'M');

  // Completing a workout never touches attendance.
  const done = await call('PUT', '/workouts/1', token, { completed: true });
  assert.equal(done.body.completed, true);
  assert.equal(done.body.name, 'Chest');
  assert.equal(done.body.exercises.length, 3);
  assert.equal((await call('GET', '/attendance/summary', token)).body.checkedInToday, false);

  const edited = await call('PUT', '/workouts/5', token, {
    name: ' Legs day ',
    exercises: [{ name: 'Back squat', sets: '5 × 5' }, { name: '  ', sets: '1' }, { name: 'Lunge', sets: '' }],
  });
  assert.deepEqual(edited.body.exercises, [
    { name: 'Back squat', sets: '5 × 5' },
    { name: 'Lunge', sets: '3 × 10' },
  ]);
  assert.equal(edited.body.name, 'Legs day');
  assert.equal((await call('PUT', '/workouts/8', token, {})).status, 400);

  const rows = async () =>
    (await pool.query('select count(*)::int as n from attendance where user_id = $1 and attendance_date = $2', [seeded.userId, today])).rows[0].n;

  const nothing = (result: string) => ({ result, attendanceDate: null, checkedInAt: null, currentStreak: 12 });
  const stale = await issueCode(pool, seeded.gymId, -60);
  assert.deepEqual((await call('POST', '/attendance/check-in', token, { code: 'gym-EXPIRED-1' })).body, nothing('expired'));
  assert.deepEqual((await call('POST', '/attendance/check-in', token, { code: stale.code })).body, nothing('expired'));
  assert.deepEqual((await call('POST', '/attendance/check-in', token, { code: 'not-a-code' })).body, nothing('invalid'));
  assert.deepEqual((await call('POST', '/attendance/check-in', token, { code: '123456' })).body, nothing('invalid'));
  assert.equal(await rows(), 0);

  const ok = (await call('POST', '/attendance/check-in', token, { code })).body;
  assert.equal(ok.result, 'checked_in');
  assert.equal(ok.attendanceDate, today);
  // Sunday is closed, so a Sunday visit does not add to the streak.
  assert.equal(ok.currentStreak, weekday(today) === 7 ? 12 : 13);
  const dup = (await call('POST', '/attendance/check-in', token, { code })).body;
  assert.deepEqual(dup, { ...ok, result: 'duplicate' });
  assert.equal(await rows(), 1);

  const [y, m] = today.split('-').map(Number);
  const cal = (await call('GET', `/attendance/calendar?year=${y}&month=${m}`, token)).body;
  assert.ok(cal.days.filter((d: any) => d.date > today).every((d: any) => d.state === 'upcoming' || d.state === 'not_joined'));
  assert.ok(cal.days.filter((d: any) => weekday(d.date) === 7 && d.date < today).every((d: any) => d.state === 'closed'));
  assert.equal(cal.days.find((d: any) => d.date === today).state, 'present');
  assert.equal((await call('GET', '/attendance/calendar?year=2025&month=12', token)).status, 404);
  assert.equal((await call('GET', `/attendance/calendar?year=${y + 1}&month=${m}`, token)).status, 404);
  assert.equal((await call('GET', '/attendance/calendar?year=2026&month=1', token)).body.days[0].label, 'January 1, before your membership');

  assert.equal((await call('PATCH', '/me', token, { name: '  ', phone: '1' })).status, 400);
  const me = (await call('PATCH', '/me', token, { name: 'Priya S', phone: '+91 1', email: 'evil@example.com' })).body;
  assert.equal(me.name, 'Priya S');
  assert.equal(me.phone, '+91 1');
  assert.equal(me.email, SEED_EMAIL);
  assert.equal(me.initials, 'PS');
  assert.equal(me.membership.status, 'active');
});

test('a member only sees their own rows', { skip }, async () => {
  const other = await pool.query(
    `insert into users (gym_id, name, email, password_hash, terms_accepted_at, privacy_accepted_at)
     select gym_id, 'Other Member', 'other@example.com', password_hash, now(), now() from users where id = $1 returning id`,
    [seeded.userId],
  );
  await pool.query(`insert into memberships (user_id, gym_id, start_date, end_date) values ($1, $2, '2026-01-12', '2027-03-14')`, [
    other.rows[0].id,
    seeded.gymId,
  ]);
  const token = await login('other@example.com', PASSWORD);
  assert.deepEqual((await call('GET', `/workouts?userId=${seeded.userId}`, token)).body, []);
  assert.equal((await call('GET', '/attendance/summary', token)).body.currentStreak, 0);
  assert.equal((await call('PUT', '/workouts/1', token, { completed: true })).status, 404);
  await pool.query('delete from users where id = $1', [other.rows[0].id]);
});
