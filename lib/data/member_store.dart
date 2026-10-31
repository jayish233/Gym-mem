import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'attendance_math.dart' show MonthSummary;
import 'mock/mock_clock.dart';
import 'models/attendance_day.dart';
import 'models/member.dart';
import 'models/workout.dart';

enum CheckIn { checkedIn, expired, duplicate, invalid }

class CheckInResult {
  const CheckInResult(this.result, this.checkedInAt, this.currentStreak);

  final CheckIn result;

  /// Local time of the visit; null when nothing is recorded today.
  final DateTime? checkedInAt;
  final int currentStreak;
}

/// The signed-in member's data, read from and written to the API.
/// Figures (streaks, states, month summaries) are computed by the server.
class MemberStore extends ChangeNotifier {
  MemberStore(this.api, this.clock);

  final ApiClient api;

  /// Device time. Only the greeting uses it; "today" comes from the gym.
  final MockClock clock;

  late Member member;
  late String gymName;
  late Membership membership;
  bool membershipActive = false;

  /// Gym-local date from the server.
  late DateTime today;
  int currentStreak = 0;
  int longestStreak = 0;
  bool checkedInToday = false;
  List<WorkoutDay> plan = [];

  /// Set when a plan change could not be saved. Cleared by the next save.
  String? planError;

  final _states = <DateTime, DayState>{};
  final _months = <DateTime, MonthSummary>{};
  final _calendars = <DateTime>{};
  final _calendarFailed = <DateTime>{};
  final _calendarLoading = <DateTime>{};
  final _renames = <int, Timer>{};
  Future<void> _saving = Future.value();

  /// Loads everything Home needs. Throws [ApiException].
  Future<void> load() async {
    final [me, summary, workouts] = await Future.wait([
      api.get('/me'),
      api.get('/attendance/summary'),
      api.get('/workouts'),
    ]);
    _applyMe(me as Map);
    _applySummary(summary as Map);
    plan = [
      for (final d in workouts as List)
        WorkoutDay(d['name'] as String, [
          for (final e in d['exercises'] as List)
            Exercise(e['name'] as String, e['sets'] as String),
        ], completed: d['completed'] as bool),
    ];
    notifyListeners();
  }

  /// Drops the member's data on sign out.
  void clear() {
    for (final t in _renames.values) {
      t.cancel();
    }
    _renames.clear();
    _states.clear();
    _months.clear();
    _calendars.clear();
    _calendarFailed.clear();
    plan = [];
    planError = null;
    checkedInToday = false;
    currentStreak = longestStreak = 0;
  }

  static DateTime _date(Object? iso) => DateTime.parse(iso as String);

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  void _applyMe(Map me) {
    member = Member(
      id: me['id'] as String,
      name: me['name'] as String,
      email: me['email'] as String,
      phone: (me['phone'] as String?) ?? '',
    );
    gymName = me['gym']['name'] as String;
    final m = me['membership'] as Map;
    membership = Membership(
      start: _date(m['startDate']),
      end: _date(m['endDate']),
    );
    membershipActive = m['status'] == 'active';
  }

  void _applySummary(Map s) {
    today = _date(s['today']);
    currentStreak = s['currentStreak'] as int;
    longestStreak = s['longestStreak'] as int;
    checkedInToday = s['checkedInToday'] as bool;
    for (final d in s['week'] as List) {
      _states[_date(d['date'])] = _parseState(d['state']);
    }
    final month = s['month'] as Map;
    _months[_monthOf(today)] = MonthSummary(
      month['visits'] as int,
      month['openDays'] as int,
    );
  }

  static DayState _parseState(Object? s) => switch (s) {
    'present' => DayState.present,
    'today' => DayState.today,
    'upcoming' => DayState.upcoming,
    'closed' => DayState.closed,
    'missed' => DayState.missed,
    _ => DayState.notJoined,
  };

  /// Index into [plan] for today (Monday = 0).
  int get todayIndex => today.weekday - 1;

  MonthSummary monthSummary(int year, int month) =>
      _months[DateTime(year, month)] ?? const MonthSummary(0, 0);

