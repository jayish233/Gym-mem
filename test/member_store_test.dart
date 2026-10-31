import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/member_store.dart';
import 'package:gymapp/data/mock/mock_clock.dart';

void main() {
  // Saturday 31 Oct 2026, evening.
  final clock = MockClock(DateTime(2026, 10, 31, 18, 42));

  test('seed matches the prototype headline figures', () {
    final s = MemberStore(clock);
    expect(s.checkedInToday, isFalse);
    expect(s.currentStreak, 12);
    expect(s.longestStreak, 21);
    expect(s.plan[0].completed, isTrue); // Monday
    expect(s.plan[5].completed, isFalse); // today, Saturday
  });

  test('checkIn is idempotent per day and bumps the streak', () {
    final s = MemberStore(clock);
    expect(s.checkIn(clock.now), isTrue);
    expect(s.checkIn(clock.now.add(const Duration(minutes: 5))), isFalse);
    expect(s.currentStreak, 13);
    expect(s.attendance.where((d) => d == s.today), hasLength(1));
  });

  test('toggling completion does not touch attendance', () {
    final s = MemberStore(clock);
    final before = s.attendance.length;
    s.toggleCompleted(s.todayIndex);
    expect(s.plan[s.todayIndex].completed, isTrue);
    expect(s.attendance.length, before);
    expect(s.checkedInToday, isFalse);
  });

  test('reset restores seed data', () {
    final s = MemberStore(clock)
      ..checkIn(clock.now)
      ..saveProfile(name: 'Someone Else', phone: '1')
      ..addExercise(0, 'Dip', '');
    s.reset();
    expect(s.checkedInToday, isFalse);
    expect(s.member.name, 'Priya Sharma');
    expect(s.plan[0].exercises, hasLength(3));
  });

  test('blank sets default to 3 × 10 and blank names are ignored', () {
    final s = MemberStore(clock)
      ..addExercise(6, 'Stretch', ' ')
      ..addExercise(6, '  ', '5 × 5');
    expect(s.plan[6].exercises.single.sets, '3 × 10');
  });
}
