# Product Requirements Document

## Presence — Member App Backend

**Document status:** Backend specification for the existing member app\
**Version:** 2.0\
**Date:** 31 October 2026\
**Client:** Flutter member app already in this repository\
**Server:** Node.js, TypeScript, PostgreSQL

This document replaces the earlier multi-tenant specification (Cloudflare
Workers, D1, Resend OTP, owner panel, staff, and inactivity jobs). That
product is out of scope here. The Flutter screens stay as they are until a
later task connects them to this API. Until then the app keeps its in-memory
`MemberStore` and `SessionController`.

---

## 1. Product summary

Presence is a gym member app. A member signs in with email and password,
accepts the Terms and Privacy Policy, checks in by scanning the gym's code,
and reviews attendance, streaks, a weekly workout plan, and their profile.

This release is one gym and its members. There is no owner panel, no staff
accounts, and no self-serve registration screen. A seed script creates the gym,
the membership, and the member password so the API can be tested against the
current app.

### In scope

- Email and password login, session logout, and terms acceptance.
- Profile read and update (name and phone). Email is read-only.
- Attendance check-in, calendar, streaks, and the monthly summary.
- Weekly workout plan: rename a day, edit exercises, mark a day completed.
- The same business rules the Flutter app already computes in
  `lib/data/attendance_math.dart`.

### Out of scope

- OTP, email delivery, Resend, and the 6-digit code step.
- Owner panel, staff, invitations, registration UI, inactivity alerts,
  payments, analytics, and notifications.
- Cloudflare Workers, D1, and cron jobs.
- Changing Flutter code in this specification. Wiring `MemberStore` and
  `SessionController` to the API is a later task.
- QR display for the gym. A script issues the check-in code the member scans.

---

## 2. Users and access

There is one role: **member**.

A member can:

- Sign in with the email and password created for them.
- Accept the Terms of Service and Privacy Policy once.
- Sign out, which revokes the current session.
- View their gym name and membership dates.
- Scan a current gym check-in code and see success, expired, duplicate, or
  invalid.
- View their attendance calendar, current streak, longest streak, and monthly
  summary.
- Edit their own weekly workout plan and mark days completed.
- Edit their name and phone.

A member cannot view another member's rows. Email cannot be changed in the
app. Membership dates cannot be changed by the member.

---

## 3. Authentication

Password replaces OTP. There is no code screen and no email is sent at login.

### 3.1 Password

- Stored only as a hash (bcrypt or argon2). Never stored or logged in plaintext.
- Minimum 8 characters. No other composition rules.
- Compared in constant time via the hashing library.

### 3.2 Login

`POST /auth/login` with `{ "email", "password" }`.

- Email is trimmed and lower-cased before lookup.
- Unknown email and wrong password return the same `401` and the same message:
  `Email or password is incorrect.`
- Success returns a new opaque session token, its expiry, and
  `termsAccepted` (true only when both acceptance timestamps are set).
- Login is rate-limited per IP and per email.

### 3.3 Session

- The token is at least 32 bytes from a cryptographic random generator.
- Only the hash of the token is stored.
- The client sends `Authorization: Bearer <token>` on later requests. Cookies
  are not used, so the Flutter client can hold the token.
- Default lifetime is 30 days from login.
- `POST /auth/logout` revokes the presented session. Unknown or already
  revoked tokens still return `204`.
- Expired or revoked tokens receive `401` on protected routes.

### 3.4 Terms and privacy

The app already has `/terms` and `/privacy` pages. The server does not host
the legal copy. It records that this member accepted the versions currently
in the app.

- `POST /auth/accept-terms` sets `terms_accepted_at` and `privacy_accepted_at`
  to the current UTC time if they are null. It requires a valid session.
- Repeating the call does not move the timestamps.
- Before both timestamps are set, only these routes succeed: `POST /auth/login`,
  `POST /auth/logout`, `POST /auth/accept-terms`, and `GET /me`.
- Every other member route returns `403` with `terms_required`.

### 3.5 Sign out in the app

Sign out calls `POST /auth/logout`, drops the token, and returns to the sign-in
screen. It does not delete attendance or the workout plan. The old mock-store
reset on sign out does not apply once the app uses this API.

---

## 4. Member workflows

### 4.1 Sign in

