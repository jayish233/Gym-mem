import { createHash } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { pool } from '../db/pool.ts';

export type SessionUser = { id: string; gym_id: string; terms_accepted: boolean };

export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');

export function fail(res: Response, status: number, error: string, message: string): void {
  res.status(status).json({ error, message });
}

export const bearer = (req: Request) => /^Bearer (\S+)$/.exec(req.get('authorization') ?? '')?.[1];

/** The signed-in user, set by requireSession. */
export const userOf = (res: Response) => res.locals.user as SessionUser;

export async function requireSession(req: Request, res: Response, next: NextFunction) {
  const token = bearer(req);
  if (!token) return fail(res, 401, 'unauthorized', 'Sign in to continue.');
  const { rows } = await pool.query<SessionUser>(
    `select u.id, u.gym_id,
            (u.terms_accepted_at is not null and u.privacy_accepted_at is not null) as terms_accepted
       from sessions s join users u on u.id = s.user_id
      where s.token_hash = $1 and s.revoked_at is null and s.expires_at > now()`,
    [sha256(token)],
  );
  if (!rows[0]) return fail(res, 401, 'unauthorized', 'Sign in to continue.');
  res.locals.user = rows[0];
  next();
}

/** Section 3.4: member routes wait for terms and privacy acceptance. */
export function requireTerms(_req: Request, res: Response, next: NextFunction) {
  if (!userOf(res).terms_accepted) {
    return fail(res, 403, 'terms_required', 'Accept the Terms and Privacy Policy to continue.');
  }
  next();
}

// shortcut: in-memory and per process, resets on restart; move to Postgres or Redis when running more than one instance.
const hits = new Map<string, { n: number; reset: number }>();

/** Fixed-window counter. True once `key` passes `limit` hits in the window. */
export function tooMany(key: string, limit: number, windowMs = 15 * 60_000): boolean {
  const now = Date.now();
  if (hits.size > 10_000) for (const [k, h] of hits) if (h.reset <= now) hits.delete(k);
  let h = hits.get(key);
  if (!h || h.reset <= now) hits.set(key, (h = { n: 0, reset: now + windowMs }));
  return ++h.n > limit;
}
