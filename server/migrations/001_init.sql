create table gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  timezone text not null,
  closed_weekdays smallint[] not null default '{}', -- 1 Monday … 7 Sunday
  created_at timestamptz not null default now()
);

create table users (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references gyms on delete cascade,
  name text not null check (btrim(name) <> ''),
  email text not null unique check (email = lower(email)),
  phone text,
  password_hash text not null,
  terms_accepted_at timestamptz,
  privacy_accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users on delete cascade,
  gym_id uuid not null references gyms on delete cascade,
  start_date date not null,
  end_date date not null check (end_date >= start_date)
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users on delete cascade,
  gym_id uuid not null references gyms on delete cascade,
  attendance_date date not null,
  checked_in_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, gym_id, attendance_date)
);

create table check_in_codes (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references gyms on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index on check_in_codes (gym_id, code_hash);

create table workout_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  name text not null,
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (user_id, weekday)
);

create table workout_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_day_id uuid not null references workout_days on delete cascade,
  position integer not null,
  name text not null,
  sets text not null
);
