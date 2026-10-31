import express, { type NextFunction, type Request, type Response } from 'express';
import { attendance } from './attendance/routes.ts';
import { auth } from './auth/routes.ts';
import { fail } from './auth/session.ts';
import { workouts } from './workouts/routes.ts';

export const app = express();
app.disable('x-powered-by');
// Set TRUST_PROXY (e.g. "1") behind a load balancer so login rate limits see the client IP.
if (process.env.TRUST_PROXY) app.set('trust proxy', process.env.TRUST_PROXY);
app.use(express.json());
app.get('/health', (_req, res) => void res.json({ ok: true })); // host liveness check, no DB
app.use(auth, attendance, workouts);

app.use((_req, res) => fail(res, 404, 'not_found', 'No such route.'));

// Never log request bodies: they carry passwords and check-in codes.
app.use((err: { status?: number; type?: string }, req: Request, res: Response, _next: NextFunction) => {
  if (err.status && err.status < 500) return fail(res, err.status, 'bad_request', 'The request body could not be read.');
  console.error(`${req.method} ${req.path}`, err);
  fail(res, 500, 'server_error', 'Something went wrong. Try again.');
});
