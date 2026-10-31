/// How a calendar day renders (CLAUDE.md section 4.7).
enum DayState { present, missed, closed, today, upcoming, notJoined }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar arithmetic that is safe across DST changes.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);
