import 'package:flutter/foundation.dart';

import 'attendance_math.dart' as math;
import 'mock/mock_clock.dart';
import 'mock/seed.dart';
import 'models/attendance_day.dart';
import 'models/member.dart';
import 'models/workout.dart';

/// Everything the signed-in member can see. Memory only.
class MemberStore extends ChangeNotifier {
  MemberStore(this.clock) {
    _seed();
  }

  final MockClock clock;

  late Member member;
  final Gym gym = seedGym;
  final Membership membership = seedMembership;
  late Set<DateTime> _attendance;
  late List<WorkoutDay> plan;

  void _seed() {
    member = buildSeedMember();
    _attendance = buildSeedAttendance(clock);
    plan = buildSeedPlan(clock);
  }

  /// Back to fresh demo data (used on sign out).
  void reset() {
    _seed();
    notifyListeners();
  }

  DateTime get today => dateOnly(clock.now);

  Set<DateTime> get attendance => Set.unmodifiable(_attendance);

  bool get checkedInToday => _attendance.contains(today);

  bool get membershipActive => membership.isActiveOn(today);

  /// Rule 2: one check-in per local day. Returns false if already recorded.
  bool checkIn(DateTime at) {
    if (!_attendance.add(dateOnly(at))) return false;
    notifyListeners();
    return true;
  }

  int get currentStreak =>
      math.currentStreak(_attendance, today, gym, membership);

  int get longestStreak =>
      math.longestStreak(_attendance, today, gym, membership);

  math.MonthSummary monthSummary(int year, int month) =>
      math.monthSummary(year, month, _attendance, today, gym, membership);

  DayState dayState(DateTime day) =>
      math.dayState(day, _attendance, today, gym, membership);

  /// Index into [plan] for today (Monday = 0).
  int get todayIndex => clock.now.weekday - 1;

  void renameDay(int day, String name) {
    plan[day].name = name;
    notifyListeners();
  }

  void addExercise(int day, String name, String sets) {
    if (name.trim().isEmpty) return;
    plan[day].exercises.add(
      Exercise(name.trim(), sets.trim().isEmpty ? '3 × 10' : sets.trim()),
    );
    notifyListeners();
  }

  void removeExercise(int day, int index) {
    plan[day].exercises.removeAt(index);
    notifyListeners();
  }

  /// Rule 8: never touches attendance.
  void toggleCompleted(int day) {
    plan[day].completed = !plan[day].completed;
    notifyListeners();
  }

  void saveProfile({required String name, required String phone}) {
    member = member.copyWith(name: name.trim(), phone: phone.trim());
    notifyListeners();
  }
}
