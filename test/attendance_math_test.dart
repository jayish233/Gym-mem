import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/attendance_math.dart';
import 'package:gymapp/data/models/attendance_day.dart';
import 'package:gymapp/data/models/member.dart';

void main() {
  const gym = Gym(name: 'G', closedWeekdays: {DateTime.sunday});
  // Monday 12 Jan 2026.
  final m = Membership(
    start: DateTime(2026, 1, 12),
    end: DateTime(2027, 3, 14),
  );
  Set<DateTime> days(List<int> janDays) => {
    for (final d in janDays) DateTime(2026, 1, d),
  };

  test('open days skip Sundays and days outside the membership', () {
    expect(isOpenDay(DateTime(2026, 1, 12), gym, m), isTrue);
    expect(isOpenDay(DateTime(2026, 1, 18), gym, m), isFalse); // Sunday
    expect(isOpenDay(DateTime(2026, 1, 10), gym, m), isFalse); // before start
    expect(isOpenDay(DateTime(2027, 3, 15), gym, m), isFalse); // after end
  });

  test('a closed Sunday does not break the current streak', () {
    // Fri 16, Sat 17, (Sun 18 closed), Mon 19.
    final a = days([16, 17, 19]);
    expect(currentStreak(a, DateTime(2026, 1, 19, 9), gym, m), 3);
  });

  test('current streak counts from yesterday when today is not attended', () {
    final a = days([16, 17]);
    expect(currentStreak(a, DateTime(2026, 1, 19), gym, m), 2);
    expect(currentStreak(a, DateTime(2026, 1, 20), gym, m), 0); // Mon 19 missed
  });

  test('current streak stops at the membership start', () {
    final a = days([12, 13, 14]);
    expect(currentStreak(a, DateTime(2026, 1, 14), gym, m), 3);
  });

  test('longest streak spans closed days and survives a later miss', () {
    // 12..17 (6), skip 18 Sunday, 19, 20, miss 21, 22.
    final a = days([12, 13, 14, 15, 16, 17, 19, 20, 22]);
    expect(longestStreak(a, DateTime(2026, 1, 23), gym, m), 8);
  });

  test('monthly summary for a past month counts the whole month', () {
    // January from the 12th: 20 days minus Sundays 18 and 25.
    final s = monthSummary(
      2026,
      1,
      days([12, 13]),
      DateTime(2026, 3, 1),
      gym,
      m,
    );
    expect(s.visits, 2);
    expect(s.openDays, 18);
    expect(s.pct, 11);
  });

  test('monthly summary for the current month stops at today', () {
    final s = monthSummary(
      2026,
      1,
      days([12, 13]),
      DateTime(2026, 1, 14),
      gym,
      m,
    );
    expect(s.openDays, 3);
    expect(s.pct, 67);
  });

  test('future days are upcoming, today is today, never missed', () {
    final today = DateTime(2026, 1, 14, 18);
    expect(
      dayState(DateTime(2026, 1, 15), {}, today, gym, m),
      DayState.upcoming,
    );
    expect(dayState(DateTime(2026, 1, 14), {}, today, gym, m), DayState.today);
    expect(dayState(DateTime(2026, 1, 13), {}, today, gym, m), DayState.missed);
    expect(
      dayState(DateTime(2026, 1, 11), {}, today, gym, m),
      DayState.notJoined,
    );
  });
}