1. Member opens the app and enters email and password.
2. `POST /auth/login`.
3. If `termsAccepted` is false, the app shows the Terms and Privacy Policy and
   asks for acceptance, then calls `POST /auth/accept-terms`.
4. The app loads `GET /me`, `GET /attendance/summary`, and `GET /workouts`,
   and opens Home.

Failure: invalid credentials stay on the sign-in screen with the generic
error. No OTP step exists.

### 4.2 Check in

1. Member opens Scan and grants camera access.
2. The app reads a code from the camera.
3. `POST /attendance/check-in` with `{ "code" }`.
4. The response is one of: `checked_in`, `expired`, `duplicate`, `invalid`.
5. Home and History use the updated attendance on the next read.

A cancelled scan or a request that fails on the network never counts as a
check-in. The client shows success only after this endpoint returns
`checked_in`.

### 4.3 Attendance history

1. Member opens History.
2. `GET /attendance/calendar?year=&month=` for the visible month.
3. Previous month is disabled before the membership start month. Next month is
   disabled on the current month in the gym timezone.

### 4.4 Workout plan

1. Member opens Plan.
2. `GET /workouts` returns Monday–Sunday.
3. Renaming a day, adding or removing an exercise, or toggling completed calls
   `PUT /workouts/:weekday`.
4. Completed is stored on the workout day only. It never inserts an attendance
   row.

### 4.5 Profile

1. `GET /me` fills name, phone, read-only email, gym name, and membership.
2. `PATCH /me` writes name and phone. A blank name is rejected.
3. Sign out follows section 3.5.

---

## 5. Business rules

These match `lib/data/attendance_math.dart`. Dates are gym-local calendar
dates. The seed gym timezone is `Asia/Kolkata`. "Today" is the current date in
that timezone.

1. **Open day.** A date is open when its weekday is not in the gym's closed
   weekdays and it falls on or after the membership start and on or before the
   membership end.
2. **One check-in per local day.** A second check-in for the same member, gym,
   and local date is a duplicate and does not insert another row.
3. **Future dates are never missed.** Days after today are Upcoming. Today is
   Today until a check-in exists; a check-in today is Present.
4. **Closed days neither count nor break a streak.** Days before the membership
   start or after it ends are Not joined.
5. **Current streak.** Count consecutive attended open days walking backward
   from today if today is attended, otherwise from yesterday. Skip closed days
   and days outside the membership. Stop at the first missed open day.
6. **Longest streak.** The longest run of attended open days from the membership
   start through today. An unattended today does not reset the run.
7. **Month summary.** `visits` is attended days in that month.
   `openDays` is open days in that month up to and including today.
   `pct` is `0` when `openDays` is `0`, otherwise
   `round(visits / openDays × 100)`.
8. **Membership status** is Active when today is inside start..end, otherwise
   Expired. The API does not model suspension.
9. **Workout completion is not attendance.**
10. **Check-in code.** The code must match a row for the member's gym whose
    `expires_at` is still in the future. A code whose plaintext contains
    `expired` (any case) is rejected as expired without a lookup. This keeps
    the app's existing test hook.

Day states returned by the calendar:

| State | When |
|-------|------|
| `present` | Attendance row exists |
| `today` | The gym-local today, with no attendance yet |
| `upcoming` | After today, inside the membership |
| `closed` | A closed weekday in the past, inside the membership |
| `missed` | An open day in the past with no attendance |
| `not_joined` | Outside the membership start..end |

---

## 6. Database

PostgreSQL. Use migrations, foreign keys, and parameterised queries. Server
timestamps are `timestamptz` in UTC. Calendar dates are `date`.

### 6.1 `gyms`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| name | text | Required |
| timezone | text | IANA name. Seed: `Asia/Kolkata` |
| closed_weekdays | smallint[] | `1` Monday … `7` Sunday, matching Dart `DateTime.weekday`. Seed: `{7}` |
| created_at | timestamptz | |

### 6.2 `users`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| gym_id | uuid | Foreign key. A member belongs to one gym |
| name | text | Required |
| email | text | Required, stored lower-case, unique |
| phone | text | Nullable |
| password_hash | text | Required |
| terms_accepted_at | timestamptz | Null until accepted |
| privacy_accepted_at | timestamptz | Null until accepted |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### 6.3 `memberships`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key, unique in this release (one membership) |
| gym_id | uuid | Foreign key |
| start_date | date | Inclusive |
| end_date | date | Inclusive |

