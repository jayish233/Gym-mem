import 'models/attendance_day.dart';
import 'models/member.dart';

/// Rule 1: open if not a closed weekday and inside the membership.
bool isOpenDay(DateTime day, Gym gym, Membership m) =>
    !gym.closedWeekdays.contains(day.weekday) && m.isActiveOn(dateOnly(day));

/// Rule 5: walk back from today (if attended) or the last open day before it.
int currentStreak(
  Set<DateTime> attended,
  DateTime today,
  Gym gym,
  Membership m,
) {
  today = dateOnly(today);
  var day = attended.contains(today) ? today : addDays(today, -1);
  var count = 0;
  while (!day.isBefore(m.start)) {
    if (isOpenDay(day, gym, m)) {
      if (!attended.contains(day)) break;
      count++;
    }
    day = addDays(day, -1);
  }
  return count;
}

/// Rule 6: longest run of attended open days. Today unattended is not a miss.
int longestStreak(
  Set<DateTime> attended,
  DateTime today,
  Gym gym,
  Membership m,
) {
  today = dateOnly(today);
  final last = today.isAfter(m.end) ? m.end : today;
  var best = 0;
  var run = 0;
  for (var day = m.start; !day.isAfter(last); day = addDays(day, 1)) {
    if (!isOpenDay(day, gym, m)) continue;
    if (attended.contains(day)) {
      run++;
      if (run > best) best = run;
    } else if (day != today) {
      run = 0;
    }
  }
  return best;
}

class MonthSummary {
  const MonthSummary(this.visits, this.openDays);

  final int visits;
  final int openDays;

  int get pct => openDays == 0 ? 0 : (visits / openDays * 100).round();
}

/// Rule 7: open days count up to and including today in the current month.
MonthSummary monthSummary(
  int year,
  int month,
  Set<DateTime> attended,
  DateTime today,
  Gym gym,
  Membership m,
) {
  today = dateOnly(today);
  var visits = 0;
  var open = 0;
  for (
    var day = DateTime(year, month);
    day.month == month && !day.isAfter(today);
    day = addDays(day, 1)
  ) {
    if (attended.contains(day)) visits++;
    if (isOpenDay(day, gym, m)) open++;
  }
  return MonthSummary(visits, open);
}

/// Rules 3 and 4. Present wins over Today so a checked-in today fills teal.
DayState dayState(
  DateTime day,
  Set<DateTime> attended,
  DateTime today,
  Gym gym,
  Membership m,
) {
  day = dateOnly(day);
  today = dateOnly(today);
  if (!m.isActiveOn(day)) return DayState.notJoined;
  if (attended.contains(day)) return DayState.present;
  if (day == today) return DayState.today;
  if (day.isAfter(today)) return DayState.upcoming;
  if (gym.closedWeekdays.contains(day.weekday)) return DayState.closed;
  return DayState.missed;
}
