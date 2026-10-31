import 'package:gymapp/data/api_client.dart';
import 'package:gymapp/data/attendance_math.dart' as math;
import 'package:gymapp/data/mock/mock_clock.dart';
import 'package:gymapp/data/mock/seed.dart';
import 'package:gymapp/data/models/attendance_day.dart';
import 'package:intl/intl.dart';

/// In-memory stand-in for server/ with the same JSON contract.
/// Seed data and rules come from lib/data/mock and attendance_math.dart.
class FakeApi extends ApiClient {
  FakeApi(this.clock) : super('http://fake') {
    attendance = buildSeedAttendance(clock);
    plan = [
      for (final d in buildSeedPlan(clock))
        {
          'name': d.name,
          'completed': d.completed,
          'exercises': [
            for (final e in d.exercises) {'name': e.name, 'sets': e.sets},
          ],
        },
    ];
  }

  static const password = 'correct-horse';
  static const validCode = 'gym-code-1';

  final MockClock clock;
  late Set<DateTime> attendance;
  late List<Map<String, Object>> plan;
  bool termsAccepted = false;
  bool offline = false;

  /// The server has revoked or expired the session.
  bool revoked = false;
  String name = 'Priya Sharma';
  String phone = '+91 98101 20034';

  /// "METHOD /path" for every call, in order.
  final calls = <String>[];

  DateTime get today => dateOnly(clock.now);
  static String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static const _states = {
    DayState.present: 'present',
    DayState.today: 'today',
    DayState.upcoming: 'upcoming',
    DayState.closed: 'closed',
    DayState.missed: 'missed',
    DayState.notJoined: 'not_joined',
  };

  String _state(DateTime d) =>
      _states[math.dayState(d, attendance, today, seedGym, seedMembership)]!;

  int get _current =>
      math.currentStreak(attendance, today, seedGym, seedMembership);
  int get _longest =>
      math.longestStreak(attendance, today, seedGym, seedMembership);

  @override
  Future<dynamic> send(String method, String path, [Object? body]) async {
    final route = '$method ${path.split('?').first}';
    calls.add(route);
    if (offline) throw ApiException.offline;
    final b = (body ?? const {}) as Map;
    const public = {'POST /auth/login', 'POST /auth/logout'};
    const beforeTerms = {'POST /auth/accept-terms', 'GET /me'};
    if (!public.contains(route)) {
      if (token == null || revoked) {
        if (token != null) onUnauthorized?.call();
        throw const ApiException(401, 'unauthorized', 'Sign in to continue.');
      }
      if (!termsAccepted && !beforeTerms.contains(route)) {
        throw const ApiException(403, 'terms_required', 'Accept the terms.');
      }
    }

    switch ((method, path.split('?').first)) {
      case ('POST', '/auth/login'):
        if (b['password'] != password) {
          throw const ApiException(
            401,
            'invalid_credentials',
            'Email or password is incorrect.',
          );
        }
        return {
          'token': 'tok',
          'expiresAt': '',
          'termsAccepted': termsAccepted,
        };
      case ('POST', '/auth/logout'):
        return null;
      case ('POST', '/auth/accept-terms'):
        termsAccepted = true;
        return null;
      case ('GET', '/me'):
        return _me();
      case ('PATCH', '/me'):
        name = (b['name'] as String).trim();
        phone = b['phone'] as String;
        return _me();
      case ('GET', '/attendance/summary'):
        final monday = addDays(today, 1 - today.weekday);
        final m = math.monthSummary(
          today.year,
          today.month,
          attendance,
          today,
          seedGym,
          seedMembership,
        );
        return {
          'today': iso(today),
          'currentStreak': _current,
          'longestStreak': _longest,
          'checkedInToday': attendance.contains(today),
          'week': [
            for (var i = 0; i < 7; i++)
              {
                'date': iso(addDays(monday, i)),
                'state': _state(addDays(monday, i)),
                'weekdayLetter': 'MTWTFSS'[i],
              },
          ],
          'month': {
            'name': DateFormat('MMMM').format(today),
            'visits': m.visits,
            'openDays': m.openDays,
            'pct': m.pct,
          },
        };
      case ('GET', '/attendance/calendar'):
        final q = Uri.parse(path).queryParameters;
        final year = int.parse(q['year']!);
        final month = int.parse(q['month']!);
        final m = math.monthSummary(
          year,
          month,
          attendance,
          today,
          seedGym,
          seedMembership,
        );
        return {
          'year': year,
          'month': month,
          'visits': m.visits,
          'openDays': m.openDays,
          'pct': m.pct,
          'currentStreak': _current,
          'longestStreak': _longest,
          'days': [
            for (
              var d = DateTime(year, month);
              d.month == month;
              d = addDays(d, 1)
            )
              {'date': iso(d), 'state': _state(d), 'label': ''},
          ],
        };
      case ('POST', '/attendance/check-in'):
        final code = b['code'] as String;
        Map<String, Object?> reply(String result, [bool recorded = false]) => {
          'result': result,
          'attendanceDate': recorded ? iso(today) : null,
          'checkedInAt': recorded ? clock.now.toUtc().toIso8601String() : null,
          'currentStreak': _current,
        };
        if (attendance.contains(today)) return reply('duplicate', true);
        if (code.toLowerCase().contains('expired')) return reply('expired');
        if (code != validCode) return reply('invalid');
        attendance.add(today);
        return reply('checked_in', true);
      case ('GET', '/workouts'):
        return [
          for (var i = 0; i < 7; i++) {'weekday': i + 1, ...plan[i]},
        ];
      case ('PUT', final p) when p.startsWith('/workouts/'):
        final i = int.parse(p.split('/').last) - 1;
        plan[i] = {
          'name': b['name'] ?? plan[i]['name']!,
          'completed': b['completed'] ?? plan[i]['completed']!,
          'exercises': b['exercises'] ?? plan[i]['exercises']!,
        };
        return {'weekday': i + 1, ...plan[i]};
    }
    throw ApiException(404, 'not_found', 'No such route: $method $path');
  }

  Map<String, Object?> _me() => {
    'id': 'u1',
    'name': name,
    'email': 'priya.sharma@example.com',
    'phone': phone,
    'initials': 'PS',
    'gym': {'id': 'g1', 'name': seedGym.name},
    'membership': {
      'startDate': iso(seedMembership.start),
      'endDate': iso(seedMembership.end),
      'status': seedMembership.isActiveOn(today) ? 'active' : 'expired',
    },
    'termsAccepted': termsAccepted,
  };
}
