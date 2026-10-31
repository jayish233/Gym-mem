import { randomBytes } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { localDate, inMembership } from '../attendance/math.ts';
import { pool } from '../db/pool.ts';
import { bearer, fail, requireSession, requireTerms, sha256, tooMany, userOf } from './session.ts';

export const BCRYPT_COST = 12;
const SESSION_DAYS = 30;
// Compared against when the email is unknown so both failures take the same time.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', BCRYPT_COST);

export const auth = Router();

auth.post('/auth/login', async (req, res) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body?.password === 'string' ? req.body.password : '';
  if (tooMany(`ip:${req.ip}`, 30) || tooMany(`email:${email}`, 10)) {
    return fail(res, 429, 'rate_limited', 'Too many attempts. Try again in 15 minutes.');
  }
  const { rows } = await pool.query(
    `select id, password_hash,
            (terms_accepted_at is not null and privacy_accepted_at is not null) as terms_accepted
       from users where email = $1`,
    [email],
  );
  const ok = await bcrypt.compare(password, rows[0]?.password_hash ?? DUMMY_HASH);
  if (!rows[0] || !ok) return fail(res, 401, 'invalid_credentials', 'Email or password is incorrect.');

  const token = randomBytes(32).toString('base64url');
  const expiresAt = new Date(Date.now() + SESSION_DAYS * 86_400_000);
  await pool.query('insert into sessions (user_id, token_hash, expires_at) values ($1, $2, $3)', [
    rows[0].id,
    sha256(token),
    expiresAt,
  ]);
  res.json({ token, expiresAt: expiresAt.toISOString(), termsAccepted: rows[0].terms_accepted });
});

// Unknown or already revoked tokens still get 204.
auth.post('/auth/logout', async (req, res) => {
  const token = bearer(req);
  if (!token) return fail(res, 401, 'unauthorized', 'Sign in to continue.');
  await pool.query('update sessions set revoked_at = now() where token_hash = $1 and revoked_at is null', [
    sha256(token),
  ]);
  res.status(204).end();
});

auth.post('/auth/accept-terms', requireSession, async (_req, res) => {
  await pool.query(
    `update users set terms_accepted_at = coalesce(terms_accepted_at, now()),
                      privacy_accepted_at = coalesce(privacy_accepted_at, now())
      where id = $1`,
    [userOf(res).id],
  );
  res.status(204).end();
});

async function profile(userId: string) {
  const { rows } = await pool.query(
    `select u.id, u.name, u.email, u.phone, g.id as gym_id, g.name as gym_name, g.timezone,
            m.start_date, m.end_date,
            (u.terms_accepted_at is not null and u.privacy_accepted_at is not null) as terms_accepted
       from users u join gyms g on g.id = u.gym_id join memberships m on m.user_id = u.id
      where u.id = $1`,
    [userId],
  );
  const r = rows[0];
  const membership = { startDate: r.start_date, endDate: r.end_date };
  return {
    id: r.id,
    name: r.name,
    email: r.email,
    phone: r.phone,
    initials: (r.name as string)
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((p) => p[0].toUpperCase())
      .join(''),
    gym: { id: r.gym_id, name: r.gym_name },
    membership: { ...membership, status: inMembership(localDate(r.timezone), membership) ? 'active' : 'expired' },
    termsAccepted: r.terms_accepted,
  };
}

// GET /me works before terms acceptance; PATCH does not.
auth.get('/me', requireSession, async (_req, res) => {
  res.json(await profile(userOf(res).id));
});

auth.patch('/me', requireSession, requireTerms, async (req, res) => {
  const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
  if (!name) return fail(res, 400, 'invalid_name', 'Enter your name.');
  const phone = typeof req.body?.phone === 'string' ? req.body.phone.trim() || null : null;
  await pool.query('update users set name = $2, phone = $3, updated_at = now() where id = $1', [
    userOf(res).id,
    name,
    phone,
  ]);
  res.json(await profile(userOf(res).id));
});
