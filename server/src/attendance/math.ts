// Port of lib/data/attendance_math.dart. Dates are gym-local 'YYYY-MM-DD'
// strings, so plain string comparison orders them correctly.

export type Gym = { closedWeekdays: number[] };
export type Membership = { startDate: string; endDate: string };
export type DayState = 'present' | 'today' | 'upcoming' | 'closed' | 'missed' | 'not_joined';

const utc = (d: string) => new Date(`${d}T00:00:00Z`);

export function addDays(d: string, n: number): string {
  const t = utc(d);
  t.setUTCDate(t.getUTCDate() + n);
  return t.toISOString().slice(0, 10);
}

/** 1 Monday … 7 Sunday, matching Dart's DateTime.weekday. */
export const weekday = (d: string) => utc(d).getUTCDay() || 7;

/** The calendar date at `at` in an IANA timezone. */
export const localDate = (timezone: string, at = new Date()) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(at);

export const monthName = (d: string) =>
  utc(d).toLocaleString('en-US', { month: 'long', timeZone: 'UTC' });

export const inMembership = (d: string, m: Membership) => d >= m.startDate && d <= m.endDate;

/** Rule 1. */
export const isOpenDay = (d: string, gym: Gym, m: Membership) =>
  !gym.closedWeekdays.includes(weekday(d)) && inMembership(d, m);

/** Rule 5: walk back from today if attended, otherwise from yesterday. */
export function currentStreak(attended: Set<string>, today: string, gym: Gym, m: Membership): number {
  let count = 0;
  for (let d = attended.has(today) ? today : addDays(today, -1); d >= m.startDate; d = addDays(d, -1)) {
    if (!isOpenDay(d, gym, m)) continue;
    if (!attended.has(d)) break;
    count++;
  }
  return count;
}

/** Rule 6: an unattended today does not reset the run. */
export function longestStreak(attended: Set<string>, today: string, gym: Gym, m: Membership): number {
  const last = today > m.endDate ? m.endDate : today;
  let best = 0;
  let run = 0;
  for (let d = m.startDate; d <= last; d = addDays(d, 1)) {
    if (!isOpenDay(d, gym, m)) continue;
    if (attended.has(d)) best = Math.max(best, ++run);
    else if (d !== today) run = 0;
  }
  return best;
}

/** Every date in a month. */
export function monthDays(year: number, month: number): string[] {
  const days: string[] = [];
  for (let d = `${year}-${String(month).padStart(2, '0')}-01`; utc(d).getUTCMonth() + 1 === month; d = addDays(d, 1)) {
    days.push(d);
  }
  return days;
}

/** Rule 7: open days count up to and including today. */
export function monthSummary(year: number, month: number, attended: Set<string>, today: string, gym: Gym, m: Membership) {
  let visits = 0;
  let openDays = 0;
  for (const d of monthDays(year, month)) {
    if (d > today) break;
    if (attended.has(d)) visits++;
    if (isOpenDay(d, gym, m)) openDays++;
  }
  return { visits, openDays, pct: openDays === 0 ? 0 : Math.round((visits / openDays) * 100) };
}

/** Rules 3 and 4. Present wins over today so a checked-in today shows as present. */
export function dayState(d: string, attended: Set<string>, today: string, gym: Gym, m: Membership): DayState {
  if (!inMembership(d, m)) return 'not_joined';
  if (attended.has(d)) return 'present';
  if (d === today) return 'today';
  if (d > today) return 'upcoming';
  if (gym.closedWeekdays.includes(weekday(d))) return 'closed';
  return 'missed';
}

// Same words as dayStateWords in lib/widgets/day_cell.dart.
const stateWords: Record<DayState, string> = {
  present: 'attended',
  missed: 'missed',
  closed: 'gym closed',
  today: 'today',
  upcoming: 'upcoming',
  not_joined: 'before your membership',
};

/** "October 14, attended". */
export const dayLabel = (d: string, state: DayState) => `${monthName(d)} ${Number(d.slice(8))}, ${stateWords[state]}`;
