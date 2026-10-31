import '../attendance_math.dart';
import '../models/attendance_day.dart';
import '../models/member.dart';
import '../models/workout.dart';
import 'mock_clock.dart';

Member buildSeedMember() => const Member(
  id: 'm_001',
  name: 'Priya Sharma',
  email: 'priya.sharma@example.com',
  phone: '+91 98101 20034',
);

const seedGym = Gym(
  name: 'Iron Works Fitness',
  closedWeekdays: {DateTime.sunday},
);

final seedMembership = Membership(
  start: DateTime(2026, 1, 12),
  end: DateTime(2027, 3, 14),
);

/// Walks open days back from yesterday: 12 present, 1 missed, 21 present,
/// 1 missed, then "4 present, 1 missed" back to the membership start.
Set<DateTime> buildSeedAttendance(MockClock clock) {
  final yesterday = addDays(dateOnly(clock.now), -1);
  final m = seedMembership;
  final attended = <DateTime>{};
  var i = 0;
  for (
    var day = yesterday.isAfter(m.end) ? m.end : yesterday;
    !day.isBefore(m.start);
    day = addDays(day, -1)
  ) {
    if (!isOpenDay(day, seedGym, m)) continue;
    final present =
        i < 12 || (i > 12 && i < 34) || (i > 34 && (i - 35) % 5 < 4);
    if (present) attended.add(day);
    i++;
  }
  return attended;
}

/// Monday first. Completed only for days earlier this week than today.
List<WorkoutDay> buildSeedPlan(MockClock clock) {
  final today = clock.now.weekday;
  final days = [
    WorkoutDay('Chest', const [
      Exercise('Bench press', '4 × 8'),
      Exercise('Incline dumbbell press', '3 × 10'),
      Exercise('Cable fly', '3 × 12'),
    ]),
    WorkoutDay('Back', const [
      Exercise('Pull-up', '4 × 6'),
      Exercise('Barbell row', '4 × 8'),
    ]),
    WorkoutDay('Shoulders', const [
      Exercise('Overhead press', '4 × 8'),
      Exercise('Lateral raise', '3 × 15'),
    ]),
    WorkoutDay('Arms', const [
      Exercise('Barbell curl', '3 × 10'),
      Exercise('Triceps pushdown', '3 × 12'),
    ]),
    WorkoutDay('Legs', const [
      Exercise('Back squat', '4 × 8'),
      Exercise('Leg press', '3 × 12'),
      Exercise('Romanian deadlift', '3 × 10'),
    ]),
    WorkoutDay('Cardio', const [Exercise('Incline walk', '30 min')]),
    WorkoutDay('Rest', const []),
  ];
  for (var i = 0; i < 7; i++) {
    days[i] = WorkoutDay(
      days[i].name,
      [...days[i].exercises], // growable copy so the planner can edit it
      completed: i + 1 < today,
    );
  }
  return days;
}
