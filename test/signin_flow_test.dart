import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';
import 'test_app.dart';

Future<void> fillIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const ValueKey('email')), email);
  await tester.enterText(find.byKey(const ValueKey('password')), password);
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid email and short password show field errors', (
    tester,
  ) async {
    final (_, _, api) = await pumpApp(tester);
    await fillIn(tester, 'nope', 'short');
    expect(find.text('Enter the email your gym has on file.'), findsOneWidget);
    expect(
      find.text('Enter your password. It has at least 8 characters.'),
      findsOneWidget,
    );
    expect(api.calls, isEmpty);
  });

  testWidgets('wrong password shows the generic server message', (
    tester,
  ) async {
    await pumpApp(tester);
    await fillIn(tester, 'priya.sharma@example.com', 'wrong-password');
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text('Before you start'), findsNothing);
  });

  testWidgets('first sign in accepts the terms, then lands on Home', (
    tester,
  ) async {
    final (_, _, api) = await pumpApp(tester);
    await fillIn(tester, ' priya.sharma@example.com ', FakeApi.password);
    expect(find.text('Before you start'), findsOneWidget);
    expect(api.termsAccepted, isFalse);

    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();
    expect(api.termsAccepted, isTrue);
    expect(find.text('Good evening, Priya'), findsOneWidget);
    expect(find.text('Scan to check in'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('returning member skips the terms step', (tester) async {
    final (_, _, api) = await pumpApp(tester);
    api.termsAccepted = true;
    await fillIn(tester, 'priya.sharma@example.com', FakeApi.password);
    expect(find.text('Good evening, Priya'), findsOneWidget);
  });

  testWidgets('offline sign in says so and stays put', (tester) async {
    final (_, _, api) = await pumpApp(tester);
    api.offline = true;
    await fillIn(tester, 'priya.sharma@example.com', FakeApi.password);
    expect(
      find.text(
        'Could not reach Presence. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign out returns to Sign in', (tester) async {
    final (session, _, api) = await pumpApp(tester, signedIn: true);
    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Check in and keep your streak.'), findsOneWidget);
    expect(session.isSignedIn, isFalse);
    expect(api.calls.last, 'POST /auth/logout');
  });
}