Status is not stored. It is Active when the gym-local today is inside the
range, otherwise Expired.

### 6.4 `sessions`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key |
| token_hash | text | Unique. Hash of the bearer token |
| expires_at | timestamptz | |
| revoked_at | timestamptz | Null while usable |
| created_at | timestamptz | |

### 6.5 `attendance`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key |
| gym_id | uuid | Foreign key |
| attendance_date | date | Gym-local date |
| checked_in_at | timestamptz | UTC |
| created_at | timestamptz | |

Unique: `(user_id, gym_id, attendance_date)`.

### 6.6 `check_in_codes`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| gym_id | uuid | Foreign key |
| code_hash | text | Hash of the code the member scans |
| expires_at | timestamptz | |
| created_at | timestamptz | |

The plaintext code is shown once by the script that creates the row. It is not
stored. Suggested lifetime for a real gym code is 60 seconds. The seed script
may print a longer-lived development code and must say that it did.

### 6.7 `workout_days`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key |
| weekday | smallint | `1` Monday … `7` Sunday |
| name | text | Required. `Rest` means a rest day |
| completed | boolean | Default false |
| updated_at | timestamptz | |

Unique: `(user_id, weekday)`.

### 6.8 `workout_exercises`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| workout_day_id | uuid | Foreign key, cascade delete |
| position | integer | Order on the day, starting at 0 |
| name | text | Required |
| sets | text | Display string, for example `4 × 8` |

---

## 7. HTTP API

Base path `/`. JSON in and out. Errors use:

```json
{ "error": "machine_code", "message": "One sentence." }
```

Authenticated routes require `Authorization: Bearer`. The user id always comes
from the session, never from the body or query.

### 7.1 Auth

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/auth/login` | No | Email and password. Returns the token |
| POST | `/auth/accept-terms` | Yes | Records terms and privacy acceptance |
| POST | `/auth/logout` | Yes | Revokes this session |

Login success `200`:

```json
{
  "token": "<plaintext once>",
  "expiresAt": "2026-11-30T12:00:00.000Z",
  "termsAccepted": false
}
```

`POST /auth/accept-terms` returns `204`. Body is empty.

### 7.2 Profile

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/me` | Profile, gym, membership |
| PATCH | `/me` | Update `name` and `phone` |

`GET /me` `200`:

```json
{
  "id": "uuid",
  "name": "Priya Sharma",
  "email": "priya.sharma@example.com",
  "phone": "+91 98101 20034",
  "initials": "PS",
  "gym": { "id": "uuid", "name": "Iron Works Fitness" },
  "membership": {
    "startDate": "2026-01-12",
    "endDate": "2027-03-14",
    "status": "active"
  },
  "termsAccepted": true
}
```

`PATCH /me` accepts `{ "name", "phone" }`. Name must be non-blank after trim.
Email in the body is ignored. Response is the same shape as `GET /me`.

### 7.3 Attendance

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/attendance/summary` | Streaks, this week, current month |
| GET | `/attendance/calendar` | One month. Query `year`, `month` |
| POST | `/attendance/check-in` | Body `{ "code" }` |

Summary `200` includes `currentStreak`, `longestStreak`, `checkedInToday`,
`week` (seven days, Monday first, each with `date`, `state`, `weekdayLetter`),
and `month` (`name`, `visits`, `openDays`, `pct`).

Calendar `200` includes `year`, `month`, `visits`, `openDays`, `pct`,
`currentStreak`, `longestStreak`, and `days`. Each day has `date`, `state`,
and a label such as `October 14, attended`. Streaks are overall, not monthly.
`404` if the month is before the membership start month or after the current
month.

Check-in `200`:

```json
{ "result": "checked_in", "attendanceDate": "2026-10-31", "checkedInAt": "...", "currentStreak": 13 }
```

`result` is `checked_in`, `expired`, `duplicate`, or `invalid`. Duplicate and
expired and invalid do not insert a row. `checked_in` is returned only after
the insert commits.

### 7.4 Workouts

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/workouts` | Seven days, Monday first, with exercises |
| PUT | `/workouts/:weekday` | Replace one day. `weekday` is `1`–`7` |

`PUT` body:

