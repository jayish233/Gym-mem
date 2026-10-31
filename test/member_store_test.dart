import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/api_client.dart';
import 'package:gymapp/data/member_store.dart';

import 'fake_api.dart';
import 'test_app.dart';

void main() {
  test('load reads the seeded member, figures and plan from the API', () async {
    final (_, s, _) = await signedIn();
    expect(s.member.name, 'Priya Sharma');
    expect(s.gymName, 'Iron Works Fitness');
    expect(s.membershipActive, isTrue);
    expect(s.checkedInToday, isFalse);
    expect(s.currentStreak, 12);
    expect(s.longestStreak, 21);
    expect(s.today, DateTime(2026, 10, 31));
    expect(s.plan[0].completed, isTrue); // Monday
    expect(s.plan[5].completed, isFalse); // today, Saturday
  });

  test(
    'success only after the server records it; second scan is duplicate',
    () async {
      final (_, s, api) = await signedIn();
      expect((await s.checkIn('gym-EXPIRED')).result, CheckIn.expired);
      expect((await s.checkIn('wrong')).result, CheckIn.invalid);
      expect(s.checkedInToday, isFalse);

      final ok = await s.checkIn(FakeApi.validCode);
      expect(ok.result, CheckIn.checkedIn);
      expect(ok.currentStreak, 13);
      expect(s.currentStreak, 13);
      expect(s.checkedInToday, isTrue);
      expect((await s.checkIn(FakeApi.validCode)).result, CheckIn.duplicate);
      expect(api.attendance.where((d) => d == api.today), hasLength(1));
    },
  );

  test('a dropped connection is never a check-in', () async {
    final (_, s, api) = await signedIn();
    api.offline = true;
    await expectLater(
      s.checkIn(FakeApi.validCode),
      throwsA(isA<ApiException>()),
    );
    api.offline = false;
    expect(api.attendance.contains(api.today), isFalse);
    expect(s.checkedInToday, isFalse);
  });

  test(
    'toggling completion saves the plan and never touches attendance',
    () async {
      final (_, s, api) = await signedIn();
      final before = api.attendance.length;
      s.toggleCompleted(s.todayIndex);
      await pumpEventQueue();
      expect(api.plan[s.todayIndex]['completed'], isTrue);
      expect(api.calls, isNot(contains('POST /attendance/check-in')));
      expect(api.attendance.length, before);
      expect(s.checkedInToday, isFalse);
    },
  );

  test(
    'blank sets default to 3 × 10, blank names are ignored, saved',
    () async {
      final (_, s, api) = await signedIn();
      s
        ..addExercise(6, 'Stretch', ' ')
        ..addExercise(6, '  ', '5 × 5');
      await pumpEventQueue();
      expect(s.plan[6].exercises.single.sets, '3 × 10');
      expect(api.plan[6]['exercises'], [
        {'name': 'Stretch', 'sets': '3 × 10'},
      ]);
    },
  );

  test('a failed save shows an error, the next save clears it', () async {
    final (_, s, api) = await signedIn();
    api.offline = true;
    s.toggleCompleted(0);
    await pumpEventQueue();
    expect(s.planError, 'Not saved. Check your connection.');
    api.offline = false;
    s.toggleCompleted(0);
    await pumpEventQueue();
    expect(s.planError, isNull);
  });

  test('profile save goes through the API; email cannot change', () async {
    final (_, s, api) = await signedIn();
    await s.saveProfile(name: ' Priya S ', phone: '+91 1');
    expect(s.member.name, 'Priya S');
    expect(api.name, 'Priya S');
    expect(s.member.email, 'priya.sharma@example.com');
  });

  test('sign out revokes the session and keeps server data', () async {
    final (session, s, api) = await signedIn();
    await s.checkIn(FakeApi.validCode);
    session.signOut();
    await pumpEventQueue();
    expect(api.calls.last, 'POST /auth/logout');
    expect(api.token, isNull);
    expect(session.isSignedIn, isFalse);
    expect(s.plan, isEmpty);
    expect(api.attendance.contains(api.today), isTrue);
  });

  test('a rejected token signs the member out', () async {
    final (session, s, api) = await signedIn();
    api.revoked = true;
    await s.loadMonth(DateTime(2026, 9));
    expect(s.calendarFailed(DateTime(2026, 9)), isTrue);
    expect(session.isSignedIn, isFalse);
  });
}