  DayState dayState(DateTime day) =>
      _states[dateOnly(day)] ??
      (day.isAfter(today) ? DayState.upcoming : DayState.notJoined);

  bool hasCalendar(DateTime month) => _calendars.contains(_monthOf(month));

  bool calendarFailed(DateTime month) =>
      _calendarFailed.contains(_monthOf(month));

  /// Fetches one month's day states for History. Safe to call repeatedly.
  Future<void> loadMonth(DateTime month) async {
    final key = _monthOf(month);
    if (_calendars.contains(key) || !_calendarLoading.add(key)) return;
    _calendarFailed.remove(key);
    try {
      final c = await api.get(
        '/attendance/calendar?year=${key.year}&month=${key.month}',
      );
      for (final d in c['days'] as List) {
        _states[_date(d['date'])] = _parseState(d['state']);
      }
      _months[key] = MonthSummary(c['visits'] as int, c['openDays'] as int);
      currentStreak = c['currentStreak'] as int;
      longestStreak = c['longestStreak'] as int;
      _calendars.add(key);
    } on ApiException {
      _calendarFailed.add(key);
    } finally {
      _calendarLoading.remove(key);
    }
    notifyListeners();
  }

  /// Sends a scanned code. Success is reported only when the server
  /// recorded the visit. Throws [ApiException] when the server is not reached.
  Future<CheckInResult> checkIn(String code) async {
    final r = await api.post('/attendance/check-in', {'code': code}) as Map;
    final result = switch (r['result']) {
      'checked_in' => CheckIn.checkedIn,
      'duplicate' => CheckIn.duplicate,
      'expired' => CheckIn.expired,
      _ => CheckIn.invalid,
    };
    if (result == CheckIn.checkedIn || result == CheckIn.duplicate) {
      _calendars.clear(); // History refetches with today filled in
      try {
        _applySummary(await api.get('/attendance/summary') as Map);
      } on ApiException {
        checkedInToday = true; // the visit is recorded either way
      }
      notifyListeners();
    }
    final at = r['checkedInAt'] as String?;
    return CheckInResult(
      result,
      at == null ? null : DateTime.parse(at).toLocal(),
      r['currentStreak'] as int,
    );
  }

  /// Throws [ApiException].
  Future<void> saveProfile({
    required String name,
    required String phone,
  }) async {
    final me = await api.patch('/me', {'name': name.trim(), 'phone': phone});
    _applyMe(me as Map);
    notifyListeners();
  }

  // Plan edits update the screen at once and save in the background,
  // one request at a time so the server sees them in order.

  void renameDay(int day, String name) {
    plan[day].name = name;
    notifyListeners();
    _renames[day]?.cancel();
    _renames[day] = Timer(const Duration(milliseconds: 600), () {
      _renames.remove(day);
      _saveDay(day);
    });
  }

  void addExercise(int day, String name, String sets) {
    if (name.trim().isEmpty) return;
    plan[day].exercises.add(
      Exercise(name.trim(), sets.trim().isEmpty ? '3 × 10' : sets.trim()),
    );
    notifyListeners();
    _saveDay(day);
  }

  void removeExercise(int day, int index) {
    plan[day].exercises.removeAt(index);
    notifyListeners();
    _saveDay(day);
  }

  /// Rule 9: never touches attendance.
  void toggleCompleted(int day) {
    plan[day].completed = !plan[day].completed;
    notifyListeners();
    _saveDay(day);
  }

  void _saveDay(int day) {
    _saving = _saving.then((_) async {
      final d = plan.elementAtOrNull(day);
      if (d == null) return; // signed out meanwhile
      try {
        await api.put('/workouts/${day + 1}', {
          // A blank name is still being typed; keep the stored one.
          if (d.name.trim().isNotEmpty) 'name': d.name.trim(),
          'completed': d.completed,
          'exercises': [
            for (final e in d.exercises) {'name': e.name, 'sets': e.sets},
          ],
        });
        if (planError != null) {
          planError = null;
          notifyListeners();
        }
      } on ApiException catch (e) {
        planError = e.status == 0
            ? 'Not saved. Check your connection.'
            : 'Not saved. ${e.message}';
        notifyListeners();
      }
    });
  }
}
