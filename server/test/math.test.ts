import assert from 'node:assert/strict';
import { test } from 'node:test';
import { currentStreak, dayState, isOpenDay, longestStreak, monthSummary } from '../src/attendance/math.ts';

const gym = { closedWeekdays: [7] };
const m = { startDate: '2026-01-12', endDate: '2027-03-14' };
// 2026-10-25 is a Sunday; 2026-10-31 a Saturday.

test('open days skip Sundays and dates outside the membership', () => {
  assert.equal(isOpenDay('2026-10-26', gym, m), true);
  assert.equal(isOpenDay('2026-10-25', gym, m), false);
  assert.equal(isOpenDay('2026-01-10', gym, m), false);
  assert.equal(isOpenDay('2027-03-15', gym, m), false);
});

test('a closed Sunday does not break the current streak', () => {
  const attended = new Set(['2026-10-23', '2026-10-24', '2026-10-26', '2026-10-27']);
  assert.equal(currentStreak(attended, '2026-10-28', gym, m), 4);
  attended.add('2026-10-28');
  assert.equal(currentStreak(attended, '2026-10-28', gym, m), 5);
});

test('streaks stop at the membership start and a missed day', () => {
  const attended = new Set(['2026-01-12', '2026-01-13', '2026-01-15']);
  assert.equal(currentStreak(attended, '2026-01-16', gym, m), 1);
  assert.equal(longestStreak(attended, '2026-01-16', gym, m), 2);
  assert.equal(currentStreak(new Set(['2026-01-12', '2026-01-13']), '2026-01-14', gym, m), 2);
});

test('an unattended today does not reset the longest run', () => {
  const attended = new Set(['2026-10-29', '2026-10-30']);
  assert.equal(longestStreak(attended, '2026-10-31', gym, m), 2);
});

test('month summary counts open days up to today', () => {
  const attended = new Set(['2026-10-01', '2026-10-02']);
  // October 2026 to the 31st: 31 days minus 4 Sundays.
  assert.deepEqual(monthSummary(2026, 10, attended, '2026-10-31', gym, m), { visits: 2, openDays: 27, pct: 7 });
  assert.deepEqual(monthSummary(2026, 10, attended, '2026-10-02', gym, m), { visits: 2, openDays: 2, pct: 100 });
  assert.deepEqual(monthSummary(2026, 10, attended, '2026-09-30', gym, m), { visits: 0, openDays: 0, pct: 0 });
});

test('future days are never missed', () => {
  const none = new Set<string>();
  assert.equal(dayState('2026-11-02', none, '2026-10-31', gym, m), 'upcoming');
  assert.equal(dayState('2026-10-31', none, '2026-10-31', gym, m), 'today');
  assert.equal(dayState('2026-10-30', none, '2026-10-31', gym, m), 'missed');
  assert.equal(dayState('2026-10-25', none, '2026-10-31', gym, m), 'closed');
  assert.equal(dayState('2026-01-01', none, '2026-10-31', gym, m), 'not_joined');
  assert.equal(dayState('2026-10-31', new Set(['2026-10-31']), '2026-10-31', gym, m), 'present');
});