```json
{
  "name": "Legs",
  "completed": false,
  "exercises": [{ "name": "Back squat", "sets": "4 × 8" }]
}
```

Blank exercise names are dropped. A blank `sets` becomes `3 × 10`. The
exercise list replaces the previous list for that day. `completed` defaults
to the stored value when omitted. Response is that day. This endpoint must
not write `attendance`.

---

## 8. Seed script

`npm run seed` is idempotent for the development database. It creates:

- Gym **Iron Works Fitness**, timezone `Asia/Kolkata`, closed on Sunday.
- User **Priya Sharma**, email `priya.sharma@example.com`, phone
  `+91 98101 20034`. The password comes from the `SEED_PASSWORD` environment
  variable (at least 8 characters). The script prints the email and refuses to
  print the password.
- Membership start `2026-01-12`, end `2027-03-14`.
- Attendance from the membership start through yesterday in the gym timezone,
  using the same pattern as `buildSeedAttendance` in `lib/data/mock/seed.dart`:
  the 12 most recent open days present, the next open day missed, the next 21
  open days present, the next open day missed, then repeating four present and
  one missed back to the start. Today is not checked in, so the current streak
  is 12 and the longest is 21.
- Workout plan Monday–Sunday: Chest, Back, Shoulders, Arms, Legs, Cardio, Rest,
  with the exercises in that seed file. `completed` is true only for weekdays
  earlier than today in the current week.
- One development check-in code, valid for 24 hours, printed once in plaintext.

Acceptance timestamps stay null so the first login must accept the terms.

---

## 9. Server stack

| Piece | Choice |
|-------|--------|
| Runtime | Node.js |
| Language | TypeScript |
| HTTP | Express |
| Database | PostgreSQL |
| Access | `pg` with SQL migrations (no ORM required) |
| Passwords | bcrypt or argon2 |
| Config | Environment variables for `DATABASE_URL`, `PORT`, and `SEED_PASSWORD` |

Suggested layout, separate from the Flutter app:

```text
server/
├── src/
│   ├── index.ts
│   ├── auth/
│   ├── attendance/
│   ├── workouts/
│   └── db/
├── migrations/
├── seed.ts
└── package.json
```

The Flutter app is not modified by standing up this server.

---

## 10. Security

- Generic login errors. No field that says which of email or password failed.
- Passwords and session tokens are hashed at rest. Check-in codes are hashed
  at rest.
- Login is rate-limited.
- Every query for member data includes the session user's id.
- SQL uses parameters only.
- HTTPS in any deployed environment.
- Logs omit passwords, tokens, and check-in codes.
- No OTP is generated, stored, or sent.

---

## 11. Errors

| Case | Result |
|------|--------|
| Wrong email or password | `401`, generic message |
| Missing or bad bearer token | `401` |
| Logged in, terms not accepted, member route | `403` `terms_required` |
| Blank name on profile save | `400` |
| Check-in code contains `expired` or is past `expires_at` | `200` `expired` |
| Check-in code does not match this gym | `200` `invalid` |
| Already checked in today | `200` `duplicate` |
| Calendar month out of range | `404` |
| Weekday outside `1`–`7` | `400` |

Check-in outcomes are `200` with a `result` so the app can show the matching
screen without treating them as transport failures. A dropped connection is
not `checked_in`.

---

## 12. Acceptance

- A seeded member can log in with email and password and cannot log in with a
  wrong password.
- No route accepts a 6-digit code or sends email.
- Before terms acceptance, attendance and workout routes return `403`.
  `POST /auth/accept-terms` then lets them through.
- Logout revokes the token. The same token then receives `401`.
- A valid code records one attendance row for today and raises the current
  streak from 12 to 13 on the seed data.
- A second check-in the same day returns `duplicate` and does not add a row.
- An expired code does not add a row.
- History figures use the rules in section 5. Future days are not missed.
  Sundays are closed and do not break the streak.
- Marking a workout day completed does not change attendance.
- Profile save changes name and phone and leaves email unchanged.
- One member cannot read another member's attendance or plan by changing an id.

---

## 13. Later, not in this document

Connecting the Flutter sign-in screen to `POST /auth/login`, dropping the OTP
code route in the app, and replacing the in-memory store with these endpoints.
Owner tools, rotating QR display, and inactivity detection stay out until a
separate specification says otherwise.
